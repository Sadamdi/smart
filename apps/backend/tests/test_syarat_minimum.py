from datetime import date

import pytest

from app.rekomendasi import kelayakan
from app.rekomendasi.kelayakan import (
    BELUM,
    HAMPIR,
    MEMENUHI,
    SYARAT_KUAT_MINIMUM,
    ProfilKelayakan,
    nilai_kelayakan,
)
from app.rekomendasi.peluang import estimasi_peluang

HARI = date(2026, 11, 17)
PROFIL = ProfilKelayakan(jenjang="S1", semester=5, ipk=3.6, kewarganegaraan="Indonesia")
SATU_KUAT = [("kewarganegaraan", {"nilai": "Indonesia"}), ("jenjang", {"nilai": ["S1"]})]


def test_bawaan_satu_syarat_terukur():
    assert SYARAT_KUAT_MINIMUM == 1  # hitungan Memenuhi di Beranda tetap berguna; data tipis diredam di estimasi peluang


def test_satu_syarat_terukur_memenuhi_pada_bawaan():
    assert nilai_kelayakan(SATU_KUAT, PROFIL, HARI).kategori == MEMENUHI


def test_minimum_dua_dapat_diperketat(monkeypatch):
    monkeypatch.setattr(kelayakan, "SYARAT_KUAT_MINIMUM", 2)
    h = nilai_kelayakan(SATU_KUAT, PROFIL, HARI)
    assert h.kategori == HAMPIR and "Syarat terukur masih sedikit" in h.catatan_kekurangan[0]


def test_data_tipis_meredam_estimasi_tanpa_mengubah_kategori():
    k = dict(
        kategori="memenuhi", ada_syarat_terukur=True, nama="Beasiswa X", penyelenggara=None, luar_negeri=False, kekuatan=0.5
    )
    lengkap = estimasi_peluang(jumlah_syarat=4, **k)
    tipis = estimasi_peluang(jumlah_syarat=1, **k)
    assert tipis < lengkap


def test_jenjang_tujuan_di_profil_lanjutan_dihitung():
    profil = ProfilKelayakan(jenjang="S1", semester=3, ipk=3.6, jenjang_tuju=["S2"])
    h = nilai_kelayakan([("ipk_minimum", {"nilai": 3.0}), ("jenjang", {"nilai": ["S2"]})], profil, HARI)
    assert h.kategori == MEMENUHI
    assert any("Jenjang tujuan S2" in a for a in h.alasan)


@pytest.mark.parametrize(
    "jenjang,semester,diminta,kategori",
    [
        ("S1", 8, ["S2"], HAMPIR),  # tingkat akhir menuju S2: harus lulus dulu
        ("S1", 3, ["S2"], BELUM),  # masih awal kuliah
        ("S2", 3, ["S3"], HAMPIR),
        ("S2", 1, ["S3"], BELUM),
        ("S3", 4, ["S1"], BELUM),  # tidak pernah turun jenjang
    ],
)
def test_kelulusan_dekat_dinilai_hampir_bukan_gagal(jenjang, semester, diminta, kategori):
    profil = ProfilKelayakan(jenjang=jenjang, semester=semester, ipk=3.6)
    h = nilai_kelayakan([("ipk_minimum", {"nilai": 3.0}), ("jenjang", {"nilai": diminta})], profil, HARI)
    assert h.kategori == kategori
