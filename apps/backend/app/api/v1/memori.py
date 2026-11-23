import uuid
from datetime import datetime
from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.orm import Session

from app.api.deps import pengguna_saat_ini
from app.db import get_session
from app.models import Pengguna
from app.schemas.common import Amplop, Kosong
from app.services import memori as layanan
from app.services import pembersihan

router = APIRouter(prefix="/me/memori", tags=["memori"])

SesiDep = Annotated[Session, Depends(get_session)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]


class MemoriOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    jenis: str
    isi: str
    sumber: str | None = None
    aktif: bool = True
    dibuat_pada: datetime


class MemoriIn(BaseModel):
    jenis: str = Field(max_length=20)
    isi: str = Field(min_length=1, max_length=480)


class UbahIn(BaseModel):
    isi: str | None = Field(default=None, max_length=480)
    aktif: bool | None = None


class PengaturanIn(BaseModel):
    aktif: bool


class StatistikOut(BaseModel):
    memori_aktif: bool
    jumlah: int
    jumlah_dipakai: int
    perkiraan_token: int
    per_jenis: dict[str, int]


@router.get("/statistik", summary="Ringkasan memori dan beban tambahannya", response_model=Amplop[StatistikOut])
def statistik(sesi: SesiDep, p: SaatIni) -> Amplop[StatistikOut]:
    return Amplop(data=StatistikOut(**layanan.statistik(sesi, p)))


@router.put("/pengaturan", summary="Saklar utama memori (hidup atau mati)", response_model=Amplop[StatistikOut])
def atur(data: PengaturanIn, sesi: SesiDep, p: SaatIni) -> Amplop[StatistikOut]:
    p.memori_aktif = data.aktif
    sesi.commit()
    return Amplop(data=StatistikOut(**layanan.statistik(sesi, p)))


@router.get("", summary="Memori tentang pengguna (dari dokumen dan percakapan)", response_model=Amplop[list[MemoriOut]])
def daftar(sesi: SesiDep, p: SaatIni) -> Amplop[list[MemoriOut]]:
    if pembersihan.bersihkan_memori(sesi, p):  # butir otomatis yang dinonaktifkan dan lama tak terpakai
        sesi.commit()
    return Amplop(data=[MemoriOut.model_validate(m) for m in layanan.daftar(sesi, p)])


@router.post("", status_code=201, summary="Tambah butir memori manual", response_model=Amplop[Kosong])
def tambah(data: MemoriIn, sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.tambah(sesi, p, data.jenis, data.isi, "manual")
    sesi.commit()
    return Amplop(data=Kosong())


@router.patch("/{memori_id}", summary="Ubah isi atau hidupkan dan matikan satu butir", response_model=Amplop[MemoriOut])
def ubah(memori_id: uuid.UUID, data: UbahIn, sesi: SesiDep, p: SaatIni) -> Amplop[MemoriOut]:
    m = layanan.ubah(sesi, p, memori_id, data.isi, data.aktif)
    sesi.commit()
    return Amplop(data=MemoriOut.model_validate(m))


@router.delete("/{memori_id}", summary="Hapus satu butir memori", response_model=Amplop[Kosong])
def hapus(memori_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.hapus(sesi, p, memori_id)
    sesi.commit()
    return Amplop(data=Kosong())


@router.delete("", summary="Hapus seluruh memori", response_model=Amplop[Kosong])
def hapus_semua(sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.hapus_semua(sesi, p)
    sesi.commit()
    return Amplop(data=Kosong())
