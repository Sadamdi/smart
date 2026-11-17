"""Data seleksi beasiswa yang dipublikasikan (kuota, pendaftar, penerima) beserta sumbernya.

Dipakai untuk dua hal: ditampilkan di halaman Detail sebagai dasar estimasi peluang, dan menggantikan perkiraan
tingkat persaingan bila ada rasio penerimaan yang terdokumentasi. Hanya sedikit beasiswa yang mengumumkan jumlah
pendaftar, jadi sebagian besar tetap memakai perkiraan, dan Detail menyatakan hal itu dengan jelas.
"""

import json
from functools import lru_cache
from pathlib import Path

BERKAS = Path(__file__).parent / "data" / "statistik_seleksi.json"


@lru_cache(maxsize=1)
def _muat() -> list[dict]:
    return json.loads(BERKAS.read_text(encoding="utf-8")).get("entri", [])


def cari(nama: str, penyelenggara: str | None, jenjang: list[str] | None = None) -> list[dict]:
    """Entri statistik yang cocok dengan nama atau penyelenggara, dari periode terbaru ke terlama.

    Bila entri menyebut jenjang dan beasiswa menyebut jenjangnya, keduanya harus beririsan (S2 tidak memakai data S1)."""
    teks = f"{nama} {penyelenggara or ''}".lower()
    cocok = []
    for e in _muat():
        if not any(k in teks for k in e["kunci"]):
            continue
        # Pembatas: beberapa nama umum (Beasiswa Unggulan, BPI) dipakai banyak penyelenggara; hanya yang tepat yang cocok.
        wajib = e.get("wajib_penyelenggara")
        if wajib and not any(k in (penyelenggara or "").lower() for k in wajib):
            continue
        if any(k in teks for k in e.get("kecuali", [])):
            continue
        if jenjang and e.get("jenjang") and not set(jenjang) & set(e["jenjang"]):
            continue
        cocok.append(e)
    return sorted(cocok, key=lambda e: e["periode"], reverse=True)


def rasio_terbaru(entri: list[dict]) -> float | None:
    """Rasio penerimaan (0 sampai 1): rata-rata berbobot dua periode terbaru yang punya rasio (60 persen terbaru,
    40 persen sebelumnya) supaya satu tahun yang ganjil tidak mendominasi. Dibatasi 1 sampai 60 persen."""
    rasio = [float(e["rasio"]) for e in entri if isinstance(e.get("rasio"), int | float) and e["rasio"] > 0][:2]
    if not rasio:
        return None
    nilai = rasio[0] if len(rasio) == 1 else 0.6 * rasio[0] + 0.4 * rasio[1]
    return max(0.01, min(0.6, nilai))
