import base64
import uuid
from dataclasses import dataclass
from datetime import date
from typing import Protocol

from sqlalchemy import select, tuple_
from sqlalchemy.orm import Session

from app.core.errors import ValidationFailed
from app.models import Beasiswa, BerkasWajib, Persyaratan


@dataclass
class FilterBeasiswa:
    q: str | None = None
    jenjang: str | None = None
    negara: str | None = None


@dataclass
class HalamanBeasiswa:
    item: list[Beasiswa]
    kursor_berikut: str | None


@dataclass
class DetailBeasiswa:
    beasiswa: Beasiswa
    persyaratan: list[Persyaratan]
    berkas_wajib: list[BerkasWajib]


class BeasiswaRepo(Protocol):
    def daftar(
        self, filter_: FilterBeasiswa, kursor: str | None, batas: int, hari_ini: date
    ) -> HalamanBeasiswa: ...
    def detail(self, beasiswa_id: uuid.UUID, hari_ini: date) -> DetailBeasiswa | None: ...


def kodekan_kursor(tenggat: date, beasiswa_id: uuid.UUID) -> str:
    return base64.urlsafe_b64encode(f"{tenggat.isoformat()}|{beasiswa_id}".encode()).decode()


def baca_kursor(kursor: str) -> tuple[date, uuid.UUID]:
    try:
        tgl, ident = base64.urlsafe_b64decode(kursor.encode()).decode().split("|")
        return date.fromisoformat(tgl), uuid.UUID(ident)
    except (ValueError, UnicodeDecodeError) as exc:
        raise ValidationFailed("kursor tidak valid") from exc


def _escape_like(teks: str) -> str:
    return teks.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


class BeasiswaRepoSql:
    """Hanya beasiswa berstatus terbit dengan tenggat belum lewat yang terlihat oleh mahasiswa (FR-SM-03)."""

    def __init__(self, sesi: Session) -> None:
        self.sesi = sesi

    def daftar(
        self, filter_: FilterBeasiswa, kursor: str | None, batas: int, hari_ini: date
    ) -> HalamanBeasiswa:
        stmt = select(Beasiswa).where(
            Beasiswa.status == "terbit", Beasiswa.tenggat.is_not(None), Beasiswa.tenggat >= hari_ini
        )
        if filter_.q:
            pola = f"%{_escape_like(filter_.q)}%"
            stmt = stmt.where(
                Beasiswa.nama.ilike(pola, escape="\\") | Beasiswa.penyelenggara.ilike(pola, escape="\\")
            )
        if filter_.jenjang:
            stmt = stmt.where(Beasiswa.jenjang.contains([filter_.jenjang]))
        if filter_.negara:
            stmt = stmt.where(Beasiswa.negara == filter_.negara)
        if kursor:
            tgl, ident = baca_kursor(kursor)
            stmt = stmt.where(tuple_(Beasiswa.tenggat, Beasiswa.id) > tuple_(tgl, ident))
        stmt = stmt.order_by(Beasiswa.tenggat, Beasiswa.id).limit(batas + 1)
        baris = list(self.sesi.scalars(stmt))
        berikut = None
        if len(baris) > batas:
            baris = baris[:batas]
            terakhir = baris[-1]
            berikut = kodekan_kursor(terakhir.tenggat, terakhir.id)
        return HalamanBeasiswa(item=baris, kursor_berikut=berikut)

    def detail(self, beasiswa_id: uuid.UUID, hari_ini: date) -> DetailBeasiswa | None:
        b = self.sesi.scalar(
            select(Beasiswa).where(
                Beasiswa.id == beasiswa_id, Beasiswa.status == "terbit", Beasiswa.tenggat >= hari_ini
            )
        )
        if b is None:
            return None
        syarat = list(self.sesi.scalars(select(Persyaratan).where(Persyaratan.beasiswa_id == b.id)))
        berkas = list(self.sesi.scalars(select(BerkasWajib).where(BerkasWajib.beasiswa_id == b.id)))
        return DetailBeasiswa(beasiswa=b, persyaratan=syarat, berkas_wajib=berkas)
