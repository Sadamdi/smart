from collections.abc import Iterator
from functools import lru_cache

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings
from app.core.errors import UpstreamUnavailable


@lru_cache
def _pabrik_sesi() -> sessionmaker[Session]:
    url = get_settings().database_url
    if not url:
        raise UpstreamUnavailable("DATABASE_URL belum diisi")
    # Beranda memanggil sekitar enam endpoint serentak; kolam kecil membuat permintaan mengantre sehingga lambat.
    mesin = create_engine(url, pool_pre_ping=True, pool_size=6, max_overflow=3, pool_recycle=300)
    return sessionmaker(mesin, expire_on_commit=False)


def hangatkan(jumlah: int = 4) -> None:
    """Membuka beberapa koneksi sekaligus saat proses mulai. Koneksi pertama ke basis data jarak jauh memakan beberapa detik;
    tanpa ini pengguna pertama setelah restart yang menanggungnya."""
    from concurrent.futures import ThreadPoolExecutor

    from sqlalchemy import text

    def satu(_):
        with _pabrik_sesi()() as sesi:
            sesi.execute(text("select 1"))

    with ThreadPoolExecutor(max_workers=jumlah) as ex:
        list(ex.map(satu, range(jumlah)))


def sesi_baru() -> Session:
    """Sesi di luar siklus permintaan (penjadwal). Penutupan menjadi tanggung jawab pemanggil."""
    return _pabrik_sesi()()


def get_session() -> Iterator[Session]:
    with _pabrik_sesi()() as sesi:
        yield sesi
