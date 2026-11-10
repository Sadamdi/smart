import uuid
from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class BeasiswaRingkas(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    nama: str
    penyelenggara: str | None = None
    negara: str | None = None
    jenjang: list[str] | None = None
    tenggat: date | None = None
    tautan_resmi: str


class PersyaratanOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    jenis: str
    nilai_batas: dict | None = None
    dapat_dikejar: bool
    # Penilaian terhadap profil pengguna yang sedang masuk; None bila syarat hanya informasi.
    status: str | None = None  # terpenuhi, dalam_toleransi, gagal, tidak_diketahui
    catatan: str | None = None


class BerkasWajibOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    nama_berkas: str


class BeasiswaDetail(BeasiswaRingkas):
    manfaat: str | None = None
    tanggal_diperiksa: datetime | None = None
    persyaratan: list[PersyaratanOut] = []
    berkas_wajib: list[BerkasWajibOut] = []
    kategori: str | None = None  # memenuhi, hampir_memenuhi, belum_memenuhi
    alasan: list[str] = []
    catatan_kekurangan: list[str] = []
