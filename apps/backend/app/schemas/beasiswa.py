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


class BerkasWajibOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    nama_berkas: str


class BeasiswaDetail(BeasiswaRingkas):
    manfaat: str | None = None
    tanggal_diperiksa: datetime | None = None
    persyaratan: list[PersyaratanOut] = []
    berkas_wajib: list[BerkasWajibOut] = []
