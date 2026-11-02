import uuid
from datetime import date

from app.core.errors import NotFound
from app.repositories.beasiswa import BeasiswaRepo, DetailBeasiswa, FilterBeasiswa, HalamanBeasiswa

BATAS_MAKS = 50


def daftar(repo: BeasiswaRepo, filter_: FilterBeasiswa, kursor: str | None, batas: int, hari_ini: date) -> HalamanBeasiswa:
    return repo.daftar(filter_, kursor, max(1, min(batas, BATAS_MAKS)), hari_ini)


def detail(repo: BeasiswaRepo, beasiswa_id: uuid.UUID, hari_ini: date) -> DetailBeasiswa:
    hasil = repo.detail(beasiswa_id, hari_ini)
    if hasil is None:
        raise NotFound("Beasiswa tidak ditemukan")
    return hasil
