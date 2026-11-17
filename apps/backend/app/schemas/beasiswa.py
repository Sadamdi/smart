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


class KelayakanKartu(BaseModel):
    """Penilaian terhadap profil pengguna untuk kartu. Skor adalah skor kelayakan, bukan peluang diterima."""

    kategori: str | None = None  # memenuhi, hampir_memenuhi, belum_memenuhi
    skor_kelayakan: int | None = None  # 0 sampai 100; None bila belum ada syarat terukur
    syarat_terpenuhi: int = 0
    syarat_total: int = 0
    luar_negeri: bool = False
    # Estimasi peluang diterima (2 sampai 90), perkiraan dari kecocokan syarat, kekuatan profil, dan persaingan umum.
    estimasi_peluang: int | None = None


class BeasiswaKartu(BeasiswaRingkas, KelayakanKartu):
    pass


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


class BeasiswaDetail(BeasiswaRingkas, KelayakanKartu):
    manfaat: str | None = None
    tanggal_diperiksa: datetime | None = None
    persyaratan: list[PersyaratanOut] = []
    berkas_wajib: list[BerkasWajibOut] = []
    alasan: list[str] = []
    catatan_kekurangan: list[str] = []
    alasan_peluang: list[str] = []
