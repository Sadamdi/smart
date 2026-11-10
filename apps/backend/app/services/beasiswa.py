import uuid
from dataclasses import dataclass, field
from datetime import date

from app.core.errors import NotFound
from app.rekomendasi.kelayakan import (
    HasilKelayakan,
    ProfilKelayakan,
    dengan_jenjang_beasiswa,
    nilai_kelayakan,
    periksa_syarat,
)
from app.repositories.beasiswa import BeasiswaRepo, DetailBeasiswa, FilterBeasiswa, HalamanBeasiswa

BATAS_MAKS = 50


def daftar(repo: BeasiswaRepo, filter_: FilterBeasiswa, kursor: str | None, batas: int, hari_ini: date) -> HalamanBeasiswa:
    return repo.daftar(filter_, kursor, max(1, min(batas, BATAS_MAKS)), hari_ini)


def detail(repo: BeasiswaRepo, beasiswa_id: uuid.UUID, hari_ini: date) -> DetailBeasiswa:
    hasil = repo.detail(beasiswa_id, hari_ini)
    if hasil is None:
        raise NotFound("Beasiswa tidak ditemukan")
    return hasil


@dataclass
class PenilaianDetail:
    kelayakan: HasilKelayakan
    status_syarat: dict[int, str] = field(default_factory=dict)
    catatan_syarat: dict[int, str] = field(default_factory=dict)


def nilai_untuk(
    persyaratan: list, profil: ProfilKelayakan, hari_ini: date, jenjang_beasiswa: list[str] | None = None
) -> PenilaianDetail:
    """Menilai tiap syarat dan keseluruhan beasiswa terhadap profil pengguna (mesin yang sama dengan rekomendasi)."""
    pasangan = [(s.jenis, s.nilai_batas) for s in persyaratan]
    lengkap = dengan_jenjang_beasiswa(pasangan, jenjang_beasiswa)  # syarat tambahan berindeks setelah syarat tercatat
    hasil = PenilaianDetail(kelayakan=nilai_kelayakan(lengkap, profil, hari_ini))
    for i, (jenis, batas) in enumerate(lengkap):
        h = periksa_syarat(jenis, batas, profil, hari_ini)
        if h is None:
            continue
        hasil.status_syarat[i] = h.status
        teks = h.alasan or h.kekurangan
        if teks:
            hasil.catatan_syarat[i] = teks
    return hasil
