import uuid
from datetime import date

from app.rekomendasi.embedding import PengemasHash, kemiripan
from app.rekomendasi.kelayakan import (
    BELUM,
    GAGAL,
    HAMPIR,
    MEMENUHI,
    OK,
    TIDAK_DIKETAHUI,
    TOLERAN,
    ProfilKelayakan,
    nilai_kelayakan,
    periksa_syarat,
    usia,
)
from app.rekomendasi.mesin import MasukanBeasiswa, susun

HARI = date(2026, 11, 3)


def profil(**kw):
    dasar = dict(jenjang="S1", semester=5, ipk=3.5, jenis_kampus="negeri", kota_domisili="Malang")
    dasar.update(kw)
    return ProfilKelayakan(**dasar)


def test_ipk_memenuhi_toleransi_dan_gagal():
    p = profil(ipk=3.4)
    assert periksa_syarat("ipk_minimum", {"nilai": 3.0}, p, HARI).status == OK
    h = periksa_syarat("ipk_minimum", {"nilai": 3.5}, p, HARI)
    assert h.status == TOLERAN and "0.10" in h.kekurangan
    assert periksa_syarat("ipk_minimum", {"nilai": 3.9}, p, HARI).status == GAGAL


def test_profil_kosong_tidak_diketahui_bukan_gagal():
    h = periksa_syarat("ipk_minimum", {"nilai": 3.0}, ProfilKelayakan(), HARI)
    assert h.status == TIDAK_DIKETAHUI and "Lengkapi IPK" in h.kekurangan


def test_semester_minimum_dengan_toleransi_satu_semester():
    assert periksa_syarat("semester_minimum", {"nilai": 6}, profil(semester=5), HARI).status == TOLERAN
    assert periksa_syarat("semester_minimum", {"nilai": 7}, profil(semester=5), HARI).status == GAGAL
    assert periksa_syarat("semester_maksimum", {"nilai": 6}, profil(semester=7), HARI).status == GAGAL


def test_jenjang_kampus_domisili_tak_dapat_dikejar():
    assert periksa_syarat("jenjang", {"nilai": ["S1", "D4"]}, profil(), HARI).status == OK
    assert periksa_syarat("jenjang", {"nilai": ["S2"]}, profil(), HARI).status == GAGAL
    assert periksa_syarat("jenis_kampus", {"nilai": "swasta"}, profil(), HARI).status == GAGAL
    assert periksa_syarat("domisili", {"nilai": ["Malang"]}, profil(), HARI).status == OK
    assert periksa_syarat("domisili", {"nilai": ["Papua"]}, profil(), HARI).status == GAGAL


def test_usia_dan_penghasilan():
    assert usia(date(2005, 5, 15), HARI) == 21
    assert usia(date(2005, 12, 1), HARI) == 20
    assert periksa_syarat("usia_maksimum", {"nilai": 21}, profil(tanggal_lahir=date(2005, 5, 15)), HARI).status == OK
    assert periksa_syarat("usia_maksimum", {"nilai": 20}, profil(tanggal_lahir=date(2005, 5, 15)), HARI).status == GAGAL
    assert (
        periksa_syarat("penghasilan_maksimum", {"nilai": 4000000}, profil(penghasilan_orang_tua=5000000), HARI).status
        == GAGAL
    )


def test_sertifikat_bahasa():
    syarat = {"jenis": "toefl", "nilai": 500}
    assert periksa_syarat("sertifikat_bahasa", syarat, profil(), HARI).status == TOLERAN  # belum punya
    assert periksa_syarat("sertifikat_bahasa", syarat, profil(skor_bahasa={"toefl": 470}), HARI).status == TOLERAN
    assert periksa_syarat("sertifikat_bahasa", syarat, profil(skor_bahasa={"toefl": 400}), HARI).status == GAGAL
    assert periksa_syarat("sertifikat_bahasa", syarat, profil(skor_bahasa={"toefl": 520}), HARI).status == OK


def test_berkas_pendukung_dan_syarat_informasi():
    assert periksa_syarat("berkas_pendukung", {"nama": "Surat rekomendasi"}, profil(), HARI).status == TOLERAN
    p = profil()
    p.berkas_diunggah = {"surat rekomendasi"}
    assert periksa_syarat("berkas_pendukung", {"nama": "Surat rekomendasi"}, p, HARI).status == OK
    assert periksa_syarat("lainnya", {"teks": "aktif organisasi"}, profil(), HARI) is None


def test_kategori_memenuhi():
    h = nilai_kelayakan([("ipk_minimum", {"nilai": 3.0}), ("jenjang", {"nilai": ["S1"]})], profil(), HARI)
    assert h.kategori == MEMENUHI and h.catatan_kekurangan == [] and len(h.alasan) == 2


def test_kategori_hampir_memenuhi_menyimpan_catatan():
    h = nilai_kelayakan([("ipk_minimum", {"nilai": 3.6}), ("jenjang", {"nilai": ["S1"]})], profil(), HARI)
    assert h.kategori == HAMPIR and any("IPK kurang" in c for c in h.catatan_kekurangan)


def test_syarat_tak_dapat_dikejar_gagal_membuat_belum_memenuhi():
    h = nilai_kelayakan([("jenjang", {"nilai": ["S2"]}), ("ipk_minimum", {"nilai": 3.0})], profil(), HARI)
    assert h.kategori == BELUM


def test_ipk_di_luar_toleransi_belum_memenuhi():
    assert nilai_kelayakan([("ipk_minimum", {"nilai": 3.9})], profil(), HARI).kategori == BELUM


def test_tanpa_syarat_terukur_tidak_dinyatakan_memenuhi():
    h = nilai_kelayakan([("lainnya", {"teks": "bebas"})], profil(), HARI)
    assert h.kategori == HAMPIR and h.catatan_kekurangan == ["Syarat belum tercatat, periksa laman resmi"]


def test_pengemas_deterministik_dan_kemiripan_masuk_akal():
    p = PengemasHash()
    a = p.kemas("teknologi informasi komputer")
    assert a == p.kemas("teknologi informasi komputer")
    dekat = kemiripan(a, p.kemas("beasiswa teknologi informasi"))
    jauh = kemiripan(a, p.kemas("pertanian kehutanan"))
    assert dekat > jauh
    assert 0 <= jauh <= dekat <= 1


def test_susun_urut_per_kategori_lalu_skor_dan_lewati_tenggat_lalu():
    def b(nama, syarat, tenggat=date(2026, 12, 1), manfaat=None):
        return MasukanBeasiswa(uuid.uuid4(), nama, "Penyelenggara", manfaat, tenggat, syarat)

    ok = b("Beasiswa Teknologi", [("ipk_minimum", {"nilai": 3.0})], manfaat="teknologi informasi")
    hampir = b("Beasiswa Prestasi", [("ipk_minimum", {"nilai": 3.6})])
    belum = b("Beasiswa S2", [("jenjang", {"nilai": ["S2"]})])
    lewat = b("Beasiswa Lama", [], tenggat=date(2026, 10, 1))
    hasil = susun(profil(), ["teknologi informasi"], "Teknik Informatika", [belum, hampir, lewat, ok], HARI)
    assert [h.beasiswa_id for h in hasil] == [ok.id, hampir.id, belum.id]
    assert hasil[0].skor >= 0.6 and all(0 <= h.skor <= 1 for h in hasil)
    assert any("mirip" in a for a in hasil[0].alasan)
