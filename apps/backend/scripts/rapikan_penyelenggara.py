"""Menyeragamkan penulisan penyelenggara yang sama. Pemakaian: uv run python -m scripts.rapikan_penyelenggara [--terapkan]
Tanpa --terapkan hanya menampilkan perubahan dan menyimpan nilai lama ke rapikan_penyelenggara_lama.json."""

import json
import sys

from sqlalchemy import create_engine, text

from app.core.config import get_settings

PETA = {
    "Kementerian Agama RI": "Kementerian Agama Republik Indonesia",
    "Lembaga Pengelola Dana Pendidikan (LPDP)": "LPDP",
    "Badan Amil Zakat (BAZNAS)": "BAZNAS",
    "BAZNAS RI": "BAZNAS",
    "The Asia Foundation": "Asia Foundation",
    "Satu Beasiswa Indonesia / Kementerian Pendidikan Tinggi, Sains, dan Teknologi": "Satu Beasiswa Indonesia",
    "STMIK Kuwera (School of Technopreneur Nusantara / SOTN)": "STMIK Kuwera",
}


def main() -> None:
    terapkan = "--terapkan" in sys.argv
    mesin = create_engine(get_settings().database_url)
    with mesin.begin() as c:
        lama = []
        for dari, ke in PETA.items():
            ids = [r[0] for r in c.execute(text("select id::text from beasiswa where penyelenggara = :d"), {"d": dari})]
            for i in ids:
                lama.append({"id": i, "penyelenggara": dari})
            print(f"{len(ids)} baris: {dari!r} -> {ke!r}")
            if terapkan and ids:
                c.execute(text("update beasiswa set penyelenggara = :k where penyelenggara = :d"), {"k": ke, "d": dari})
        with open("rapikan_penyelenggara_lama.json", "w", encoding="utf8") as f:
            json.dump(lama, f, ensure_ascii=False, indent=1)
    print("diterapkan" if terapkan else "pratinjau saja (tambahkan --terapkan)")


if __name__ == "__main__":
    main()
