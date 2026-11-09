"""Memantau sumber otomatis sekarang. Tanpa argumen: hanya sumber yang belum pernah dipantau. Dengan --semua: semuanya.

Pemakaian (dari apps/backend): uv run python -m scripts.pantau_sekarang [--semua]
"""

import sys
from datetime import date

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Sumber
from app.services import pemantau_ai


def main() -> None:
    settings = get_settings()
    with Session(create_engine(settings.database_url)) as sesi:
        stmt = select(Sumber).where(Sumber.jenis == "pantau_otomatis", Sumber.aktif.is_(True))
        if "--semua" not in sys.argv:
            stmt = stmt.where(Sumber.status_terakhir == "belum_pernah")
        for s in list(sesi.scalars(stmt)):
            try:
                r = pemantau_ai.pantau_sumber(sesi, settings, s, date.today())
                s.status_terakhir = "berhasil"
            except Exception as exc:  # satu sumber gagal tidak menghentikan yang lain
                sesi.rollback()
                s = sesi.get(Sumber, s.id)
                s.status_terakhir = "gagal"
                r = f"gagal: {str(exc)[:80]}"
            sesi.commit()
            print(s.nama, r, flush=True)


if __name__ == "__main__":
    main()
