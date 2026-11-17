"""Data seleksi beasiswa yang dipublikasikan (kuota, pendaftar, penerima) beserta sumbernya.

Dipakai untuk dua hal: ditampilkan di halaman Detail sebagai dasar estimasi peluang, dan menggantikan perkiraan
persaingan umum bila ada rasio penerimaan yang terdokumentasi. Hanya sedikit beasiswa yang mengumumkan jumlah
pendaftar, jadi sebagian besar tetap memakai perkiraan, dan Detail menyatakan hal itu dengan jelas.
"""

import json
from functools import lru_cache
from pathlib import Path

BERKAS = Path(__file__).parent / "data" / "statistik_seleksi.json"


@lru_cache(maxsize=1)
def _muat() -> list[dict]:
    return json.loads(BERKAS.read_text(encoding="utf-8")).get("entri", [])


def cari(nama: str, penyelenggara: str | None) -> list[dict]:
    """Entri statistik yang cocok dengan nama atau penyelenggara, dari periode terbaru ke terlama."""
    teks = f"{nama} {penyelenggara or ''}".lower()
    cocok = [e for e in _muat() if any(k in teks for k in e["kunci"])]
    return sorted(cocok, key=lambda e: e["periode"], reverse=True)


def rasio_terbaru(entri: list[dict]) -> float | None:
    """Rasio penerimaan (0 sampai 1) dari periode terbaru yang punya rasio, dibatasi 2 sampai 60 persen."""
    for e in entri:
        r = e.get("rasio")
        if isinstance(r, int | float) and r > 0:
            return max(0.02, min(0.6, float(r)))
    return None
