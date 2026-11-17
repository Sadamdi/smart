"""Mengukur waktu bagian-bagian jalur Beranda untuk satu pengguna (hanya baca, kecuali hitung ulang yang memang terjadi
saat hasil usang). Jalankan di server: python -m scripts.ukur_latensi email@contoh.id"""

import sys
import time
from datetime import date

from sqlalchemy import select, text

from app.db import sesi_baru
from app.models import Pengguna
from app.services import rekomendasi as rek


def waktu(label, fn):
    t = time.perf_counter()
    hasil = fn()
    print(f"{label}: {(time.perf_counter() - t) * 1000:.0f} ms")
    return hasil


def main(email: str) -> None:
    with sesi_baru() as sesi:
        waktu("ping basis data (select 1)", lambda: sesi.execute(text("select 1")).scalar())
        waktu("ping basis data lagi", lambda: sesi.execute(text("select 1")).scalar())
        p = sesi.scalar(select(Pengguna).where(Pengguna.email == email))
        if p is None:
            print("pengguna tidak ditemukan")
            return
        usang = waktu("cek usang", lambda: rek._usang(sesi, p))
        print("usang:", usang)
        waktu("daftar (ada cache)", lambda: rek.daftar(sesi, p, date.today(), "memenuhi", wilayah="dalam"))
        waktu("ringkasan", lambda: rek.ringkasan(sesi, p, date.today(), "dalam"))
        waktu("hitung ulang paksa", lambda: rek.hitung(sesi, p, date.today()))
        sesi.rollback()


if __name__ == "__main__":
    main(sys.argv[1])
