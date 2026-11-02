"""Batas toleransi dan bobot skor. Dibaca dari satu tempat agar mudah ditinjau ulang (aturan kelayakan 26 Oktober 2026)."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Toleransi:
    ipk: float = 0.25  # kurang paling banyak 0,25 dari syarat
    semester: int = 1  # kurang paling banyak satu semester
    skor_bahasa_persen: float = 0.10  # skor kurang paling banyak 10 persen


@dataclass(frozen=True)
class Bobot:
    kelayakan: float = 0.6
    kemiripan: float = 0.4


TOLERANSI = Toleransi()
BOBOT = Bobot()
VERSI_MODEL = "aturan-1.0+hash-384"
