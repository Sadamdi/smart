import uuid
from typing import Protocol

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.errors import Conflict
from app.models import Pengguna


class PenggunaRepo(Protocol):
    def by_email(self, email: str) -> Pengguna | None: ...
    def by_id(self, pengguna_id: uuid.UUID) -> Pengguna | None: ...
    def tambah(self, pengguna: Pengguna) -> Pengguna: ...
    def simpan(self, pengguna: Pengguna) -> Pengguna: ...
    def naikkan_versi(self, pengguna: Pengguna) -> Pengguna: ...
    def hapus(self, pengguna: Pengguna) -> None: ...


class PenggunaRepoSql:
    """Satu-satunya lapisan yang menyentuh tabel pengguna."""

    def __init__(self, sesi: Session) -> None:
        self.sesi = sesi

    def by_email(self, email: str) -> Pengguna | None:
        return self.sesi.scalar(select(Pengguna).where(func.lower(Pengguna.email) == email.lower()))

    def by_id(self, pengguna_id: uuid.UUID) -> Pengguna | None:
        return self.sesi.get(Pengguna, pengguna_id)

    def tambah(self, pengguna: Pengguna) -> Pengguna:
        self.sesi.add(pengguna)
        try:
            self.sesi.commit()
        except IntegrityError as exc:  # pendaftaran ganda yang lolos pemeriksaan awal
            self.sesi.rollback()
            raise Conflict("Email sudah terdaftar") from exc
        self.sesi.refresh(pengguna)
        return pengguna

    def simpan(self, pengguna: Pengguna) -> Pengguna:
        self.sesi.commit()
        self.sesi.refresh(pengguna)
        return pengguna

    def naikkan_versi(self, pengguna: Pengguna) -> Pengguna:
        pengguna.versi_token = (pengguna.versi_token or 0) + 1
        return self.simpan(pengguna)

    def hapus(self, pengguna: Pengguna) -> None:
        self.sesi.delete(pengguna)
        self.sesi.commit()
