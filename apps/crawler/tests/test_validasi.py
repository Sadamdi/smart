from datetime import date

from smart_crawler.validasi import tentukan_status

H = date(2026, 11, 2)


def test_tanpa_tenggat_menunggu_validasi():
    assert tentukan_status(None, H, "https://x")[0] == "menunggu_validasi"


def test_tenggat_lewat_kedaluwarsa():
    assert tentukan_status(date(2026, 11, 1), H, "https://x")[0] == "kedaluwarsa"


def test_tenggat_kurang_tiga_hari_tidak_terbit():
    assert tentukan_status(date(2026, 11, 4), H, "https://x")[0] == "menunggu_validasi"


def test_tenggat_tiga_hari_atau_lebih_terbit():
    assert tentukan_status(date(2026, 11, 5), H, "https://x") == ("terbit", None)


def test_tanpa_tautan_tidak_terbit():
    assert tentukan_status(date(2026, 12, 1), H, None)[0] == "menunggu_validasi"
