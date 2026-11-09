"""Menjalankan validasi AI untuk seluruh beasiswa yang menunggu (membuka ulang yang pernah gagal sementara).

Pemakaian (dari apps/backend): uv run python -m scripts.validasi_semua [--ulang]
--ulang membuka kembali beasiswa menunggu yang alasannya bukan penolakan tetap (tenggat kosong, laman gagal dibuka).
"""

import sys
from datetime import date

from sqlalchemy import create_engine, select, update
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Beasiswa
from app.services import pemantau_ai

ULANG = (
    "tenggat tidak tertulis",
    "tidak dapat dibuka",
    "bukan JSON",
    "terlalu sedikit",
    "Tenggat paling cepat",
    "status 403",
)


def main() -> None:
    settings = get_settings()
    with Session(create_engine(settings.database_url)) as sesi:
        if "--ulang" in sys.argv:
            buka = [
                b.id
                for b in sesi.scalars(select(Beasiswa).where(Beasiswa.status == "menunggu_validasi"))
                if any(k in (b.alasan_ditandai or "") for k in ULANG)
            ]
            if buka:
                sesi.execute(update(Beasiswa).where(Beasiswa.id.in_(buka)).values(divalidasi_ai_pada=None))
                sesi.commit()
            print("dibuka ulang:", len(buka), flush=True)
        total = {"diproses": 0, "terbit": 0, "kedaluwarsa": 0, "menunggu": 0}
        while True:
            r = pemantau_ai.validasi_antrean(sesi, settings, date.today(), batas=10)
            if r["layanan_ai_mati"]:
                print("layanan AI mati, berhenti", flush=True)
                break
            if not r["diproses"]:
                break
            for k in total:
                total[k] += r[k]
            print(total, flush=True)


if __name__ == "__main__":
    main()
