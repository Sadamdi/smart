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
    c = layanan.kirim(sesi, p, data.pesan, settings, date.today())
    sesi.commit()
    return Amplop(data=_out(sesi, c))


def _sse(peristiwa: str, data: dict) -> str:
    return f"event: {peristiwa}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


@router.post("/stream", summary="Kirim pesan dan terima jawaban per potongan (SSE)")
def kirim_stream(data: ChatIn, sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> StreamingResponse:
    """Peristiwa: `token` ({t}), `selesai` (ChatOut), atau `galat` ({pesan}). Klien yang memutus koneksi membatalkan
    jawaban; jawaban yang dibatalkan tidak disimpan ke riwayat."""
    pesan, prompt, rujukan = layanan.siapkan(sesi, p, data.pesan, settings, date.today())

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
        yield _sse("selesai", json.loads(_out(sesi, c).model_dump_json()))

    return StreamingResponse(
        alir(), media_type="text/event-stream", headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"}
    )


@router.get("/riwayat", summary="Riwayat percakapan", response_model=Amplop[list[ChatOut]])
def riwayat(sesi: SesiDep, p: SaatIni) -> Amplop[list[ChatOut]]:
    return Amplop(data=[_out(sesi, c) for c in layanan.riwayat(sesi, p)])


@router.delete("/riwayat", summary="Hapus riwayat percakapan", response_model=Amplop[Kosong])
def hapus(sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.hapus_riwayat(sesi, p)
    sesi.commit()
    return Amplop(data=Kosong())
