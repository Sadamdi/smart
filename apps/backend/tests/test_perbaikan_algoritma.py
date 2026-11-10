"""Perbaikan 10 November 2026: kewarganegaraan, toleransi IPK, pembaca CV, normalisasi nama dan penyelenggara."""

from datetime import date

import pytest

from app.rekomendasi.kelayakan import BELUM, HAMPIR, MEMENUHI, ProfilKelayakan, nilai_kelayakan
from app.services.dokumen import baca_dengan_aturan
from app.services.normalisasi import rapikan_nama, rapikan_penyelenggara

HARI = date(2026, 11, 10)


def _profil(**k) -> ProfilKelayakan:
    dasar = dict(jenjang="S1", semester=5, ipk=3.5, kewarganegaraan="Indonesia")
    dasar.update(k)
    return ProfilKelayakan(**dasar)


@pytest.mark.parametrize("warga", ["Indonesia", "WNI", "wni", "Warga Negara Indonesia", "warga negara indonesia (WNI)"])
@pytest.mark.parametrize(
    "syarat",
    [
        "Indonesia",
        "WNI",
        "Warga Negara Indonesia",
        "Warga Negara Indonesia (WNI)",
        "Warga negara dari daftar OECD-DAC (termasuk Indonesia)",
    ],
)
def test_kewarganegaraan_indonesia_seragam(warga, syarat):
    h = nilai_kelayakan([("kewarganegaraan", {"nilai": syarat})], _profil(kewarganegaraan=warga), HARI)
    assert h.kategori == MEMENUHI


@pytest.mark.parametrize(
    "syarat", ["international students", "Citizens of all countries (non-Turkish citizens)", "Semua negara"]
)
def test_syarat_terbuka_untuk_semua(syarat):
    assert nilai_kelayakan([("kewarganegaraan", {"nilai": syarat})], _profil(), HARI).kategori == MEMENUHI


def test_warga_asing_tidak_cocok_dan_negara_lain_tetap_dibedakan():
    assert nilai_kelayakan([("kewarganegaraan", {"nilai": "Turki"})], _profil(), HARI).kategori == BELUM
    asing = {"nilai": "Warga negara asing (bukan Indonesia)"}
    assert nilai_kelayakan([("kewarganegaraan", asing)], _profil(), HARI).kategori == BELUM
    daftar = {"nilai": "Indonesia, Brunei, Malaysia"}
    assert nilai_kelayakan([("kewarganegaraan", daftar)], _profil(kewarganegaraan="Malaysia"), HARI).kategori == MEMENUHI


def test_kewarganegaraan_kosong_meminta_pengisian():
    h = nilai_kelayakan([("kewarganegaraan", {"nilai": "Indonesia"})], _profil(kewarganegaraan=None), HARI)
    assert h.kategori == HAMPIR and any("kewarganegaraan" in c for c in h.catatan_kekurangan)


@pytest.mark.parametrize(
    ("ipk", "harapan"),
    [(3.9, MEMENUHI), (3.6, MEMENUHI), (3.5, HAMPIR), (3.4, HAMPIR), (3.2, BELUM), (2.0, BELUM)],
)
def test_ipk_mengubah_kategori_pada_beasiswa_dengan_syarat_ipk(ipk, harapan):
    syarat = [("jenjang", {"nilai": ["S1"]}), ("ipk_minimum", {"nilai": 3.6})]
    assert nilai_kelayakan(syarat, _profil(ipk=ipk), HARI).kategori == harapan


def test_semester_dan_bahasa_meleset_tipis_menjadi_hampir():
    sem = nilai_kelayakan([("semester_minimum", {"nilai": 5})], _profil(semester=4), HARI)
    assert sem.kategori == HAMPIR
    toefl = {"jenis": "toefl", "nilai": 500}
    dekat = nilai_kelayakan([("sertifikat_bahasa", toefl)], _profil(skor_bahasa={"toefl": 460}), HARI)
    assert dekat.kategori == HAMPIR
    jauh = nilai_kelayakan([("sertifikat_bahasa", toefl)], _profil(skor_bahasa={"toefl": 400}), HARI)
    assert jauh.kategori == BELUM


def test_tanpa_syarat_terukur_tidak_pernah_memenuhi():
    for syarat in ([], [("lainnya", {"teks": "bebas"})]):
        h = nilai_kelayakan(syarat, _profil(), HARI)
        assert h.kategori != MEMENUHI and h.alasan == []


@pytest.mark.parametrize(
    "teks",
    [
        "IPK: 3.45",
        "IPK 3,45",
        "GPA: 3.45/4.00",
        "IPK = 3,45 (skala 4)",
        "Indeks Prestasi Kumulatif 3.45",
        "indeks prestasi kumulatif: 3,45",
        "IPK kumulatif: 3.45",
    ],
)
def test_cv_ipk_berbagai_format(teks):
    assert baca_dengan_aturan(f"CV\n{teks}\n")["ipk"] == 3.45


def test_cv_tidak_mengira_ips_sebagai_ipk():
    assert "ipk" not in baca_dengan_aturan("Indeks Prestasi Semester 3.90")


@pytest.mark.parametrize(
    ("teks", "angka"),
    [
        ("Semester 5", 5),
        ("semester: 7", 7),
        ("Smt 4", 4),
        ("smt. 6", 6),
        ("Semester ke-3", 3),
        ("Mahasiswa semester 8", 8),
        ("Semester V", 5),
        ("Semester IV", 4),
        ("Smt VII", 7),
        ("semester xii", 12),
        ("Semester XIV", 14),
    ],
)
def test_cv_semester_berbagai_format(teks, angka):
    assert baca_dengan_aturan(f"Mahasiswa\n{teks}\n")["semester"] == angka


def test_cv_semester_tidak_salah_baca():
    for teks in ("semester ini cukup baik", "Semester 20", "Sempurna dalam semua mata kuliah"):
        assert "semester" not in baca_dengan_aturan(teks)


def test_cv_toefl_tetap_terbaca():
    assert baca_dengan_aturan("TOEFL ITP: 550")["skor_bahasa"]["toefl"] == 550


def test_rapikan_nama_membuang_awalan_promosi():
    assert rapikan_nama("[FULL Scholarship] Beasiswa S1 di Korea Selatan") == "Beasiswa S1 di Korea Selatan"
    assert rapikan_nama("[Dibuka] [Gratis]  Beasiswa   Unggulan ") == "Beasiswa Unggulan"
    assert rapikan_nama("Beasiswa Unggulan") == "Beasiswa Unggulan"
    assert rapikan_nama("[Promo] ab") == "[Promo] ab"  # hasil terlalu pendek: nama asli dipertahankan
    assert rapikan_nama(None) is None


def test_rapikan_penyelenggara_menyeragamkan_varian():
    for v in (
        "Australia Awards",
        "Australia Awards in Indonesia",
        "Australia Awards Indonesia",
        "australia awards  indonesia",
    ):
        assert rapikan_penyelenggara(v) == "Australia Awards"
    assert rapikan_penyelenggara("Türkiye Scholarships") == "Türkiye Scholarships"
    assert rapikan_penyelenggara("Pertamina Foundation ") == "Pertamina Foundation"
    assert rapikan_penyelenggara("  ") is None
    assert rapikan_penyelenggara(None) is None


def test_syarat_deskriptif_tidak_menyilang_wni_dan_domisili_indonesia():
    from datetime import date

    from app.rekomendasi.kelayakan import GAGAL, OK, TOLERAN, ProfilKelayakan, periksa_syarat

    p = ProfilKelayakan(kota_domisili="Malang", kewarganegaraan="Indonesia")
    h = date(2026, 11, 10)
    r = periksa_syarat("kewarganegaraan", {"nilai": "citizens from developing member countries of ADB"}, p, h)
    assert r.status == TOLERAN
    r = periksa_syarat("kewarganegaraan", {"nilai": "negara/teritori peserta yang terdaftar pada daftar dropdown"}, p, h)
    assert r.status == TOLERAN
    assert periksa_syarat("kewarganegaraan", {"nilai": "Canada (and Israel)"}, p, h).status == GAGAL
    assert periksa_syarat("kewarganegaraan", {"nilai": "Warga Negara Indonesia (WNI)"}, p, h).status == OK
    assert periksa_syarat("domisili", {"nilai": ["Indonesia"]}, p, h).status == OK
    assert periksa_syarat("domisili", {"nilai": ["Tidak berdomisili di Jerman lebih dari 15 bulan"]}, p, h).status == OK
    assert periksa_syarat("domisili", {"nilai": ["Kota Blitar"]}, p, h).status == GAGAL
    assert periksa_syarat("domisili", {"nilai": ["Kota Malang"]}, p, h).status == OK


def test_masalah_tautan_atau_jenjang():
    from app.services.pemantau_ai import masalah_tautan_atau_jenjang as m

    assert m("https://indbeasiswa.com/", "Beasiswa HKPFS S3") is not None
    assert m("https://indbeasiswa.com/beasiswa-hkpfs/", "Beasiswa HKPFS S3") is None
    assert m("https://www.lpdp.kemenkeu.go.id/", "Beasiswa LPDP") is None
    assert m("https://x.org/a", "Pendaftaran SMA Unggul Garuda") is not None
    assert m("https://x.org/a", "Beasiswa S1 untuk lulusan SMA") is None
    assert m("https://x.org/a", "Beasiswa JIS untuk pelajar kelas 8") is not None
