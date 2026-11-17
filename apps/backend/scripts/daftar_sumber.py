"""Daftar sumber pemantauan beserta status (hanya baca). Jalankan di server: python -m scripts.daftar_sumber"""

from sqlalchemy import select

from app.db import sesi_baru
from app.models import Sumber


def main() -> None:
    with sesi_baru() as sesi:
        for s in sesi.scalars(select(Sumber).order_by(Sumber.nama)):
            print(f"{'aktif' if s.aktif else 'mati ':5} {s.status_terakhir:12} {s.jenis:16} {s.nama[:46]:46} {s.url[:80]}")


if __name__ == "__main__":
    main()
