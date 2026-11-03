"""Menggabungkan kelayakan dan kemiripan menjadi daftar rekomendasi terurut. Murni, tanpa basis data."""

import uuid
from dataclasses import dataclass
from datetime import date

from app.rekomendasi.embedding import Pengemas, PengemasHash, kemiripan, teks_beasiswa, teks_profil
from app.rekomendasi.kelayakan import (
    BELUM,
    HAMPIR,
    MEMENUHI,
    HasilKelayakan,
    ProfilKelayakan,
    nilai_kelayakan,
)
from app.rekomendasi.konfigurasi import BOBOT

URUTAN_KATEGORI = {MEMENUHI: 0, HAMPIR: 1, BELUM: 2}


@dataclass
class MasukanBeasiswa:
    id: uuid.UUID
    nama: str
    penyelenggara: str | None
    manfaat: str | None
    tenggat: date | None
    syarat: list[tuple[str, dict | None]]


@dataclass
class HasilRekomendasi:
    beasiswa_id: uuid.UUID
    kategori: str
    skor: float
    skor_kelayakan: float
    skor_kemiripan: float
    alasan: list[str]
    catatan_kekurangan: list[str]
    tenggat: date | None


def susun(
    profil: ProfilKelayakan,
    minat: list[str] | None,
    program_studi: str | None,
    beasiswa: list[MasukanBeasiswa],
    hari_ini: date,
    pengemas: Pengemas | None = None,
    kondisi_khusus: list[str] | None = None,
    catatan: str | None = None,
) -> list[HasilRekomendasi]:
    pengemas = pengemas or PengemasHash()
    vek_profil = pengemas.kemas(teks_profil(minat, program_studi, profil.jenjang, kondisi_khusus, catatan))
    hasil: list[HasilRekomendasi] = []
    for b in beasiswa:
        if b.tenggat is not None and b.tenggat < hari_ini:
            continue
        kel: HasilKelayakan = nilai_kelayakan(b.syarat, profil, hari_ini)
        mirip = kemiripan(vek_profil, pengemas.kemas(teks_beasiswa(b.nama, b.penyelenggara, b.manfaat)))
        alasan = list(kel.alasan)
        if mirip >= 0.15:
            alasan.append("Minat dan program studi mirip dengan fokus beasiswa")
        skor = BOBOT.kelayakan * kel.skor + BOBOT.kemiripan * mirip
        hasil.append(
            HasilRekomendasi(
                b.id,
                kel.kategori,
                round(skor, 4),
                round(kel.skor, 4),
                round(mirip, 4),
                alasan,
                kel.catatan_kekurangan,
                b.tenggat,
            )
        )
    hasil.sort(key=lambda r: (URUTAN_KATEGORI[r.kategori], -r.skor, r.tenggat or date.max))
    return hasil
