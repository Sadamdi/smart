"""Merapikan nama beasiswa dan penyelenggara agar tampilan seragam (aturan sama dipakai saat ingest dan skrip perapian)."""

import re

# Awalan promosi dalam kurung siku, misalnya "[FULL Scholarship]" atau "[Dibuka] ".
_AWALAN = re.compile(r"^\s*(?:\[[^\]]{1,60}\]\s*)+")
_SPASI = re.compile(r"\s+")

# Penyelenggara yang ditulis dengan banyak varian: (pola huruf kecil, nama baku).
_ALIAS_PENYELENGGARA = (
    (re.compile(r"^australia awards\b.*"), "Australia Awards"),
    (re.compile(r"^t[uü]rk[iıi]ye (burslar[ıi]|scholarships?)\b.*"), "Türkiye Scholarships"),
)


def rapikan_nama(nama: str | None) -> str | None:
    if not nama:
        return nama
    baru = _SPASI.sub(" ", _AWALAN.sub("", nama)).strip(" -|:;,")
    return baru if len(baru) >= 4 else nama.strip()


def rapikan_penyelenggara(nama: str | None) -> str | None:
    if not nama:
        return nama
    bersih = _SPASI.sub(" ", nama).strip(" -|:;,")
    if not bersih:
        return None
    for pola, baku in _ALIAS_PENYELENGGARA:
        if pola.match(bersih.lower()):
            return baku
    return bersih
