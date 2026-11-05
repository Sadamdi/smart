"""Uji profil lanjutan: gabung hasil baca tanpa menimpa isian, validasi butir, daerah asal pada syarat domisili, kata kunci."""

import uuid
from datetime import date

import pytest

from app.core.config import get_settings
from app.models import Pengguna
from app.rekomendasi.kelayakan import MEMENUHI, ProfilKelayakan, nilai_kelayakan
from app.services import dokumen
from app.services.rekomendasi import teks_tambahan
from tests.conftest import kepala
from tests.test_integrasi_db import B, _daftar, klien_db, sesi  # noqa: F401 (fixture)


def test_gabung_tidak_menimpa_isian_dan_tidak_menggandakan():
    lama = {"sekolah_asal": "SMAN 1 Malang", "organisasi": [{"nama": "HMJ TI", "jabatan": "Ketua"}]}
    hasil = {
        "sekolah_asal": "SMA Lain",
        "kota_asal": "Blitar",
        "organisasi": [{"nama": "hmj ti"}, {"nama": "UKM Robotik"}],
        "keahlian": ["Python", "python", "SQL"],
    }
    baru, terisi = dokumen.gabung_profil_lanjutan(lama, hasil)
    assert baru["sekolah_asal"] == "SMAN 1 Malang"  # tidak ditimpa
    assert baru["kota_asal"] == "Blitar"
    assert [o["nama"] for o in baru["organisasi"]] == ["HMJ TI", "UKM Robotik"]
    assert baru["keahlian"] == ["Python", "SQL"]
    assert {"kota_asal", "organisasi", "keahlian"} <= set(terisi)


def test_pengalaman_organisasi_dari_aturan_menjadi_organisasi():
    baru, terisi = dokumen.gabung_profil_lanjutan(None, {"pengalaman_organisasi": ["Ketua UKM Robotik"]})
    assert baru["organisasi"] == [{"nama": "Ketua UKM Robotik"}] and terisi == ["organisasi"]


def test_butir_tidak_valid_dibuang():
    daftar = dokumen._bersih_daftar(
        [
            {"nama": "Juara 2 OSN", "tingkat": "nasional", "tahun": 2022},
            {"nama": "x", "tingkat": "galaksi"},
            {"tahun": 2020},
        ],
        dokumen.Prestasi,
    )
    assert daftar == [{"nama": "Juara 2 OSN", "tingkat": "nasional", "tahun": 2022}]


def test_daerah_asal_memenuhi_syarat_domisili():
    syarat = [("domisili", {"nilai": ["Jawa Timur"]})]
    tanpa = ProfilKelayakan(kota_domisili="Jakarta")
    dengan = ProfilKelayakan(kota_domisili="Jakarta", daerah_asal=["Blitar", "Jawa Timur"])
    assert nilai_kelayakan(syarat, tanpa, date(2026, 11, 5)).kategori != MEMENUHI
    assert nilai_kelayakan(syarat, dengan, date(2026, 11, 5)).kategori == MEMENUHI


def test_teks_tambahan_memuat_kata_kunci_profil_lanjutan():
    p = Pengguna(email="a@example.com", nama="A", kata_sandi="x")
    p.catatan_tambahan = "penerima KIP"
    p.profil_lanjutan = {
        "fakultas": "Sains dan Teknologi",
        "organisasi": [{"nama": "UKM Robotik"}],
        "keahlian": ["Python"],
        "target_studi": {"bidang": ["kecerdasan buatan"], "negara": ["Jepang"]},
    }
    t = teks_tambahan(p)
    for kata in ("penerima KIP", "Sains dan Teknologi", "UKM Robotik", "Python", "kecerdasan buatan", "Jepang"):
        assert kata in t


@pytest.mark.usefixtures("klien_db")
@pytest.mark.skipif(not get_settings().database_url or get_settings().app_env == "prod", reason="butuh DB")
def test_profil_lanjutan_disimpan_dan_ditolak_bila_tidak_valid(klien_db):  # noqa: F811
    h = kepala(_daftar(klien_db, f"pl-{uuid.uuid4().hex[:8]}@example.com")["token_akses"])
    ok = {"profil_lanjutan": {"kota_asal": "Blitar", "organisasi": [{"nama": "HMJ TI", "tahun": 2025}], "keahlian": ["SQL"]}}
    r = klien_db.put(f"{B}/me/profil", json=ok, headers=h)
    assert r.status_code == 200 and r.json()["data"]["profil_lanjutan"]["kota_asal"] == "Blitar"
    salah = {"profil_lanjutan": {"prestasi": [{"nama": "Juara", "tingkat": "galaksi"}]}}
    assert klien_db.put(f"{B}/me/profil", json=salah, headers=h).status_code == 422
