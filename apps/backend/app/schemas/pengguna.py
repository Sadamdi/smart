import uuid
from datetime import date
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, StringConstraints

Teks = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)]
KataSandi = Annotated[str, StringConstraints(min_length=8, max_length=128)]


class DaftarIn(BaseModel):
    nama: Teks
    email: EmailStr
    kata_sandi: KataSandi

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "nama": "Nur Contoh",
                "email": "mahasiswa@example.com",
                "kata_sandi": "kata-sandi-panjang",
            }
        }
    )


class MasukIn(BaseModel):
    email: EmailStr
    kata_sandi: Annotated[str, StringConstraints(min_length=1, max_length=128)]

    model_config = ConfigDict(
        json_schema_extra={"example": {"email": "mahasiswa@example.com", "kata_sandi": "kata-sandi-panjang"}}
    )


class SegarkanIn(BaseModel):
    token_penyegar: str


class GantiSandiIn(BaseModel):
    kata_sandi_lama: Annotated[str, StringConstraints(min_length=1, max_length=128)]
    kata_sandi_baru: KataSandi


class TokenOut(BaseModel):
    token_akses: str
    token_penyegar: str
    kedaluwarsa_detik: int


class ProfilIn(BaseModel):
    """Semua kolom opsional; hanya kolom yang dikirim yang diubah."""

    nama: Teks | None = None
    tanggal_lahir: date | None = None
    kota_domisili: Annotated[str, StringConstraints(strip_whitespace=True, max_length=120)] | None = None
    kampus: Annotated[str, StringConstraints(strip_whitespace=True, max_length=200)] | None = None
    jenis_kampus: Literal["negeri", "swasta"] | None = None
    program_studi: Annotated[str, StringConstraints(strip_whitespace=True, max_length=200)] | None = None
    jenjang: Literal["D3", "D4", "S1", "S2", "S3"] | None = None
    semester: Annotated[int, Field(ge=1, le=14)] | None = None
    ipk: Annotated[Decimal, Field(ge=0, le=4, max_digits=3, decimal_places=2)] | None = None
    ips_terakhir: Annotated[Decimal, Field(ge=0, le=4, max_digits=3, decimal_places=2)] | None = None
    minat: (
        Annotated[
            list[Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=60)]],
            Field(max_length=20),
        ]
        | None
    ) = None
    penghasilan_orang_tua: Annotated[int, Field(ge=0)] | None = None
    skor_bahasa: dict[str, str | int | float] | None = None
    kewarganegaraan: Annotated[str, StringConstraints(strip_whitespace=True, max_length=80)] | None = None
    kondisi_khusus: (
        Annotated[
            list[
                Literal[
                    "disabilitas",
                    "ekonomi_kurang_mampu",
                    "yatim_piatu",
                    "daerah_3t",
                    "penghafal_quran",
                    "anak_tenaga_kesehatan",
                ]
            ],
            Field(max_length=10),
        ]
        | None
    ) = None
    catatan_tambahan: Annotated[str, StringConstraints(strip_whitespace=True, max_length=1000)] | None = None

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "kampus": "UIN Maulana Malik Ibrahim Malang",
                "jenis_kampus": "negeri",
                "jenjang": "S1",
                "semester": 5,
                "ipk": "3.60",
                "minat": ["teknologi", "data"],
            }
        }
    )


class PreferensiNotifikasiIn(BaseModel):
    email: bool
    push: bool


class PenggunaOut(BaseModel):
    """Profil yang boleh dilihat pemiliknya. Tidak memuat kata sandi, versi token, atau vektor."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: str
    peran: str
    nama: str
    tanggal_lahir: date | None = None
    kota_domisili: str | None = None
    kampus: str | None = None
    jenis_kampus: str | None = None
    program_studi: str | None = None
    jenjang: str | None = None
    semester: int | None = None
    ipk: Decimal | None = None
    ips_terakhir: Decimal | None = None
    minat: list[str] | None = None
    penghasilan_orang_tua: int | None = None
    skor_bahasa: dict | None = None
    kewarganegaraan: str | None = None
    kondisi_khusus: list[str] | None = None
    catatan_tambahan: str | None = None
    preferensi_notifikasi: dict
