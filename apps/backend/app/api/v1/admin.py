import uuid
from datetime import date
from typing import Annotated, Literal

from fastapi import APIRouter, Depends
from pydantic import BaseModel, ConfigDict, Field, HttpUrl
from sqlalchemy.orm import Session

from app.api.deps import wajib_admin
from app.db import get_session
from app.schemas.beasiswa import BeasiswaDetail, BeasiswaRingkas, BerkasWajibOut, PersyaratanOut
from app.schemas.common import Amplop
from app.services import admin as layanan

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[Depends(wajib_admin)])

SesiDep = Annotated[Session, Depends(get_session)]

JENIS_SYARAT = Literal[
    "ipk_minimum",
    "semester_minimum",
    "semester_maksimum",
    "jenjang",
    "jenis_kampus",
    "domisili",
    "usia_maksimum",
    "sertifikat_bahasa",
    "penghasilan_maksimum",
    "kewarganegaraan",
    "berkas_pendukung",
    "lainnya",
]


class SyaratIn(BaseModel):
    jenis: JENIS_SYARAT
    nilai_batas: dict | None = None
    dapat_dikejar: bool = False


class AntreanItem(BeasiswaRingkas):
    status: str
    alasan_ditandai: str | None = None
    nama_sumber: str


class PerbaikiIn(BaseModel):
    nama: str | None = Field(None, min_length=3, max_length=300)
    penyelenggara: str | None = Field(None, max_length=200)
    negara: str | None = Field(None, max_length=80)
    jenjang: list[Literal["D3", "D4", "S1", "S2", "S3"]] | None = None
    manfaat: str | None = Field(None, max_length=2000)
    tenggat: date | None = None
    tautan_resmi: HttpUrl | None = None
    persyaratan: list[SyaratIn] | None = None
    berkas_wajib: list[str] | None = None


class ManualIn(BaseModel):
    nama: str = Field(min_length=3, max_length=300)
    penyelenggara: str | None = Field(None, max_length=200)
    negara: str | None = Field(None, max_length=80)
    jenjang: list[Literal["D3", "D4", "S1", "S2", "S3"]] | None = None
    manfaat: str | None = Field(None, max_length=2000)
    tenggat: date | None = None
    tautan_resmi: HttpUrl
    persyaratan: list[SyaratIn] = []
    berkas_wajib: list[str] = []


class TolakIn(BaseModel):
    alasan: str = Field(min_length=3, max_length=500)


class DetailAdmin(BeasiswaDetail):
    status: str
    alasan_ditandai: str | None = None


class SumberOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    nama: str
    url: str
    jenis: str
    negara: str | None = None
    jadwal: str | None = None
    status_terakhir: str
    aktif: bool


class SumberIn(BaseModel):
    nama: str = Field(min_length=3, max_length=200)
    url: HttpUrl
    jenis: Literal["pantau_otomatis", "tautan_keluar", "input_manual", "rujukan"]
    negara: str | None = Field(None, max_length=80)
    jadwal: str | None = Field(None, max_length=60)
    aktif: bool = True


class SumberUbahIn(BaseModel):
    nama: str | None = Field(None, min_length=3, max_length=200)
    jenis: Literal["pantau_otomatis", "tautan_keluar", "input_manual", "rujukan"] | None = None
    negara: str | None = None
    jadwal: str | None = None
    aktif: bool | None = None


def _detail(b, syarat, berkas) -> DetailAdmin:
    ringkas = BeasiswaRingkas.model_validate(b).model_dump()
    return DetailAdmin(
        **ringkas,
        manfaat=b.manfaat,
        tanggal_diperiksa=b.tanggal_diperiksa,
        persyaratan=[PersyaratanOut.model_validate(s) for s in syarat],
        berkas_wajib=[BerkasWajibOut.model_validate(x) for x in berkas],
        status=b.status,
        alasan_ditandai=b.alasan_ditandai,
    )


@router.get("/antrean-validasi", summary="Beasiswa menunggu validasi", response_model=Amplop[list[AntreanItem]])
def antrean(sesi: SesiDep) -> Amplop[list[AntreanItem]]:
    item = [
        AntreanItem(
            **BeasiswaRingkas.model_validate(b).model_dump(),
            status=b.status,
            alasan_ditandai=b.alasan_ditandai,
            nama_sumber=nama,
        )
        for b, nama in layanan.antrean(sesi)
    ]
    return Amplop(data=item)


@router.get("/beasiswa/{beasiswa_id}", summary="Detail beasiswa untuk validasi", response_model=Amplop[DetailAdmin])
def detail(beasiswa_id: uuid.UUID, sesi: SesiDep) -> Amplop[DetailAdmin]:
    return Amplop(data=_detail(*layanan.detail(sesi, beasiswa_id)))


@router.put("/beasiswa/{beasiswa_id}", summary="Perbaiki data beasiswa", response_model=Amplop[DetailAdmin])
def perbaiki(beasiswa_id: uuid.UUID, data: PerbaikiIn, sesi: SesiDep) -> Amplop[DetailAdmin]:
    isi = data.model_dump(exclude_unset=True, exclude={"persyaratan", "berkas_wajib"})
    if "tautan_resmi" in isi and isi["tautan_resmi"] is not None:
        isi["tautan_resmi"] = str(isi["tautan_resmi"])
    syarat = [s.model_dump() for s in data.persyaratan] if data.persyaratan is not None else None
    layanan.perbaiki(sesi, beasiswa_id, isi, syarat, data.berkas_wajib)
    sesi.commit()
    return Amplop(data=_detail(*layanan.detail(sesi, beasiswa_id)))


@router.post("/beasiswa/{beasiswa_id}/terbitkan", summary="Terbitkan beasiswa", response_model=Amplop[DetailAdmin])
def terbitkan(beasiswa_id: uuid.UUID, sesi: SesiDep) -> Amplop[DetailAdmin]:
    layanan.terbitkan(sesi, beasiswa_id, date.today())
    sesi.commit()
    return Amplop(data=_detail(*layanan.detail(sesi, beasiswa_id)))


@router.post(
    "/beasiswa/{beasiswa_id}/tolak",
    summary="Tolak beasiswa dengan alasan",
    response_model=Amplop[DetailAdmin],
)
def tolak(beasiswa_id: uuid.UUID, data: TolakIn, sesi: SesiDep) -> Amplop[DetailAdmin]:
    layanan.tolak(sesi, beasiswa_id, data.alasan)
    sesi.commit()
    return Amplop(data=_detail(*layanan.detail(sesi, beasiswa_id)))


@router.post("/beasiswa", status_code=201, summary="Input beasiswa manual", response_model=Amplop[DetailAdmin])
def manual(data: ManualIn, sesi: SesiDep) -> Amplop[DetailAdmin]:
    isi = data.model_dump(exclude={"persyaratan", "berkas_wajib"})
    isi["tautan_resmi"] = str(data.tautan_resmi)
    b = layanan.input_manual(sesi, isi, [s.model_dump() for s in data.persyaratan], data.berkas_wajib)
    sesi.commit()
    return Amplop(data=_detail(*layanan.detail(sesi, b.id)))


@router.get("/sumber", summary="Daftar sumber dan status terakhir", response_model=Amplop[list[SumberOut]])
def daftar_sumber(sesi: SesiDep) -> Amplop[list[SumberOut]]:
    return Amplop(data=[SumberOut.model_validate(s) for s in layanan.daftar_sumber(sesi)])


@router.post("/sumber", status_code=201, summary="Tambah sumber", response_model=Amplop[SumberOut])
def tambah_sumber(data: SumberIn, sesi: SesiDep) -> Amplop[SumberOut]:
    isi = data.model_dump()
    isi["url"] = str(data.url)
    s = layanan.tambah_sumber(sesi, isi)
    sesi.commit()
    return Amplop(data=SumberOut.model_validate(s))


@router.put("/sumber/{sumber_id}", summary="Ubah sumber", response_model=Amplop[SumberOut])
def ubah_sumber(sumber_id: uuid.UUID, data: SumberUbahIn, sesi: SesiDep) -> Amplop[SumberOut]:
    s = layanan.ubah_sumber(sesi, sumber_id, data.model_dump(exclude_unset=True))
    sesi.commit()
    return Amplop(data=SumberOut.model_validate(s))


@router.get("/laporan", summary="Ringkasan sistem", response_model=Amplop[dict])
def laporan(sesi: SesiDep) -> Amplop[dict]:
    return Amplop(data=layanan.laporan(sesi))
