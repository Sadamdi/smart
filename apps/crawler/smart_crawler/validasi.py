"""Aturan terbit: hanya beasiswa dengan tenggat paling cepat tiga hari ke depan yang diterbitkan."""

from datetime import date, timedelta

HARI_MINIMAL = 3


def tentukan_status(tenggat: date | None, hari_ini: date, tautan: str | None) -> tuple[str, str | None]:
    """Mengembalikan (status, alasan_ditandai). Data yang ambigu tidak ditebak: menunggu validasi."""
    if not tautan:
        return "menunggu_validasi", "Tautan resmi belum ada"
    if tenggat is None:
        return "menunggu_validasi", "Tenggat belum diketahui"
    if tenggat < hari_ini:
        return "kedaluwarsa", None
    if tenggat < hari_ini + timedelta(days=HARI_MINIMAL):
        return "menunggu_validasi", "Tenggat kurang dari tiga hari"
    return "terbit", None
