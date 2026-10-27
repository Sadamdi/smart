"""Mengosongkan semua tabel SMART. HANYA untuk basis data dev atau uji.

Menolak jalan kecuali APP_ENV bernilai dev atau test dan host DATABASE_URL ada di DESTRUCTIVE_DB_HOSTS
(app/core/safety.py). Jalankan eksplisit; jangan dipanggil dari skrip seed atau pengaturan uji.

Pemakaian: uv run python -m scripts.cleanup
"""

from sqlalchemy import create_engine, text

from app.core.config import get_settings
from app.core.safety import pastikan_boleh_hapus
from app.models import TABEL_SMART


def main() -> None:
    settings = get_settings()
    pastikan_boleh_hapus(settings)
    engine = create_engine(settings.database_url)
    with engine.begin() as koneksi:
        koneksi.execute(text("TRUNCATE " + ", ".join(TABEL_SMART) + " RESTART IDENTITY CASCADE"))
    print("Semua tabel SMART dikosongkan.")


if __name__ == "__main__":
    main()
