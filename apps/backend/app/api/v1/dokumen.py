import mimetypes
import uuid
from datetime import datetime
from pathlib import Path
from typing import Annotated, Literal
from urllib.parse import quote

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import Response
from pydantic import BaseModel, ConfigDict, model_validator
from sqlalchemy.orm import Session

from app.api.deps import pengguna_saat_ini
from app.core.config import Settings, get_settings
from app.core.errors import NotFound, ValidationFailed
from app.db import get_session
from app.models import Pengguna
from app.schemas.common import Amplop, Kosong
from app.services import dokumen as layanan
from app.services import pembersihan

router = APIRouter(prefix="/me/dokumen", tags=["dokumen"])

SesiDep = Annotated[Session, Depends(get_session)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]
SettingsDep = Annotated[Settings, Depends(get_settings)]


class DokumenOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    jenis: str
    nama_berkas: str
    status_baca: str
    hasil_baca: dict | None = None
    tanggal_unggah: datetime
    ada_berkas: bool = False

    @model_validator(mode="before")
    @classmethod
    def _tandai(cls, d):
        if hasattr(d, "lokasi_penyimpanan"):
            return {
                "id": d.id,
                "jenis": d.jenis,
                "nama_berkas": d.nama_berkas,
                "status_baca": d.status_baca,
                "hasil_baca": d.hasil_baca,
                "tanggal_unggah": d.tanggal_unggah,
                "ada_berkas": bool(d.lokasi_penyimpanan) and Path(d.lokasi_penyimpanan).exists(),
            }
        return d


class HasilBacaIn(BaseModel):
    hasil_baca: dict


class TerapkanOut(BaseModel):
    kolom_terisi: list[str]


@router.post(
    "", status_code=201, summary="Unggah dokumen (maksimal 10 MB, disimpan di server)", response_model=Amplop[DokumenOut]
)
async def unggah(
    sesi: SesiDep,
    p: SaatIni,
    settings: SettingsDep,
    jenis: Annotated[Literal["cv", "sertifikat", "pengalaman_organisasi"], Form()],
    berkas: Annotated[UploadFile, File()],
    asal: Annotated[Literal["profil", "chat"], Form()] = "profil",
) -> Amplop[DokumenOut]:
    isi = await berkas.read(settings.upload_maks_byte + 1)
    if not berkas.filename:
        raise ValidationFailed("Nama berkas kosong")
    d = layanan.simpan(sesi, p, jenis, berkas.filename, isi, settings, asal)
    sesi.commit()
    return Amplop(data=DokumenOut.model_validate(d))


class PenyimpananOut(BaseModel):
    terpakai_byte: int
    maks_byte: int
    persen: int
    dokumen_profil: int
    dokumen_chat: int


@router.get("/penyimpanan", summary="Pemakaian ruang dokumen", response_model=Amplop[PenyimpananOut])
def penyimpanan(sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> Amplop[PenyimpananOut]:
    return Amplop(data=PenyimpananOut(**pembersihan.ringkasan_penyimpanan(sesi, settings, p)))


@router.post(
    "/penyimpanan/bersihkan", summary="Bersihkan lampiran chat dan memori yang tak terpakai", response_model=Amplop[dict]
)
def bersihkan(sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> Amplop[dict]:
    hasil = pembersihan.bersihkan_pengguna(sesi, settings, p, paksa_penuh=True)
    sesi.commit()
    return Amplop(data=hasil)


@router.get("", summary="Daftar dokumen dan status baca", response_model=Amplop[list[DokumenOut]])
def daftar(sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> Amplop[list[DokumenOut]]:
    if pembersihan.bersihkan_dokumen(sesi, settings, p):  # pembersihan otomatis: lampiran chat yang lama tak dipakai
        sesi.commit()
    return Amplop(data=[DokumenOut.model_validate(d) for d in layanan.daftar(sesi, p)])


@router.get("/{dokumen_id}", summary="Detail dan hasil baca", response_model=Amplop[DokumenOut])
def detail(dokumen_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[DokumenOut]:
    return Amplop(data=DokumenOut.model_validate(layanan.ambil(sesi, p, dokumen_id)))


@router.get("/{dokumen_id}/berkas", summary="Unduh atau lihat berkas asli", response_class=Response)
def berkas_asli(dokumen_id: uuid.UUID, sesi: SesiDep, p: SaatIni, settings: SettingsDep) -> Response:
    d = layanan.ambil(sesi, p, dokumen_id)
    if not d.lokasi_penyimpanan or not Path(d.lokasi_penyimpanan).exists():
        raise NotFound("Berkas asli tidak tersimpan di server")
    isi = layanan.isi_berkas(settings, d)
    if isi is None:
        raise NotFound("Berkas asli tidak tersimpan di server")
    jenis, _ = mimetypes.guess_type(d.nama_berkas)
    return Response(
        isi,
        media_type=jenis or "application/octet-stream",
        headers={
            "Content-Disposition": f"inline; filename*=UTF-8''{quote(d.nama_berkas)}",
            "Cache-Control": "private, no-store",
        },
    )


@router.put("/{dokumen_id}/hasil-baca", summary="Koreksi hasil baca", response_model=Amplop[DokumenOut])
def koreksi(dokumen_id: uuid.UUID, data: HasilBacaIn, sesi: SesiDep, p: SaatIni) -> Amplop[DokumenOut]:
    d = layanan.koreksi(sesi, p, dokumen_id, data.hasil_baca)
    sesi.commit()
    return Amplop(data=DokumenOut.model_validate(d))


@router.post(
    "/{dokumen_id}/terapkan-ke-profil",
    summary="Isi kolom profil yang masih kosong dari hasil baca",
    response_model=Amplop[TerapkanOut],
)
def terapkan(dokumen_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[TerapkanOut]:
    d = layanan.ambil(sesi, p, dokumen_id)
    terisi = layanan.terapkan_ke_profil(sesi, p, d.hasil_baca or {})
    sesi.commit()
    return Amplop(data=TerapkanOut(kolom_terisi=terisi))


@router.delete("/{dokumen_id}", summary="Hapus dokumen", response_model=Amplop[Kosong])
def hapus(dokumen_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.hapus(sesi, p, dokumen_id)
    sesi.commit()
    return Amplop(data=Kosong())
