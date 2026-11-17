from datetime import date
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api.deps import pengguna_saat_ini
from app.db import get_session
from app.models import Pengguna
from app.schemas.beasiswa import BeasiswaRingkas, KelayakanKartu
from app.schemas.common import Amplop
from app.services import rekomendasi as layanan
from app.services.kartu import peluang_untuk

router = APIRouter(prefix="/rekomendasi", tags=["rekomendasi"])

SesiDep = Annotated[Session, Depends(get_session)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]
Kategori = Literal["memenuhi", "hampir_memenuhi", "belum_memenuhi"]
Wilayah = Literal["dalam", "luar"]
Urut = Literal["peluang", "tenggat", "kecocokan"]


class RekomendasiOut(KelayakanKartu):
    """Skor kelayakan (0 sampai 100) adalah seberapa banyak syarat terukur terpenuhi, bukan peluang diterima.
    Bernilai None bila beasiswa belum punya syarat terukur."""

    beasiswa: BeasiswaRingkas
    kategori: Kategori
    alasan: list[str]
    catatan_kekurangan: list[str]
    tenggat: date | None


class RingkasanOut(BaseModel):
    memenuhi: int
    hampir_memenuhi: int
    belum_memenuhi: int


def _item(r, b, p) -> RekomendasiOut:
    ekstra = peluang_untuk(p, b, r.kategori, r.skor_kelayakan, r.alasan, r.catatan_kekurangan)
    for k in ("_alasan_peluang", "_statistik", "_dasar_peluang", "_tingkat"):
        ekstra.pop(k, None)
    return RekomendasiOut(
        beasiswa=BeasiswaRingkas.model_validate(b),
        kategori=r.kategori,
        alasan=r.alasan or [],
        catatan_kekurangan=r.catatan_kekurangan or [],
        tenggat=b.tenggat,
        **ekstra,
    )


@router.get("", summary="Rekomendasi beasiswa per kategori", response_model=Amplop[list[RekomendasiOut]])
def daftar(
    sesi: SesiDep,
    p: SaatIni,
    kategori: Annotated[Kategori | None, Query()] = None,
    wilayah: Annotated[Wilayah | None, Query(description="dalam atau luar negeri")] = None,
    batas: Annotated[int | None, Query(ge=1, le=200, description="Ambil hanya sekian teratas (Beranda memakai 1)")] = None,
    urut: Annotated[Urut, Query(description="peluang (bawaan), tenggat, atau kecocokan")] = "peluang",
    min_peluang: Annotated[int, Query(ge=0, le=90, description="Hanya yang estimasi peluangnya minimal sekian persen")] = 0,
) -> Amplop[list[RekomendasiOut]]:
    baris = layanan.daftar(sesi, p, date.today(), kategori, wilayah=wilayah)
    sesi.commit()
    item = [_item(r, b, p) for r, b in baris]
    if min_peluang:
        item = [x for x in item if (x.estimasi_peluang or 0) >= min_peluang]
    if urut == "peluang":
        # Peluang tertinggi dulu; yang belum punya estimasi (syarat belum tercatat) di akhir.
        item.sort(key=lambda x: -(x.estimasi_peluang if x.estimasi_peluang is not None else -1))
    elif urut == "tenggat":
        item.sort(key=lambda x: (x.tenggat is None, x.tenggat))
    return Amplop(data=item[:batas] if batas else item)


@router.get("/ringkasan", summary="Jumlah rekomendasi per kategori", response_model=Amplop[RingkasanOut])
def ringkasan(sesi: SesiDep, p: SaatIni, wilayah: Annotated[Wilayah | None, Query()] = None) -> Amplop[RingkasanOut]:
    hasil = layanan.ringkasan(sesi, p, date.today(), wilayah)
    sesi.commit()
    return Amplop(data=RingkasanOut(**hasil))


@router.post("/hitung-ulang", summary="Hitung ulang rekomendasi", response_model=Amplop[list[RekomendasiOut]])
def hitung_ulang(sesi: SesiDep, p: SaatIni) -> Amplop[list[RekomendasiOut]]:
    baris = layanan.daftar(sesi, p, date.today(), None, paksa=True)
    sesi.commit()
    return Amplop(data=[_item(r, b, p) for r, b in baris])
