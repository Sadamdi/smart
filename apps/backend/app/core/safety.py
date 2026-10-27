"""Pengaman operasi yang menghapus data.

Basis data berada di layanan awan (Supabase), bukan localhost, sehingga pemeriksaan host saja
tidak cukup. Uji dan skrip yang menghapus data hanya boleh jalan bila lingkungan dev atau test
dan host basis data ada di daftar putih eksplisit. Host produksi tidak pernah masuk daftar itu.
"""

from urllib.parse import urlparse

from app.core.config import Settings


class DestructiveOperationRefused(RuntimeError):
    pass


def host_dari_url(database_url: str) -> str:
    return (urlparse(database_url).hostname or "").lower()


def pastikan_boleh_hapus(settings: Settings) -> None:
    """Melempar DestructiveOperationRefused bila operasi penghapusan tidak aman."""
    if settings.app_env == "prod":
        raise DestructiveOperationRefused("APP_ENV=prod: operasi yang menghapus data ditolak.")
    if not settings.database_url:
        raise DestructiveOperationRefused("DATABASE_URL belum diisi.")
    host = host_dari_url(settings.database_url)
    daftar_putih = {h.lower() for h in settings.destructive_db_hosts}
    if not daftar_putih:
        raise DestructiveOperationRefused(
            "DESTRUCTIVE_DB_HOSTS kosong: tidak ada host yang boleh dihapus isinya."
        )
    if host not in daftar_putih:
        raise DestructiveOperationRefused(
            f"Host basis data '{host}' tidak ada di DESTRUCTIVE_DB_HOSTS. Operasi dihentikan."
        )
