import uuid
from datetime import date
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, StringConstraints, field_validator

from app.rekomendasi.wilayah import negara_kanonik, provinsi_kanonik

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


Pendek = Annotated[str, StringConstraints(strip_whitespace=True, min_length=1, max_length=120)]
Tahun = Annotated[int, Field(ge=1990, le=2100)] | None
TINGKAT_PRESTASI = Literal["sekolah", "kota", "provinsi", "nasional", "internasional"]


class Organisasi(BaseModel):
    nama: Pendek
    jabatan: Annotated[str, StringConstraints(strip_whitespace=True, max_length=80)] | None = None
    tahun: Tahun = None


class Prestasi(BaseModel):
    nama: Pendek
    tingkat: TINGKAT_PRESTASI | None = None
    tahun: Tahun = None


class Sertifikat(BaseModel):
    nama: Pendek
    penerbit: Annotated[str, StringConstraints(strip_whitespace=True, max_length=120)] | None = None
    tahun: Tahun = None


class Pengalaman(BaseModel):
    nama: Pendek
    peran: Annotated[str, StringConstraints(strip_whitespace=True, max_length=80)] | None = None
    tahun: Tahun = None


class TargetStudi(BaseModel):
    jenjang: list[Literal["D3", "D4", "S1", "S2", "S3"]] = []
    negara: list[Pendek] = Field(default=[], max_length=10)
    bidang: list[Pendek] = Field(default=[], max_length=10)


class ProfilLanjutan(BaseModel):
    """Profil lanjutan (opsional) untuk pencarian yang lebih terarah. Dikirim utuh; mengganti isi sebelumnya."""

    provinsi_asal: Annotated[str, StringConstraints(strip_whitespace=True, max_length=80)] | None = None
    kota_asal: Annotated[str, StringConstraints(strip_whitespace=True, max_length=80)] | None = None
    sekolah_asal: Annotated[str, StringConstraints(strip_whitespace=True, max_length=150)] | None = None
    jenis_sekolah: Literal["SMA", "SMK", "MA", "Pesantren", "Lainnya"] | None = None
    jurusan_sekolah: Annotated[str, StringConstraints(strip_whitespace=True, max_length=80)] | None = None
    tahun_lulus: Tahun = None
    fakultas: Annotated[str, StringConstraints(strip_whitespace=True, max_length=120)] | None = None
    organisasi: list[Organisasi] = Field(default=[], max_length=20)
    prestasi: list[Prestasi] = Field(default=[], max_length=20)
    sertifikat: list[Sertifikat] = Field(default=[], max_length=20)
    pengalaman: list[Pengalaman] = Field(default=[], max_length=20)
    keahlian: list[Pendek] = Field(default=[], max_length=30)
    target_studi: TargetStudi | None = None


class ProfilIn(BaseModel):
    """Semua kolom opsional; hanya kolom yang dikirim yang diubah."""

    nama: Teks | None = None
    tanggal_lahir: date | None = None
    kota_domisili: Annotated[str, StringConstraints(strip_whitespace=True, max_length=120)] | None = None
    negara_domisili: Annotated[str, StringConstraints(strip_whitespace=True, max_length=80)] | None = None
    provinsi_domisili: Annotated[str, StringConstraints(strip_whitespace=True, max_length=80)] | None = None
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
    profil_lanjutan: ProfilLanjutan | None = None

    @field_validator("tanggal_lahir")
    @classmethod
    def _lahir(cls, v: date | None) -> date | None:
        if v is not None and not (date(1900, 1, 1) <= v <= date.today()):
            raise ValueError("Tanggal lahir tidak masuk akal (harus antara 1900 dan hari ini)")
        return v

    @field_validator("negara_domisili")
    @classmethod
    def _negara(cls, v: str | None) -> str | None:
        if v is None:
            return None
        baku = negara_kanonik(v)
        if baku is None:
            raise ValueError("Negara domisili harus dipilih dari daftar negara (GET /referensi/wilayah)")
        return baku

    @field_validator("provinsi_domisili")
    @classmethod
    def _provinsi(cls, v: str | None) -> str | None:
        if v is None:
            return None
        baku = provinsi_kanonik(v)
        if baku is None:
            raise ValueError("Provinsi domisili harus dipilih dari daftar provinsi Indonesia (GET /referensi/wilayah)")
        return baku

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "negara_domisili": "Indonesia",
                "provinsi_domisili": "Jawa Timur",
                "kota_domisili": "Malang",
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
    negara_domisili: str | None = None
    provinsi_domisili: str | None = None
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
    profil_lanjutan: dict | None = None
    preferensi_notifikasi: dict


class ReferensiWilayahOut(BaseModel):
    negara: list[str]
    provinsi: list[str]
    negara_asal: str
