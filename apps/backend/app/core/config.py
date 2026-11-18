from functools import lru_cache
from typing import Annotated, Literal

from pydantic import field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: Literal["dev", "test", "prod"] = "dev"
    database_url: str | None = None
    # Daftar putih host basis data yang boleh dihapus isinya (uji dan skrip cleanup). Kosong di prod.
    destructive_db_hosts: Annotated[list[str], NoDecode] = []

    cors_origins: Annotated[list[str], NoDecode] = ["http://localhost:3000"]

    # Kunci enkripsi berkas dan teks dokumen di server (Fernet, 32 byte base64 urlsafe). Kosong: diturunkan dari jwt_secret.
    kunci_enkripsi: str = ""
    # Terowongan terenkripsi aplikasi (X25519 + AES-256-GCM). Kunci privat mentah 32 byte base64; kosong: terowongan mati.
    # Mode: optional (terima biasa dan terowongan), required (aplikasi lama wajib memperbarui).
    terowongan_kunci_privat: str = ""
    terowongan_kid: str = "k1"
    terowongan_kunci_lama: str = ""  # "kid:base64,kid:base64" untuk kunci yang sudah dipensiunkan
    terowongan_mode: Literal["optional", "required"] = "optional"
    jwt_secret: str = ""
    jwt_access_menit: int = 15
    jwt_refresh_hari: int = 30

    # Layanan AI (endpoint OpenAI-compatible). Kosong berarti tidak tersedia; fitur turun ke jalur manual.
    ai_base_url: str = ""
    ai_api_key: str = ""
    ai_model: str = ""
    ai_model_gambar: str = ""  # model bila pesan memuat gambar; kosong memakai ai_model
    ai_batas_harian: int = 200

    # pemicu terjadwal di dalam aplikasi: validasi AI berkala dan pemantauan harian (aktifkan di server)
    penjadwal_aktif: bool = False

    # model pemeringkat LightGBM; bila berkas tidak ada, urutan memakai skor gabungan aturan dan kemiripan
    model_peringkat_path: str = "data/model/peringkat.lgb"

    upload_dir: str = "data/unggahan"
    upload_maks_byte: int = 10 * 1024 * 1024
    # Total berkas per pengguna di server, supaya penyimpanan tidak membengkak.
    upload_total_maks_byte: int = 50 * 1024 * 1024
    # Gambar yang lebih besar dari sisi ini diperkecil sebelum disimpan.
    upload_gambar_sisi_maks: int = 1600
    # True (bawaan sejak 18 November 2026): berkas disimpan di server agar bisa dilihat dari web dan HP.
    # False: berkas dihapus segera setelah dibaca, hanya hasil baca yang disimpan.
    upload_simpan_berkas: bool = True

    @field_validator("destructive_db_hosts", "cors_origins", mode="before")
    @classmethod
    def _pisah_koma(cls, nilai: object) -> object:
        if isinstance(nilai, str):
            teks = nilai.strip()
            if not teks:
                return []
            if teks.startswith("["):
                return nilai
            return [bagian.strip() for bagian in teks.split(",") if bagian.strip()]
        return nilai


@lru_cache
def get_settings() -> Settings:
    return Settings()
