import uuid
from datetime import datetime
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, File, Form, UploadFile
from pydantic import BaseModel, ConfigDict
from sqlalchemy.orm import Session

from app.api.deps import pengguna_saat_ini
from app.core.config import Settings, get_settings
from app.core.errors import ValidationFailed
from app.db import get_session
from app.models import Pengguna
from app.schemas.common import Amplop, Kosong
from app.services import dokumen as layanan

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


class HasilBacaIn(BaseModel):
    hasil_baca: dict


class TerapkanOut(BaseModel):
    kolom_terisi: list[str]


@router.post("", status_code=201, summary="Unggah dokumen (maksimal 5 MB)", response_model=Amplop[DokumenOut])
async def unggah(
    sesi: SesiDep,
    p: SaatIni,
    settings: SettingsDep,
    jenis: Annotated[Literal["cv", "sertifikat", "pengalaman_organisasi"], Form()],
    berkas: Annotated[UploadFile, File()],
) -> Amplop[DokumenOut]:
    isi = await berkas.read(settings.upload_maks_byte + 1)
    if not berkas.filename:
        raise ValidationFailed("Nama berkas kosong")
    d = layanan.simpan(sesi, p, jenis, berkas.filename, isi, settings)
    sesi.commit()
    return Amplop(data=DokumenOut.model_validate(d))


@router.get("", summary="Daftar dokumen dan status baca", response_model=Amplop[list[DokumenOut]])
def daftar(sesi: SesiDep, p: SaatIni) -> Amplop[list[DokumenOut]]:
    return Amplop(data=[DokumenOut.model_validate(d) for d in layanan.daftar(sesi, p)])


@router.get("/{dokumen_id}", summary="Detail dan hasil baca", response_model=Amplop[DokumenOut])
def detail(dokumen_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[DokumenOut]:
    return Amplop(data=DokumenOut.model_validate(layanan.ambil(sesi, p, dokumen_id)))


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
