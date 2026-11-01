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

    jwt_secret: str = ""
    jwt_access_menit: int = 15
    jwt_refresh_hari: int = 30

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
