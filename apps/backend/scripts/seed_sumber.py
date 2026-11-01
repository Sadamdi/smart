"""Mengisi tabel sumber dengan sembilan laman awal. Aman diulang (upsert berdasarkan url, tidak menghapus apa pun).

Pemakaian (dari apps/backend, dengan DATABASE_URL di .env):
    uv run python -m scripts.seed_sumber
"""

from sqlalchemy import create_engine
from sqlalchemy.dialects.postgresql import insert

from app.core.config import get_settings
from app.models import Sumber

# (nama, url, jenis, negara, jadwal cron atau None, aktif). Metode per sumber: Dokument/01-Arsitektur/04-PEMANTAUAN-SUMBER.md
SUMBER_AWAL = [
    (
        "SatuBeasiswa Kemdiktisaintek",
        "https://satubeasiswa.kemdiktisaintek.go.id/beasiswa",
        "pantau_otomatis",
        "Indonesia",
        None,
        False,
    ),
    ("Luarkampus.id", "https://luarkampus.id/beasiswa", "tautan_keluar", "Indonesia", None, True),
    (
        "Beasiswa Unggulan Kemendikdasmen",
        "https://beasiswaunggulan.kemendikdasmen.go.id",
        "tautan_keluar",
        "Indonesia",
        None,
        True,
    ),
    (
        "Informasi beasiswa Kemahasiswaan UIN Malang",
        "https://kemahasiswaan.uin-malang.ac.id/informasi-beasiswa",
        "pantau_otomatis",
        "Indonesia",
        "0 6 * * *",
        True,
    ),
    ("Djarum Beasiswa Plus", "https://djarumbeasiswaplus.org/home", "input_manual", "Indonesia", None, True),
    (
        "Beasiswa LPDP Terintegrasi",
        "https://beasiswalpdp-terintegrasi.kemenkeu.go.id",
        "tautan_keluar",
        "Indonesia",
        None,
        True,
    ),
    ("BSI Scholarship", "https://bsischolarship.id", "tautan_keluar", "Indonesia", None, True),
    ("Beasiswa Komdigi", "https://beasiswa.komdigi.go.id", "rujukan", "Indonesia", None, True),
    (
        "Scholarpedia (Kobi Education)",
        "https://scholarpedia.kobieducation.com/scholarship",
        "rujukan",
        "Indonesia",
        None,
        True,
    ),
]


def main() -> None:
    url = get_settings().database_url
    if not url:
        raise SystemExit("DATABASE_URL belum diisi.")
    engine = create_engine(url)
    nilai = [
        {"nama": n, "url": u, "jenis": j, "negara": ng, "jadwal": jd, "aktif": a}
        for n, u, j, ng, jd, a in SUMBER_AWAL
    ]
    stmt = insert(Sumber).values(nilai)
    stmt = stmt.on_conflict_do_update(
        index_elements=[Sumber.url],
        set_={"nama": stmt.excluded.nama, "jenis": stmt.excluded.jenis, "negara": stmt.excluded.negara},
    )
    with engine.begin() as koneksi:
        koneksi.execute(stmt)
    print(f"{len(nilai)} sumber diperiksa atau diisi.")


if __name__ == "__main__":
    main()
