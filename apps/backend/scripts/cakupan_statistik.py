"""Seberapa banyak beasiswa terbit yang punya data seleksi terdokumentasi, dan tingkat persaingan sisanya (hanya baca).

Jalankan di server: python -m scripts.cakupan_statistik
"""

from collections import Counter

from sqlalchemy import select

from app.db import sesi_baru
from app.models import Beasiswa
from app.rekomendasi import statistik
from app.rekomendasi.peluang import tingkat_persaingan
from app.services.kartu import luar_negeri


def main() -> None:
    with sesi_baru() as sesi:
        daftar = sesi.scalars(select(Beasiswa).where(Beasiswa.status == "terbit")).all()
    dengan_rasio, dengan_info, tanpa = [], [], []
    tingkat = Counter()
    for b in daftar:
        entri = statistik.cari(b.nama, b.penyelenggara, b.jenjang)
        if statistik.rasio_terbaru(entri) is not None:
            dengan_rasio.append(b)
        elif entri:
            dengan_info.append(b)
        else:
            tanpa.append(b)
            tingkat[tingkat_persaingan(b.nama, b.penyelenggara, luar_negeri(b.negara))] += 1
    print(f"Terbit: {len(daftar)}")
    print(f"Rasio terdokumentasi: {len(dengan_rasio)}")
    print(f"Hanya kuota atau jumlah penerima (tanpa rasio): {len(dengan_info)}")
    print(f"Tanpa data program, memakai tingkat persaingan: {len(tanpa)} {dict(tingkat)}")
    print("--- rasio terdokumentasi")
    for b in dengan_rasio:
        print(f"  {b.nama[:70]} | {b.penyelenggara}")
    print("--- hanya kuota atau penerima")
    for b in dengan_info:
        print(f"  {b.nama[:70]} | {b.penyelenggara}")


if __name__ == "__main__":
    main()
