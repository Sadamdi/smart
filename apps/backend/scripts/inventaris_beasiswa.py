"""Daftar beasiswa di basis data menurut status, negara, dan penyelenggara (hanya baca). Dipakai untuk riset data seleksi.

Jalankan di server: python -m scripts.inventaris_beasiswa
"""

import json
from collections import Counter

from sqlalchemy import select

from app.db import sesi_baru
from app.models import Beasiswa


def main() -> None:
    with sesi_baru() as sesi:
        baris = sesi.execute(select(Beasiswa.status, Beasiswa.nama, Beasiswa.penyelenggara, Beasiswa.negara, Beasiswa.jenjang)).all()
    status = Counter(b[0] for b in baris)
    terbit = [b for b in baris if b[0] == "terbit"]
    penyelenggara = Counter((b[2] or "?").strip() for b in terbit)
    luar = Counter((b[3] or "Indonesia") for b in terbit)
    print(json.dumps({"status": status, "negara_terbit": luar, "total": len(baris)}, ensure_ascii=False))
    print("PENYELENGGARA_TERBIT")
    for nama, n in penyelenggara.most_common():
        print(f"{n}\t{nama}")
    print("NAMA_TERBIT")
    for b in terbit:
        print(f"{b[1]}\t{b[2]}\t{b[3]}\t{','.join(b[4] or [])}")


if __name__ == "__main__":
    main()
