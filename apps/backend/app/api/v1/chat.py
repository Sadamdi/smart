import json
import uuid
from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import pengguna_saat_ini
from app.core.config import Settings, get_settings
from app.core.errors import UpstreamUnavailable
from app.db import get_session
from app.models import Beasiswa, Pengguna, Percakapan
from app.schemas.common import Amplop, Kosong
from app.services import chat as layanan
from app.services import llm
from app.services import memori as layanan_memori

router = APIRouter(prefix="/chat", tags=["chatbot"])

SesiDep = Annotated[Session, Depends(get_session)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]
SettingsDep = Annotated[Settings, Depends(get_settings)]


class ChatIn(BaseModel):
    pesan: str = Field(min_length=1, max_length=layanan.PESAN_MAKS)
    # Dokumen yang sudah diunggah lewat /me/dokumen dan dilampirkan pada pertanyaan ini.
    dokumen_ids: list[uuid.UUID] = Field(default=[], max_length=layanan.DOKUMEN_MAKS)
    # Sesi (utas) tujuan; kosong berarti sesi terbaru, atau sesi baru bila belum ada (klien lama).
    sesi_id: uuid.UUID | None = None


class RujukanOut(BaseModel):
    id: uuid.UUID
    nama: str
    tautan_resmi: str


class ChatOut(BaseModel):
    id: uuid.UUID
    sesi_id: uuid.UUID | None = None
    pesan: str
    jawaban: str | None
    waktu: datetime
    rujukan: list[RujukanOut]


class StatusOut(BaseModel):
    tersedia: bool


def _out(sesi: Session, c) -> ChatOut:
    ids = c.rujukan_beasiswa_id or []
    rujukan = (
        [
            RujukanOut(id=b.id, nama=b.nama, tautan_resmi=b.tautan_resmi)
            for b in sesi.scalars(select(Beasiswa).where(Beasiswa.id.in_(ids)))
        ]
        if ids
        else []
    )
    return ChatOut(id=c.id, sesi_id=c.sesi_id, pesan=c.pesan, jawaban=c.jawaban, waktu=c.waktu, rujukan=rujukan)


@router.get("/status", summary="Apakah layanan AI tersedia", response_model=Amplop[StatusOut])
def status(settings: SettingsDep, _: SaatIni) -> Amplop[StatusOut]:
    return Amplop(data=StatusOut(tersedia=llm.tersedia(settings)))


@router.post("", summary="Kirim pesan ke chatbot", response_model=Amplop[ChatOut])
def kirim(data: ChatIn, sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> Amplop[ChatOut]:
    tujuan = layanan.ambil_sesi(sesi, p, data.sesi_id)
    c = layanan.kirim(sesi, p, data.pesan, settings, date.today(), data.dokumen_ids, tujuan.id)
    sesi.commit()
    layanan.beri_judul(sesi, tujuan, c.pesan, c.jawaban, settings)
    layanan_memori.catat_dari_percakapan(sesi, p, data.pesan, settings)
    sesi.commit()
    return Amplop(data=_out(sesi, c))


def _sse(peristiwa: str, data: dict) -> str:
    return f"event: {peristiwa}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


@router.post("/stream", summary="Kirim pesan dan terima jawaban per potongan (SSE)")
def kirim_stream(data: ChatIn, sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> StreamingResponse:
    """Peristiwa: `token` ({t}), `selesai` (ChatOut), atau `galat` ({pesan}). Klien yang memutus koneksi membatalkan
    jawaban; jawaban yang dibatalkan tidak disimpan ke riwayat."""
    tujuan = layanan.ambil_sesi(sesi, p, data.sesi_id)
    sesi.commit()
    pesan, prompt, rujukan, sumber = layanan.siapkan(
        sesi, p, data.pesan, settings, date.today(), data.dokumen_ids, tujuan.id
    )

    def alir():
        potongan: list[str] = []
        try:
            for t in llm.tanya_stream(settings, layanan.SISTEM, prompt):
                potongan.append(t)
                yield _sse("token", {"t": t})
        except UpstreamUnavailable as e:
            yield _sse("galat", {"pesan": str(e)})
            return
        jawaban = "".join(potongan).strip()
        if not jawaban:
            yield _sse("galat", {"pesan": "Layanan AI tidak memberi jawaban, coba lagi"})
            return
        c = layanan.simpan(sesi, p, pesan, jawaban, rujukan, tujuan.id)
        sesi.commit()
        akhir = json.loads(_out(sesi, c).model_dump_json())
        akhir["sumber_data"] = sumber
        yield _sse("selesai", akhir)
        if layanan.beri_judul(sesi, tujuan, pesan, jawaban, settings):
            sesi.commit()
            yield _sse("judul", {"sesi_id": str(tujuan.id), "judul": tujuan.judul})
        if layanan_memori.catat_dari_percakapan(sesi, p, pesan, settings):
            sesi.commit()

    return StreamingResponse(
        alir(), media_type="text/event-stream", headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"}
    )


@router.get("/riwayat", summary="Riwayat percakapan", response_model=Amplop[list[ChatOut]])
def riwayat(sesi: SesiDep, p: SaatIni, sesi_id: uuid.UUID | None = None) -> Amplop[list[ChatOut]]:
    return Amplop(data=[_out(sesi, c) for c in layanan.riwayat(sesi, p, sesi_id=sesi_id)])


class StatistikChatOut(BaseModel):
    jumlah: int
    tujuh_hari: int
    pertama: datetime | None
    terakhir: datetime | None
    rata_panjang_jawaban: int
    jumlah_sesi: int = 0
    token_masuk: int = 0
    token_keluar: int = 0
    dijawab_server: int = 0
    dijawab_ponsel: int = 0
    per_hari: list[dict] = []
    topik: list[dict] = []
    beasiswa_teratas: list[dict]


class ButirRiwayat(BaseModel):
    pesan: str = Field(max_length=layanan.PESAN_MAKS)
    jawaban: str | None = None
    waktu: str | None = None
    sesi: str | None = None  # judul sesi asal; kosong pada cadangan lama


class ImporIn(BaseModel):
    butir: list[ButirRiwayat] = Field(max_length=500)


class SesiOut(BaseModel):
    id: uuid.UUID
    judul: str
    dibuat_pada: datetime
    diubah_pada: datetime
    jumlah: int = 0


class SesiBaruIn(BaseModel):
    judul: str | None = Field(default=None, max_length=layanan.JUDUL_MAKS)
    klien_id: str | None = Field(default=None, max_length=80)


class SesiUbahIn(BaseModel):
    judul: str = Field(min_length=1, max_length=layanan.JUDUL_MAKS)


def _sesi_out(sesi: Session, s, jumlah: int | None = None) -> SesiOut:
    n = (
        jumlah
        if jumlah is not None
        else sesi.scalar(select(func.count()).select_from(Percakapan).where(Percakapan.sesi_id == s.id)) or 0
    )
    return SesiOut(id=s.id, judul=s.judul, dibuat_pada=s.dibuat_pada, diubah_pada=s.diubah_pada, jumlah=n)


@router.get("/sesi", summary="Daftar sesi chat (terbaru dahulu)", response_model=Amplop[list[SesiOut]])
def daftar_sesi(sesi: SesiDep, p: SaatIni) -> Amplop[list[SesiOut]]:
    jumlah = dict(
        sesi.execute(
            select(Percakapan.sesi_id, func.count()).where(Percakapan.pengguna_id == p.id).group_by(Percakapan.sesi_id)
        ).all()
    )
    return Amplop(data=[_sesi_out(sesi, s, jumlah.get(s.id, 0)) for s in layanan.daftar_sesi(sesi, p)])


@router.post("/sesi", summary="Mulai sesi chat baru", response_model=Amplop[SesiOut], status_code=201)
def buat_sesi(data: SesiBaruIn, sesi: SesiDep, p: SaatIni) -> Amplop[SesiOut]:
    s = layanan.buat_sesi(sesi, p, data.judul, data.klien_id)
    sesi.commit()
    return Amplop(data=_sesi_out(sesi, s))


@router.patch("/sesi/{sesi_id}", summary="Ubah judul sesi", response_model=Amplop[SesiOut])
def ubah_sesi(sesi_id: uuid.UUID, data: SesiUbahIn, sesi: SesiDep, p: SaatIni) -> Amplop[SesiOut]:
    s = layanan.ubah_judul(sesi, p, sesi_id, data.judul)
    sesi.commit()
    return Amplop(data=_sesi_out(sesi, s))


@router.delete("/sesi/{sesi_id}", summary="Hapus sesi beserta isinya", response_model=Amplop[Kosong])
def hapus_sesi(sesi_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.hapus_sesi(sesi, p, sesi_id)
    sesi.commit()
    return Amplop(data=Kosong())


@router.get("/saran", summary="Saran pertanyaan lanjutan dari model", response_model=Amplop[list[str]])
def saran(sesi: SesiDep, p: SaatIni, settings: SettingsDep, sesi_id: uuid.UUID | None = None) -> Amplop[list[str]]:
    return Amplop(data=layanan.saran(sesi, p, sesi_id, settings))


@router.get("/statistik", summary="Statistik isi dan pemakaian chatbot", response_model=Amplop[StatistikChatOut])
def statistik(sesi: SesiDep, p: SaatIni) -> Amplop[StatistikChatOut]:
    d = layanan.statistik(sesi, p)
    return Amplop(data=StatistikChatOut(**{k: d[k] for k in StatistikChatOut.model_fields}))


@router.get("/ekspor", summary="Cadangan riwayat percakapan (JSON)", response_model=Amplop[list[ButirRiwayat]])
def ekspor(sesi: SesiDep, p: SaatIni) -> Amplop[list[ButirRiwayat]]:
    return Amplop(data=[ButirRiwayat(**b) for b in layanan.ekspor(sesi, p)])


class CatatLokalIn(BaseModel):
    pesan: str = Field(min_length=1, max_length=layanan.PESAN_MAKS)
    jawaban: str | None = None
    waktu: str | None = None
    sesi_id: uuid.UUID | None = None


@router.post(
    "/catat-lokal",
    summary="Simpan percakapan yang dijawab model di ponsel dan pelajari memorinya",
    response_model=Amplop[dict],
)
def catat_lokal(data: CatatLokalIn, sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> Amplop[dict]:
    """Percakapan yang dijawab model di ponsel disalin ke riwayat server (aman diulang: butir yang sama dilewati) dan
    pesan pengguna dipelajari untuk memori seperti pada jawaban server."""
    tujuan = layanan.ambil_sesi(sesi, p, data.sesi_id)
    n = layanan.impor(sesi, p, [data.model_dump(exclude={"sesi_id"})], tujuan.id)
    sesi.commit()
    baru = 0
    if n:
        layanan.beri_judul(sesi, tujuan, data.pesan, data.jawaban, settings)
        baru = layanan_memori.catat_dari_percakapan(sesi, p, data.pesan, settings)
        sesi.commit()
    return Amplop(data={"disimpan": n, "memori_baru": baru, "sesi_id": str(tujuan.id), "judul": tujuan.judul})


@router.post("/impor", summary="Pulihkan riwayat dari cadangan", response_model=Amplop[dict])
def impor(data: ImporIn, sesi: SesiDep, p: SaatIni) -> Amplop[dict]:
    n = layanan.impor(sesi, p, [b.model_dump() for b in data.butir])
    sesi.commit()
    return Amplop(data={"dipulihkan": n})


@router.delete("/riwayat/{percakapan_id}", summary="Hapus satu percakapan", response_model=Amplop[Kosong])
def hapus_satu(percakapan_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.hapus_satu(sesi, p, percakapan_id)
    sesi.commit()
    return Amplop(data=Kosong())


@router.delete("/riwayat", summary="Hapus riwayat percakapan", response_model=Amplop[Kosong])
def hapus(sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.hapus_riwayat(sesi, p)
    sesi.commit()
    return Amplop(data=Kosong())
