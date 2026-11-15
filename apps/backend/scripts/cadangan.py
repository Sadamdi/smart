"""Cadangan harian seluruh tabel basis data ke berkas JSON terkompresi, dengan pemangkasan otomatis.

Berkas: <tujuan>/cadangan-YYYYMMDD-HHMM.json.gz. Kolom vektor dan biner dilewati (dapat dibangun ulang dari teks).
Kata sandi dan token ikut tersimpan dalam bentuk hash/terenkripsi seperti di basis data, jadi izin berkas dibatasi 600.

Pemakaian (dari apps/backend):
    python -m scripts.cadangan [--tujuan /opt/smart/cadangan] [--simpan 14]
Dijadwalkan lewat cron: lihat apps/docs/CADANGAN.md.
"""

import argparse
import gzip
import json
import os
from datetime import date, datetime, time
from decimal import Decimal
from uuid import UUID

from sqlalchemy import MetaData, create_engine, select

from app.core.config import get_settings


def _nilai(v):
    if isinstance(v, (datetime, date, time)):
        return v.isoformat()
    if isinstance(v, (UUID, Decimal)):
        return str(v)
    if isinstance(v, (bytes, memoryview)):
        return None
    return v


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tujuan", default="/opt/smart/cadangan")
    ap.add_argument("--simpan", type=int, default=14)
    a = ap.parse_args()
    os.makedirs(a.tujuan, mode=0o700, exist_ok=True)
    mesin = create_engine(get_settings().database_url)
    meta = MetaData()
    meta.reflect(bind=mesin)
    hasil: dict[str, list] = {}
    with mesin.connect() as c:
        for nama, t in meta.tables.items():
            kolom = [k for k in t.columns if "vector" not in str(k.type).lower()]
            baris = c.execute(select(*kolom)).mappings().all()
            hasil[nama] = [{k: _nilai(v) for k, v in b.items()} for b in baris]
    jalur = os.path.join(a.tujuan, datetime.now().strftime("cadangan-%Y%m%d-%H%M.json.gz"))
    with gzip.open(jalur, "wt", encoding="utf-8") as f:
        json.dump(hasil, f, ensure_ascii=False, default=str)
    os.chmod(jalur, 0o600)
    lama = sorted(x for x in os.listdir(a.tujuan) if x.startswith("cadangan-"))[: -a.simpan]
    for x in lama:
        os.remove(os.path.join(a.tujuan, x))
    print(jalur, sum(len(v) for v in hasil.values()), "baris", len(hasil), "tabel", "dihapus", len(lama))


if __name__ == "__main__":
    main()
