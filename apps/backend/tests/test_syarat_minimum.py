from datetime import date

from app.rekomendasi.kelayakan import HAMPIR, MEMENUHI, SYARAT_KUAT_MINIMUM, ProfilKelayakan, nilai_kelayakan
from app.services.kartu import metrik

HARI = date(2026, 11, 17)
PROFIL = ProfilKelayakan(jenjang="S1", semester=5, ipk=3.6, kewarganegaraan="Indonesia")


def test_bawaan_dua_syarat_terukur():
    assert SYARAT_KUAT_MINIMUM == 2


def test_satu_syarat_terukur_tidak_cukup_untuk_memenuhi():
    h = nilai_kelayakan([("kewarganegaraan", {"nilai": "Indonesia"}), ("jenjang", {"nilai": ["S1"]})], PROFIL, HARI)
    assert h.kategori == HAMPIR
    assert h.skor <= 0.5
    assert "Syarat terukur masih sedikit" in h.catatan_kekurangan[0]


def test_dua_syarat_terukur_boleh_memenuhi():
    h = nilai_kelayakan(
        [("kewarganegaraan", {"nilai": "Indonesia"}), ("ipk_minimum", {"nilai": 3.0}), ("jenjang", {"nilai": ["S1"]})],
        PROFIL,
        HARI,
    )
    assert h.kategori == MEMENUHI


def test_syarat_tipis_tidak_diberi_angka_di_kartu():
    h = nilai_kelayakan([("kewarganegaraan", {"nilai": "Indonesia"})], PROFIL, HARI)
    m = metrik(h.skor, h.alasan, h.catatan_kekurangan)
    assert m == {"skor_kelayakan": None, "syarat_terpenuhi": 0, "syarat_total": 0}
