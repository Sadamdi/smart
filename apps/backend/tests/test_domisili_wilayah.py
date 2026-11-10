"""Uji domisili terstruktur: negara, provinsi, kota; normalisasi nama; endpoint referensi dan validasi profil."""

from datetime import date

import pytest

from app.rekomendasi.kelayakan import GAGAL, OK, TIDAK_DIKETAHUI, ProfilKelayakan, periksa_syarat
from app.rekomendasi.wilayah import PROVINSI_INDONESIA, negara_kanonik, provinsi_kanonik
from tests.conftest import daftarkan, kepala

B = "/api/v1"
H = date(2026, 11, 10)

MALANG = dict(
    negara_domisili="Indonesia", provinsi_domisili="Jawa Timur", kota_domisili="Malang", kewarganegaraan="Indonesia"
)
KUPANG = dict(negara_domisili="Indonesia", provinsi_domisili="Nusa Tenggara Timur", kota_domisili="Kupang")
JAYAPURA = dict(negara_domisili="Indonesia", provinsi_domisili="Papua", kota_domisili="Jayapura")
KL = dict(negara_domisili="Malaysia", kota_domisili="Kuala Lumpur", kewarganegaraan="Indonesia")


def status(syarat, **profil):
    return periksa_syarat(
        "domisili", {"nilai": syarat if isinstance(syarat, list) else [syarat]}, ProfilKelayakan(**profil), H
    )


@pytest.mark.parametrize(
    "syarat",
    [
        "Indonesia",
        "Jawa Timur",
        "Jatim",
        "jawa timur",
        "Provinsi Jawa Timur",
        "Kota Malang",
        "Kabupaten Malang",
        "Malang",
        "Kab. Malang",
    ],
)
def test_malang_cocok_semua_tingkat(syarat):
    assert status(syarat, **MALANG).status == OK


@pytest.mark.parametrize(
    "syarat", ["Kota Blitar", "Jawa Tengah", "Papua", "Canada", "Singapore", "Jepang", "Kota Surabaya", "DKI Jakarta"]
)
def test_malang_tidak_cocok_wilayah_lain(syarat):
    assert status(syarat, **MALANG).status == GAGAL


def test_majemuk_cocok_salah_satu():
    assert status("Jawa Timur dan Jawa Tengah", **MALANG).status == OK
    assert status(["Jawa Barat", "Banten"], **MALANG).status == GAGAL
    assert status("Kota Malang, Kota Batu", **MALANG).status == OK


def test_kalimat_memuat_nama_wilayah():
    assert status("Warga Kota Malang", **MALANG).status == OK
    assert status("Berdomisili di Jawa Timur", **MALANG).status == OK


def test_kupang_ntt():
    assert status("Nusa Tenggara Timur", **KUPANG).status == OK
    assert status("NTT", **KUPANG).status == OK
    assert status("Kota Kupang", **KUPANG).status == OK
    assert status("Jawa Timur", **KUPANG).status == GAGAL
    assert status("Indonesia", **KUPANG).status == OK


def test_jayapura_papua():
    assert status("Papua", **JAYAPURA).status == OK
    assert status("Kota Jayapura", **JAYAPURA).status == OK
    assert status("Papua Barat", **JAYAPURA).status == GAGAL
    assert status("Papua New Guinea", **JAYAPURA).status == GAGAL


def test_kuala_lumpur_malaysia():
    assert status("Malaysia", **KL).status == OK
    assert status("Kuala Lumpur", **KL).status == OK
    assert status("Indonesia", **KL).status == GAGAL
    assert status("Jawa Timur", **KL).status == GAGAL
    assert status("Singapore", **KL).status == GAGAL
    assert status("Kota Malang", **KL).status == GAGAL


def test_luar_negeri_tidak_cocok_untuk_wni_di_indonesia():
    for negara in ("Canada", "Singapore", "Australia", "Germany", "Japan"):
        assert status(negara, **MALANG).status == GAGAL, negara
        assert status(negara, **MALANG).status != OK


def test_domisili_dan_kewarganegaraan_tidak_menyilang():
    p = ProfilKelayakan(**MALANG)
    assert periksa_syarat("kewarganegaraan", {"nilai": ["Indonesia"]}, p, H).status == OK
    assert periksa_syarat("domisili", {"nilai": ["Kota Malang"]}, p, H).status == OK
    assert periksa_syarat("domisili", {"nilai": ["Indonesia"]}, p, H).status == OK
    assert periksa_syarat("kewarganegaraan", {"nilai": ["Canada"]}, p, H).status == GAGAL


def test_profil_lama_hanya_kota():
    lama = dict(kota_domisili="Malang")
    assert status("Jawa Timur", **lama).status == OK  # provinsi ditebak dari kota
    assert status("Papua", **lama).status == GAGAL
    assert status("Indonesia", **lama).status == OK
    assert status("Canada", **lama).status == GAGAL  # Malang dikenal berada di Indonesia
    assert status("Canada", kota_domisili="Springfield").status == TIDAK_DIKETAHUI


def test_kosong_tidak_diketahui_dan_syarat_negatif_tetap():
    assert status("Jawa Timur").status == TIDAK_DIKETAHUI
    assert status("Tidak berdomisili di Jerman lebih dari 15 bulan", **MALANG).status == OK
    assert status("Indonesia", negara_domisili="Malaysia").status == GAGAL


def test_daerah_asal_tetap_memenuhi():
    p = dict(
        negara_domisili="Indonesia",
        provinsi_domisili="DKI Jakarta",
        kota_domisili="Jakarta",
        daerah_asal=["Blitar", "Jawa Timur"],
    )
    assert status("Jawa Timur", **p).status == OK
    assert status("Kota Blitar", **p).status == OK
    assert status("Jawa Tengah", **p).status == GAGAL


def test_normalisasi():
    assert provinsi_kanonik("Jatim") == "Jawa Timur"
    assert provinsi_kanonik("daerah istimewa yogyakarta") == "DI Yogyakarta"
    assert provinsi_kanonik("Malang") is None
    assert negara_kanonik("singapore") == "Singapura"
    assert negara_kanonik("Papua New Guinea") == "Papua Nugini"
    assert len(PROVINSI_INDONESIA) == 38


def test_endpoint_referensi(klien):
    r = klien.get(f"{B}/referensi/wilayah")
    assert r.status_code == 200
    d = r.json()["data"]
    assert "Jawa Timur" in d["provinsi"] and len(d["provinsi"]) == 38
    assert "Indonesia" in d["negara"] and "Malaysia" in d["negara"] and d["negara_asal"] == "Indonesia"


def test_profil_menyimpan_dan_menormalkan_wilayah(klien):
    h = kepala(daftarkan(klien)["token_akses"])
    r = klien.put(
        f"{B}/me/profil",
        headers=h,
        json={"negara_domisili": "indonesia", "provinsi_domisili": "Jatim", "kota_domisili": "Malang"},
    )
    assert r.status_code == 200
    p = r.json()["data"]
    assert (p["negara_domisili"], p["provinsi_domisili"], p["kota_domisili"]) == ("Indonesia", "Jawa Timur", "Malang")
    # pindah ke luar negeri mengosongkan provinsi
    p2 = klien.put(
        f"{B}/me/profil", headers=h, json={"negara_domisili": "Malaysia", "kota_domisili": "Kuala Lumpur"}
    ).json()["data"]
    assert p2["negara_domisili"] == "Malaysia" and p2["provinsi_domisili"] is None


def test_profil_menolak_wilayah_tak_dikenal(klien):
    h = kepala(daftarkan(klien)["token_akses"])
    for badan in ({"negara_domisili": "Atlantis"}, {"provinsi_domisili": "Jawa Utara"}):
        assert klien.put(f"{B}/me/profil", headers=h, json=badan).status_code == 422, badan
