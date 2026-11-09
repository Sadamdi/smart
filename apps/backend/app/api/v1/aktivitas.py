import uuid
from datetime import date, timedelta
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.api.deps import pengguna_saat_ini
from app.db import get_session
from app.models import Pengguna
from app.schemas.beasiswa import BeasiswaRingkas
from app.schemas.common import Amplop, Kosong
from app.services import aktivitas as layanan

router = APIRouter(tags=["interaksi dan kalender"])

SesiDep = Annotated[Session, Depends(get_session)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]


class InteraksiIn(BaseModel):
    aksi: Literal["klik", "simpan", "rencana_daftar"]
    status_rencana: Literal["akan_daftar", "sudah_daftar", "tidak_jadi"] | None = None


class InteraksiOut(BaseModel):
    id: uuid.UUID
    aksi: str
    status_rencana: str | None = None


class TersimpanOut(BaseModel):
    beasiswa: BeasiswaRingkas
    status_rencana: str | None = None


class BerkasChecklistOut(BaseModel):
    id: uuid.UUID
    nama_berkas: str
    selesai: bool


class ChecklistBeasiswaOut(BaseModel):
    beasiswa: BeasiswaRingkas
    berkas: list[BerkasChecklistOut]


class CentangIn(BaseModel):
    selesai: bool


class AcaraOut(BaseModel):
    jenis: Literal["tenggat", "tugas"]
    tanggal: date
    judul: str
    ref_id: uuid.UUID
    selesai: bool


class TugasIn(BaseModel):
    judul: str = Field(min_length=1, max_length=200)
    tanggal: date


class TugasUbahIn(BaseModel):
    judul: str | None = Field(None, min_length=1, max_length=200)
    tanggal: date | None = None
    selesai: bool | None = None


class TugasOut(BaseModel):
    id: uuid.UUID
    judul: str
    tanggal: date
    selesai: bool


class NotifikasiOut(BaseModel):
    id: uuid.UUID
    jenis: str
    dibaca: bool
    tanggal_acuan: date
    judul: str
    pesan: str
    beasiswa_id: uuid.UUID


@router.post(
    "/beasiswa/{beasiswa_id}/interaksi",
    status_code=201,
    summary="Catat klik, simpan, atau rencana daftar",
    response_model=Amplop[InteraksiOut],
)
def interaksi(beasiswa_id: uuid.UUID, data: InteraksiIn, sesi: SesiDep, p: SaatIni) -> Amplop[InteraksiOut]:
    i = layanan.catat_interaksi(sesi, p, beasiswa_id, data.aksi, data.status_rencana, date.today())
    sesi.commit()
    return Amplop(data=InteraksiOut(id=i.id, aksi=i.aksi, status_rencana=i.status_rencana))


@router.delete("/beasiswa/{beasiswa_id}/interaksi/simpan", summary="Batalkan simpan", response_model=Amplop[Kosong])
def batal_simpan(beasiswa_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.batal_simpan(sesi, p, beasiswa_id)
    sesi.commit()
    return Amplop(data=Kosong())


@router.get("/me/tersimpan", summary="Beasiswa tersimpan", response_model=Amplop[list[TersimpanOut]])
def tersimpan(sesi: SesiDep, p: SaatIni) -> Amplop[list[TersimpanOut]]:
    return Amplop(
        data=[
            TersimpanOut(beasiswa=BeasiswaRingkas.model_validate(b), status_rencana=r)
            for b, r in layanan.tersimpan(sesi, p, date.today())
        ]
    )


@router.get(
    "/me/checklist",
    summary="Checklist berkas beasiswa tersimpan",
    response_model=Amplop[list[ChecklistBeasiswaOut]],
)
def checklist(sesi: SesiDep, p: SaatIni) -> Amplop[list[ChecklistBeasiswaOut]]:
    return Amplop(
        data=[
            ChecklistBeasiswaOut(
                beasiswa=BeasiswaRingkas.model_validate(b),
                berkas=[BerkasChecklistOut(id=x.id, nama_berkas=x.nama_berkas, selesai=s) for x, s in berkas],
            )
            for b, berkas in layanan.checklist(sesi, p, date.today())
        ]
    )


@router.put(
    "/me/checklist/{berkas_wajib_id}",
    summary="Centang atau batalkan berkas",
    response_model=Amplop[CentangIn],
)
def centang(berkas_wajib_id: uuid.UUID, data: CentangIn, sesi: SesiDep, p: SaatIni) -> Amplop[CentangIn]:
    layanan.centang(sesi, p, berkas_wajib_id, data.selesai, date.today())
    sesi.commit()
    return Amplop(data=CentangIn(selesai=data.selesai))


@router.get("/me/kalender", summary="Tenggat dan tugas pada rentang tanggal", response_model=Amplop[list[AcaraOut]])
def kalender(
    sesi: SesiDep,
    p: SaatIni,
    dari: Annotated[date | None, Query()] = None,
    sampai: Annotated[date | None, Query()] = None,
) -> Amplop[list[AcaraOut]]:
    hari = date.today()
    dari = dari or hari
    sampai = sampai or hari + timedelta(days=60)
    return Amplop(data=[AcaraOut(**a) for a in layanan.kalender(sesi, p, dari, sampai, hari)])


@router.post("/me/tugas", status_code=201, summary="Tambah tugas pribadi", response_model=Amplop[TugasOut])
def tambah_tugas(data: TugasIn, sesi: SesiDep, p: SaatIni) -> Amplop[TugasOut]:
    t = layanan.tambah_tugas(sesi, p, data.judul, data.tanggal)
    sesi.commit()
    return Amplop(data=TugasOut(id=t.id, judul=t.judul, tanggal=t.tanggal, selesai=t.selesai))


@router.put("/me/tugas/{tugas_id}", summary="Ubah atau selesaikan tugas", response_model=Amplop[TugasOut])
def ubah_tugas(tugas_id: uuid.UUID, data: TugasUbahIn, sesi: SesiDep, p: SaatIni) -> Amplop[TugasOut]:
    t = layanan.ubah_tugas(sesi, p, tugas_id, data.model_dump(exclude_unset=True))
    sesi.commit()
    return Amplop(data=TugasOut(id=t.id, judul=t.judul, tanggal=t.tanggal, selesai=t.selesai))


@router.delete("/me/tugas/{tugas_id}", summary="Hapus tugas", response_model=Amplop[Kosong])
def hapus_tugas(tugas_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.hapus_tugas(sesi, p, tugas_id)
    sesi.commit()
    return Amplop(data=Kosong())


def _pesan(tenggat: date, hari_ini: date, nama: str) -> tuple[str, str]:
    sisa = (tenggat - hari_ini).days
    kapan = "hari ini" if sisa == 0 else f"{sisa} hari lagi"
    return (
        f"Tenggat {nama}",
        f"Batas pendaftaran {tenggat.strftime('%d-%m-%Y')} ({kapan}). Periksa kelengkapan berkas.",
    )


@router.get("/notifikasi", summary="Daftar notifikasi", response_model=Amplop[list[NotifikasiOut]])
def notifikasi(sesi: SesiDep, p: SaatIni) -> Amplop[list[NotifikasiOut]]:
    hari = date.today()
    pasangan = layanan.daftar_notifikasi(sesi, p, hari)
    sesi.commit()
    hasil = []
    for n, b in pasangan:
        judul, pesan = _pesan(n.tanggal_acuan, hari, b.nama)
        hasil.append(
            NotifikasiOut(
                id=n.id,
                jenis=n.jenis,
                dibaca=n.dibaca,
                tanggal_acuan=n.tanggal_acuan,
                judul=judul,
                pesan=pesan,
                beasiswa_id=b.id,
            )
        )
    return Amplop(data=hasil)


@router.put("/notifikasi/baca-semua", summary="Tandai semua dibaca", response_model=Amplop[Kosong])
def baca_semua(sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.tandai_semua_dibaca(sesi, p)
    sesi.commit()
    return Amplop(data=Kosong())


@router.put("/notifikasi/{notifikasi_id}/baca", summary="Tandai dibaca", response_model=Amplop[Kosong])
def baca(notifikasi_id: uuid.UUID, sesi: SesiDep, p: SaatIni) -> Amplop[Kosong]:
    layanan.tandai_dibaca(sesi, p, notifikasi_id)
    sesi.commit()
    return Amplop(data=Kosong())
