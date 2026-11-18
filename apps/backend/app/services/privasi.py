"""Penyamaran data pribadi sebelum teks dokumen dikirim ke layanan AI eksternal.

Yang disamarkan: surel, nomor telepon, NIM atau nomor identitas 12 digit ke atas, dan kata-kata nama pengguna.
Isi dokumen yang relevan untuk analisis (pendidikan, organisasi, prestasi, keahlian) tetap utuh.
"""

import re

_SUREL = re.compile(r"[\w.+-]+@[\w-]+(?:\.[\w-]+)+")
_TELEPON = re.compile(r"(?:\+62|62|0)[\s-]?8\d{1,3}[\s-]?\d{3,4}[\s-]?\d{2,5}")
_IDENTITAS = re.compile(r"\b\d{12,18}\b")


def samarkan(teks: str, nama: str | None = None) -> str:
    teks = _SUREL.sub("[surel]", teks)
    teks = _TELEPON.sub("[telepon]", teks)
    teks = _IDENTITAS.sub("[nomor identitas]", teks)
    for kata in {k for k in re.split(r"\s+", nama or "") if len(k) >= 3}:
        teks = re.sub(rf"\b{re.escape(kata)}\b", "[nama]", teks, flags=re.IGNORECASE)
    return teks
