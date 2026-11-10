"""Menyeragamkan nama beasiswa dan penyelenggara yang sudah tersimpan (aturan sama dengan ingest).

Aturan: awalan promosi dalam kurung siku dibuang dari nama; varian penyelenggara yang sama
(mis. "Australia Awards in Indonesia") disatukan. Kolom sidik_isi tidak diubah sehingga pemantauan
berikutnya tidak membuat duplikat.

Pemakaian (dari apps/backend):
  uv run python -m scripts.normalisasi_nama --dry-run   # hanya menampilkan rencana perubahan
  uv run python -m scripts.normalisasi_nama             # menerapkan perubahan

Skrip ini mengubah basis data yang ditunjuk DATABASE_URL. Jalankan --dry-run lebih dulu dan cadangkan data.
"""

import argparse

from sqlalchemy import select

from app.db import sesi_baru
from app.models import Beasiswa
from app.services.normalisasi import rapikan_nama, rapikan_penyelenggara


def rencana(baris: list[Beasiswa]) -> list[tuple[Beasiswa, str | None, str | None]]:
    hasil = []
    for b in baris:
        nama = rapikan_nama(b.nama)
        penyelenggara = rapikan_penyelenggara(b.penyelenggara)
        if nama != b.nama or penyelenggara != b.penyelenggara:
            hasil.append((b, nama, penyelenggara))
    return hasil


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dry-run", action="store_true", help="tampilkan rencana tanpa mengubah data")
    args = ap.parse_args(argv)
    with sesi_baru() as sesi:
        perubahan = rencana(list(sesi.scalars(select(Beasiswa))))
        for b, nama, penyelenggara in perubahan:
            if nama != b.nama:
                print(f"nama          : {b.nama!r} -> {nama!r}")
            if penyelenggara != b.penyelenggara:
                print(f"penyelenggara : {b.penyelenggara!r} -> {penyelenggara!r}")
        print(f"{len(perubahan)} beasiswa akan diubah" if args.dry_run else f"{len(perubahan)} beasiswa diubah")
        if args.dry_run:
            return 0
        for b, nama, penyelenggara in perubahan:
            b.nama = nama or b.nama
            b.penyelenggara = penyelenggara
        sesi.commit()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
