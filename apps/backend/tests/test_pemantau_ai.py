"""Uji validasi AI dan pemantau: penjaga laman, verifikasi kutipan, aturan terbit, sekali per beasiswa, saklar admin."""

import uuid
from datetime import date, timedelta

import pytest
from sqlalchemy import func, update

from app.core.config import Settings, get_settings
from app.core.errors import UpstreamUnavailable
from app.models import Beasiswa, Persyaratan, Sumber
from app.services import laman, llm, pemantau_ai
from tests.test_integrasi_db import sesi  # noqa: F401 (fixture)

HARI = date(2026, 11, 4)
S = Settings(ai_base_url="http://x", ai_api_key="k", ai_model="auto")
LAMAN = (
    "Beasiswa Contoh Unggul dari Yayasan Contoh. Pendaftaran ditutup 30 November 2026. "
    "Syarat: IPK minimal 3,25 dan mahasiswa S1. Berkas: transkrip nilai dan KTP. " * 2
)


def test_penjaga_menolak_alamat_internal_dan_skema_aneh():
    for url in ("http://127.0.0.1/x", "http://localhost/", "file:///etc/passwd", "ftp://contoh.id"):
        with pytest.raises(laman.LamanGagal):
            laman.periksa_alamat(url)


def test_html_ke_teks_membuang_skrip_dan_menjaga_tautan():
    t = laman.html_ke_teks('<script>alert(1)</script><p>Halo <a href="/daftar">Daftar</a></p>', "https://a.id/x")
    assert "alert" not in t and "Daftar [https://a.id/daftar]" in t


def test_kutipan_harus_ada_di_laman():
    assert pemantau_ai.ada_kutipan("ditutup 30 November 2026", LAMAN)
    assert not pemantau_ai.ada_kutipan("ditutup 1 Januari 2027", LAMAN)
    assert pemantau_ai.tenggat_terverifikasi("2026-11-30", "ditutup 30 November 2026", LAMAN) == date(2026, 11, 30)
    assert (
        pemantau_ai.tenggat_terverifikasi("2026-12-01", "ditutup 30 November 2026", LAMAN) is None
    )  # tanggal tak cocok kutipan
    assert pemantau_ai.tenggat_terverifikasi("2026-11-30", "kutipan karangan", LAMAN) is None


def test_syarat_valid_menolak_bentuk_salah_dan_kutipan_palsu():
    ok = pemantau_ai.syarat_valid({"jenis": "ipk_minimum", "nilai": "3,25", "kutipan": "IPK minimal 3,25"}, LAMAN)
    assert ok == ("ipk_minimum", {"nilai": 3.25})
    assert pemantau_ai.syarat_valid({"jenis": "ipk_minimum", "nilai": 9, "kutipan": "IPK minimal 3,25"}, LAMAN) is None
    assert pemantau_ai.syarat_valid({"jenis": "ipk_minimum", "nilai": 3, "kutipan": "tidak ada di laman"}, LAMAN) is None
    assert pemantau_ai.syarat_valid({"jenis": "jenjang", "nilai": ["S1", "X9"], "kutipan": "mahasiswa S1"}, LAMAN) == (
        "jenjang",
        {"nilai": ["S1"]},
    )


def _jawab(tenggat="2026-11-30", kutipan="ditutup 30 November 2026"):
    import json

    return json.dumps(
        {
            "ini_beasiswa": True,
            "penyelenggara": "Yayasan Contoh",
            "jenjang": ["S1"],
            "tenggat": tenggat,
            "kutipan_tenggat": kutipan,
            "persyaratan": [{"jenis": "ipk_minimum", "nilai": 3.25, "kutipan": "IPK minimal 3,25"}],
            "berkas": ["Transkrip nilai", "KTP"],
        }
    )


def _beasiswa(sesi, status="menunggu_validasi"):  # noqa: F811
    s = Sumber(nama="Uji " + uuid.uuid4().hex[:6], url="https://uji.example/" + uuid.uuid4().hex, jenis="pantau_otomatis")
    sesi.add(s)
    sesi.flush()
    b = Beasiswa(sumber_id=s.id, nama="Beasiswa Contoh Unggul", tautan_resmi="https://uji.example/b", status=status)
    sesi.add(b)
    sesi.flush()
    return b


pytestmark_db = pytest.mark.skipif(not get_settings().database_url or get_settings().app_env == "prod", reason="butuh DB")


@pytestmark_db
def test_validasi_menerbitkan_bila_semua_terverifikasi(sesi, monkeypatch):  # noqa: F811
    monkeypatch.setattr(llm, "tanya", lambda *a, **k: _jawab())
    b = _beasiswa(sesi)
    assert pemantau_ai.validasi_beasiswa(sesi, S, b, HARI, teks=LAMAN) == "terbit"
    assert b.status == "terbit" and b.tenggat == date(2026, 11, 30) and b.divalidasi_ai_pada is not None
    jenis = {p.jenis for p in sesi.query(Persyaratan).filter_by(beasiswa_id=b.id)}
    assert {"ipk_minimum", "jenjang"} <= jenis  # jenjang beasiswa otomatis menjadi syarat terukur


@pytestmark_db
def test_tenggat_karangan_tidak_dipercaya_terbit_tanpa_tenggat(sesi, monkeypatch):  # noqa: F811
    monkeypatch.setattr(llm, "tanya", lambda *a, **k: _jawab(kutipan="kutipan yang tidak ada"))
    b = _beasiswa(sesi)
    assert pemantau_ai.validasi_beasiswa(sesi, S, b, HARI, teks=LAMAN) == "terbit"
    assert b.status == "terbit" and b.tenggat is None  # tenggat karangan AI tidak pernah dipakai


@pytestmark_db
def test_tenggat_terlalu_dekat_tetap_menunggu(sesi, monkeypatch):  # noqa: F811
    monkeypatch.setattr(llm, "tanya", lambda *a, **k: _jawab("2026-11-05", "ditutup 5 November 2026"))
    b = _beasiswa(sesi)
    teks = LAMAN + " ditutup 5 November 2026"
    assert pemantau_ai.validasi_beasiswa(sesi, S, b, HARI, teks=teks) == "menunggu"
    assert "tiga hari" in b.alasan_ditandai.lower() or "3 hari" in b.alasan_ditandai


@pytestmark_db
def test_sekali_saja_dan_layanan_mati_tidak_menandai(sesi, monkeypatch):  # noqa: F811
    panggilan = []
    monkeypatch.setattr(llm, "tanya", lambda *a, **k: panggilan.append(1) or _jawab())
    monkeypatch.setattr(laman, "ambil_teks", lambda url, klien=None, maks=0: LAMAN)
    sesi.execute(
        update(Beasiswa).values(divalidasi_ai_pada=func.now())
    )  # abaikan antrean nyata; hanya data uji yang diperiksa
    sesi.flush()
    b = _beasiswa(sesi)
    pemantau_ai.validasi_antrean(sesi, S, HARI, batas=50)
    assert b.divalidasi_ai_pada is not None
    n = len(panggilan)
    pemantau_ai.validasi_antrean(sesi, S, HARI, batas=50)
    assert len(panggilan) == n  # beasiswa yang sama tidak diproses ulang

    def mati(*a, **k):
        raise UpstreamUnavailable("mati")

    monkeypatch.setattr(llm, "tanya", mati)
    b2 = _beasiswa(sesi)
    r = pemantau_ai.validasi_antrean(sesi, S, HARI + timedelta(days=0), batas=50)
    assert r["layanan_ai_mati"] == 1 and b2.divalidasi_ai_pada is None


@pytestmark_db
def test_saklar_default_aktif_dan_bisa_dimatikan(sesi):  # noqa: F811
    assert pemantau_ai.auto_validasi_aktif(sesi) is True
    pemantau_ai.atur_auto_validasi(sesi, False)
    assert pemantau_ai.auto_validasi_aktif(sesi) is False


def test_bagi_teks_memotong_pada_batas_baris_dan_membatasi_jumlah():
    teks = "\n".join(f"baris {i} " + "x" * 50 for i in range(100))
    bagian = pemantau_ai.bagi_teks(teks, ukuran=500, maks=3)
    assert len(bagian) == 3 and all(len(b) <= 560 for b in bagian)
    assert pemantau_ai.bagi_teks("", 500, 3) == []


def test_tautan_media_sosial_tidak_dipakai_sebagai_tautan_resmi():
    assert pemantau_ai._media_sosial("https://www.instagram.com/indbeasiswa/")
    assert pemantau_ai._media_sosial("http://t.me/indbeasiswa")
    assert not pemantau_ai._media_sosial("https://www.tanotofoundation.org/id/")


def test_kunci_alamat_menyamakan_alamat_panjang_dan_pendek():
    panjang = "https://satubeasiswa.example/beasiswa/beasiswa-bermitra-84gp"
    pendek = "https://satubeasiswa.example/beasiswa/84gp"
    assert pemantau_ai._kunci_alamat(panjang) == pemantau_ai._kunci_alamat(pendek) == "84gp"
    assert pemantau_ai._nama_dari_slug(panjang) == "Beasiswa Bermitra"


@pytestmark_db
def test_pantau_sitemap_mendaftarkan_alamat_baru_saja(sesi, monkeypatch):  # noqa: F811
    xml = (
        "<urlset><url><loc>https://uji-sitemap.example/beasiswa/beasiswa-alfa-ab12</loc></url>"
        "<url><loc>https://uji-sitemap.example/beasiswa/beasiswa-beta-cd34</loc></url>"
        "<url><loc>https://uji-sitemap.example/tentang</loc></url>"
        "<url><loc>https://lain.example/beasiswa/x-ef56</loc></url></urlset>"
    )
    monkeypatch.setattr(laman, "ambil_mentah", lambda url, klien=None: xml)
    s = Sumber(nama="Sitemap uji", url="https://uji-sitemap.example/sitemap.xml", jenis="pantau_otomatis")
    sesi.add(s)
    sesi.flush()
    sesi.add(
        Beasiswa(sumber_id=s.id, nama="Sudah Ada", tautan_resmi="https://uji-sitemap.example/beasiswa/ab12", status="terbit")
    )
    sesi.flush()
    r = pemantau_ai.pantau_sumber(sesi, S, s, HARI)
    assert r == {"ditemukan": 2, "baru": 1}  # alfa sudah ada (kunci ab12); hanya beta baru
    baru = sesi.query(Beasiswa).filter_by(sumber_id=s.id, status="menunggu_validasi").one()
    assert baru.nama == "Beasiswa Beta" and baru.alasan_ditandai.startswith("Dari peta situs")


@pytestmark_db
def test_beasiswa_terbit_tanpa_tenggat_terlihat_di_daftar_dan_rekomendasi(sesi, monkeypatch):  # noqa: F811
    from app.repositories.beasiswa import BeasiswaRepoSql, FilterBeasiswa
    from app.services import rekomendasi as layanan

    monkeypatch.setattr(llm, "tanya", lambda *a, **k: _jawab(tenggat=None, kutipan=None))
    b = _beasiswa(sesi)
    b.nama = "Beasiswa Tanpa Tenggat Uji " + uuid.uuid4().hex[:6]
    assert pemantau_ai.validasi_beasiswa(sesi, S, b, HARI, teks=LAMAN) == "terbit"
    assert b.status == "terbit" and b.tenggat is None
    halaman = BeasiswaRepoSql(sesi).daftar(FilterBeasiswa(q=b.nama), None, 10, HARI)
    assert [x.id for x in halaman.item] == [b.id]
    assert BeasiswaRepoSql(sesi).detail(b.id, HARI) is not None
    assert b.id in {m.id for m in layanan._masukan(sesi, HARI)}
