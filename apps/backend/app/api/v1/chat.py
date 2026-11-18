import json
import uuid
from datetime import date, datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.api.deps import pengguna_saat_ini
from app.core.config import Settings, get_settings
from app.core.errors import UpstreamUnavailable
from app.db import get_session
from app.models import Beasiswa, Pengguna
from app.schemas.common import Amplop, Kosong
from app.services import chat as layanan
from app.services import llm

router = APIRouter(prefix="/chat", tags=["chatbot"])

SesiDep = Annotated[Session, Depends(get_session)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]
SettingsDep = Annotated[Settings, Depends(get_settings)]


class ChatIn(BaseModel):
    pesan: str = Field(min_length=1, max_length=layanan.PESAN_MAKS)
    # Dokumen yang sudah diunggah lewat /me/dokumen dan dilampirkan pada pertanyaan ini.
    dokumen_ids: list[uuid.UUID] = Field(default=[], max_length=layanan.DOKUMEN_MAKS)


class RujukanOut(BaseModel):
    id: uuid.UUID
    nama: str
    tautan_resmi: str


class ChatOut(BaseModel):
    id: uuid.UUID
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
    return ChatOut(id=c.id, pesan=c.pesan, jawaban=c.jawaban, waktu=c.waktu, rujukan=rujukan)


@router.get("/status", summary="Apakah layanan AI tersedia", response_model=Amplop[StatusOut])
def status(settings: SettingsDep, _: SaatIni) -> Amplop[StatusOut]:
    return Amplop(data=StatusOut(tersedia=llm.tersedia(settings)))


@router.post("", summary="Kirim pesan ke chatbot", response_model=Amplop[ChatOut])
def kirim(data: ChatIn, sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> Amplop[ChatOut]:
    c = layanan.kirim(sesi, p, data.pesan, settings, date.today(), data.dokumen_ids)
    sesi.commit()
    return Amplop(data=_out(sesi, c))


def _sse(peristiwa: str, data: dict) -> str:
    return f"event: {peristiwa}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


@router.post("/stream", summary="Kirim pesan dan terima jawaban per potongan (SSE)")
def kirim_stream(data: ChatIn, sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> StreamingResponse:
    """Peristiwa: `token` ({t}), `selesai` (ChatOut), atau `galat` ({pesan}). Klien yang memutus koneksi membatalkan
    jawaban; jawaban yang dibatalkan tidak disimpan ke riwayat."""
    pesan, prompt, rujukan, sumber = layanan.siapkan(sesi, p, data.pesan, settings, date.today(), data.dokumen_ids)

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
        c = layanan.simpan(sesi, p, pesan, jawaban, rujukan)
        sesi.commit()
        akhir = json.loads(_out(sesi, c).model_dump_json())
        akhir["sumber_data"] = sumber
        yield _sse("selesai", akhir)

    return StreamingResponse(
        alir(), media_type="text/event-stream", headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"}
    )


@router.get("/riwayat", summary="Riwayat percakapan", response_model=Amplop[list[ChatOut]])
def riwayat(sesi: SesiDep, p: SaatIni) -> Amplop[list[ChatOut]]:
    return Amplop(data=[_out(sesi, c) for c in layanan.riwayat(sesi, p)])


class StatistikChatOut(BaseModel):
    jumlah: int
    tujuh_hari: int
    pertama: datetime | None
    terakhir: datetime | None
    rata_panjang_jawaban: int
    beasiswa_teratas: list[dict]


class ButirRiwayat(BaseModel):
    pesan: str = Field(max_length=layanan.PESAN_MAKS)
    jawaban: str | None = None
    waktu: str | None = None


class ImporIn(BaseModel):
    butir: list[ButirRiwayat] = Field(max_length=500)


@router.get("/statistik", summary="Statistik isi dan pemakaian chatbot", response_model=Amplop[StatistikChatOut])
def statistik(sesi: SesiDep, p: SaatIni) -> Amplop[StatistikChatOut]:
    d = layanan.statistik(sesi, p)
    return Amplop(data=StatistikChatOut(**{k: d[k] for k in StatistikChatOut.model_fields}))


@router.get("/ekspor", summary="Cadangan riwayat percakapan (JSON)", response_model=Amplop[list[ButirRiwayat]])
def ekspor(sesi: SesiDep, p: SaatIni) -> Amplop[list[ButirRiwayat]]:
    return Amplop(data=[ButirRiwayat(**b) for b in layanan.ekspor(sesi, p)])


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
