"""Lapis kedua: kemiripan teks profil dan beasiswa.

Antarmuka `Pengemas` dapat diganti dengan model all-indo-e5-small-v4 (384 dimensi) bila server memadai. Cadangan bawaan
memakai hashing token sehingga berjalan di server 1 GB RAM tanpa unduhan model dan hasilnya deterministik.
"""

import hashlib
import math
import re
from typing import Protocol

DIMENSI = 384
_STOP = {"dan", "yang", "untuk", "dengan", "atau", "dari", "the", "and"}


class Pengemas(Protocol):
    def kemas(self, teks: str) -> list[float]: ...


class PengemasHash:
    def kemas(self, teks: str) -> list[float]:
        vek = [0.0] * DIMENSI
        for token in re.findall(r"[a-z0-9]+", teks.lower()):
            if token in _STOP or len(token) < 3:
                continue
            h = int(hashlib.sha1(token.encode()).hexdigest(), 16)  # noqa: S324 - bukan untuk keamanan
            vek[h % DIMENSI] += 1.0
        norma = math.sqrt(sum(x * x for x in vek))
        return [x / norma for x in vek] if norma else vek


def kemiripan(a: list[float], b: list[float]) -> float:
    """Cosine untuk vektor ternormalisasi non-negatif; hasil antara 0 dan 1."""
    return max(0.0, min(1.0, sum(x * y for x, y in zip(a, b, strict=True))))


KATA_KONDISI = {
    "disabilitas": "disabilitas difabel berkebutuhan khusus",
    "ekonomi_kurang_mampu": "kurang mampu tidak mampu ekonomi bantuan",
    "yatim_piatu": "yatim piatu",
    "daerah_3t": "daerah terpencil 3T tertinggal",
    "penghafal_quran": "hafiz penghafal quran tahfidz",
    "anak_tenaga_kesehatan": "tenaga kesehatan",
}


def teks_profil(
    minat: list[str] | None,
    program_studi: str | None,
    jenjang: str | None,
    kondisi_khusus: list[str] | None = None,
    catatan: str | None = None,
) -> str:
    kondisi = [KATA_KONDISI.get(k, k) for k in (kondisi_khusus or [])]
    return " ".join([*(minat or []), program_studi or "", jenjang or "", *kondisi, catatan or ""]).strip()


def teks_beasiswa(nama: str, penyelenggara: str | None, manfaat: str | None) -> str:
    return " ".join(x for x in (nama, penyelenggara, manfaat) if x)
