from pathlib import Path

from smart_crawler.uinmalang import ekstrak, sidik, tebak_jenjang

HTML = (Path(__file__).parent / "fixtures" / "uinmalang_informasi_beasiswa.html").read_text(encoding="utf-8")


def test_mengambil_seluruh_program_dari_tabel_timeline():
    baris = ekstrak(HTML)
    assert len(baris) == 36
    assert baris[0].nama == "Program KIP Kuliah (Mahasiswa Baru)"
    assert baris[0].pelaksanaan == "Agustus - September"
    assert baris[0].tautan.startswith("https://")


def test_nama_tidak_kosong_dan_sidik_unik():
    baris = ekstrak(HTML)
    assert all(b.nama for b in baris)
    assert len({sidik(b) for b in baris}) == len(baris)


def test_html_tanpa_tabel_beasiswa_menghasilkan_daftar_kosong():
    assert ekstrak("<html><body><table><tr><td>a</td></tr></table></body></html>") == []


def test_tebak_jenjang():
    assert tebak_jenjang("Mahasiswa aktif Program S1 (Non-Vokasi)") == ["S1"]
    assert "S2" in tebak_jenjang("Mahasiswa pascasarjana S2 dan S3")
