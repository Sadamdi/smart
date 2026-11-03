"""Mengisi syarat jenjang dari kolom jenjang pada beasiswa yang belum punya syarat jenjang. Aman diulang.

Pemakaian (dari apps/backend): uv run python -m scripts.isi_syarat_jenjang
"""

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Beasiswa, Persyaratan


def main() -> None:
    url = get_settings().database_url
    if not url:
        raise SystemExit("DATABASE_URL belum diisi")
    baru = 0
    with Session(create_engine(url)) as sesi:
        for b in sesi.scalars(select(Beasiswa).where(Beasiswa.jenjang.is_not(None))):
            ada = sesi.scalar(select(Persyaratan.id).where(Persyaratan.beasiswa_id == b.id, Persyaratan.jenis == "jenjang"))
            if ada is None and b.jenjang:
                sesi.add(
                    Persyaratan(
                        beasiswa_id=b.id, jenis="jenjang", nilai_batas={"nilai": list(b.jenjang)}, dapat_dikejar=False
                    )
                )
                baru += 1
        sesi.commit()
    print(f"{baru} syarat jenjang ditambahkan.")


if __name__ == "__main__":
    main()
