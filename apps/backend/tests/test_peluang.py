from app.rekomendasi.peluang import (
    DASAR_KETAT,
    DASAR_LONGGAR,
    estimasi_peluang,
    kekuatan_profil,
    persaingan_dasar,
)
from app.services.kartu import peluang_untuk


class _B:
    def __init__(self, nama="Beasiswa Biasa", penyelenggara=None, negara="Indonesia"):
        self.nama, self.penyelenggara, self.negara = nama, penyelenggara, negara


class _P:
    def __init__(self, ipk=None, profil_lanjutan=None, skor_bahasa=None):
        self.ipk, self.profil_lanjutan, self.skor_bahasa = ipk, profil_lanjutan, skor_bahasa


def test_persaingan_ketat_dan_longgar():
    assert persaingan_dasar("LPDP Reguler", "Kemenkeu", False) == DASAR_KETAT
    assert persaingan_dasar("Chevening", None, True) == 0.02  # sangat ketat
    assert persaingan_dasar("KIP Kuliah", None, False) == DASAR_LONGGAR
    assert persaingan_dasar("Beasiswa X", None, True) < persaingan_dasar("Beasiswa X", None, False)


def test_kekuatan_profil_naik_dengan_isian():
    kosong = kekuatan_profil(None, None, None)
    kuat = kekuatan_profil(
        3.9,
        {
            "prestasi": [{"nama": "Juara", "tingkat": "nasional"}],
            "organisasi": [{"nama": "a"}, {"nama": "b"}, {"nama": "c"}],
            "sertifikat": [{"nama": "a"}, {"nama": "b"}],
            "pengalaman": [{"nama": "a"}],
        },
        {"toefl": 550},
    )
    assert 0 <= kosong < kuat <= 1


def test_estimasi_dipengaruhi_kategori_dan_profil_dan_dibatasi():
    k = dict(ada_syarat_terukur=True, nama="Beasiswa Biasa", penyelenggara=None, luar_negeri=False)
    memenuhi = estimasi_peluang(kategori="memenuhi", kekuatan=0.5, **k)
    hampir = estimasi_peluang(kategori="hampir_memenuhi", kekuatan=0.5, **k)
    belum = estimasi_peluang(kategori="belum_memenuhi", kekuatan=0.5, **k)
    assert memenuhi > hampir > belum >= 2
    assert estimasi_peluang(kategori="memenuhi", kekuatan=1.0, **k) > estimasi_peluang(
        kategori="memenuhi", kekuatan=0.0, **k
    )
    # tidak pernah menyatakan pasti: batas atas 90
    assert (
        estimasi_peluang(
            kategori="memenuhi",
            kekuatan=1.0,
            ada_syarat_terukur=True,
            nama="KIP Kuliah",
            penyelenggara=None,
            luar_negeri=False,
        )
        <= 90
    )


def test_tanpa_syarat_terukur_tidak_ada_estimasi():
    assert (
        estimasi_peluang(
            kategori="hampir_memenuhi",
            ada_syarat_terukur=False,
            nama="x",
            penyelenggara=None,
            luar_negeri=False,
            kekuatan=0.9,
        )
        is None
    )


def test_peluang_untuk_menyertakan_alasan_dan_wilayah():
    h = peluang_untuk(
        _P(ipk=3.6), _B("LPDP", "Kemenkeu", "Indonesia"), "memenuhi", 1.0, ["IPK memenuhi", "Jenjang sesuai"], []
    )
    assert h["estimasi_peluang"] is not None and h["syarat_total"] == 2 and h["luar_negeri"] is False
    assert h["_alasan_peluang"]
    h2 = peluang_untuk(_P(), _B(), "hampir_memenuhi", 0.4, [], ["Syarat belum tercatat, periksa laman resmi"])
    assert h2["estimasi_peluang"] is None


def test_sertifikat_menerima_jenis_dan_membuang_jenis_asing():
    from app.schemas.pengguna import Sertifikat
    from app.services.dokumen import _bersih_daftar

    ok = _bersih_daftar([{"nama": "Panitia Seminar", "jenis": "kepanitiaan"}, {"nama": "X", "jenis": "ngawur"}], Sertifikat)
    assert [x["nama"] for x in ok] == ["Panitia Seminar"]


def test_berkas_dihapus_setelah_dibaca_dan_hasil_tetap(tmp_path):
    from pathlib import Path

    from app.core.config import Settings
    from app.services import dokumen

    class _Sesi:
        def add(self, _):
            pass

        def flush(self):
            pass

        def scalars(self, _):
            return []

    class _P2:
        import uuid

        id = uuid.UUID("11111111-1111-1111-1111-111111111111")
        nama = "Nabila Putri"

    st = Settings(upload_dir=str(tmp_path), upload_simpan_berkas=False)
    d = dokumen.simpan(
        _Sesi(), _P2(), "cv", "cv.txt", b"IPK 3,75 semester 5 TOEFL 520 organisasi BEM Fakultas Teknik periode 2024", st
    )
    assert d.status_baca == "selesai" and d.hasil_baca["ipk"] == 3.75
    assert d.lokasi_penyimpanan == ""
    assert not list(Path(tmp_path).rglob("*.txt"))
    st2 = Settings(upload_dir=str(tmp_path), upload_simpan_berkas=True)
    d2 = dokumen.simpan(
        _Sesi(), _P2(), "cv", "cv.txt", b"IPK 3,75 semester 5 TOEFL 520 organisasi BEM Fakultas Teknik periode 2024", st2
    )
    assert d2.lokasi_penyimpanan and Path(d2.lokasi_penyimpanan).exists()


def test_statistik_lpdp_cocok_dan_rasio_dipakai():
    from app.rekomendasi import statistik

    entri = statistik.cari("LPDP Reguler Magister dan Doktor", "Kemenkeu")
    assert [e["periode"] for e in entri] == ["2024", "2023"]
    assert all(e["sumber"] and e["url"].startswith("https://") for e in entri)
    assert round(statistik.rasio_terbaru(entri), 3) == 0.23  # 60 persen 2024 (0,19) + 40 persen 2023 (0,29)
    assert statistik.cari("Beasiswa Tanpa Data", None) == []
    assert statistik.rasio_terbaru([]) is None
    # KIP Kuliah hanya punya kuota, tanpa rasio: dasar tetap perkiraan
    assert statistik.rasio_terbaru(statistik.cari("KIP Kuliah", None)) is None


def test_peluang_untuk_memakai_statistik_dan_menandai_dasarnya():
    h = peluang_untuk(_P(ipk=3.6), _B("LPDP Reguler", "Kemenkeu", "Indonesia"), "memenuhi", 1.0, ["a", "b"], [])
    assert h["_dasar_peluang"] == "statistik" and h["_statistik"]
    assert any(a.startswith("Persaingan memakai rasio") for a in h["_alasan_peluang"])
    h2 = peluang_untuk(_P(ipk=3.6), _B("Beasiswa Lokal Biasa"), "memenuhi", 1.0, ["a", "b"], [])
    assert h2["_dasar_peluang"] == "perkiraan" and h2["_statistik"] == []


def test_statistik_memilih_data_menurut_jenjang():
    from app.rekomendasi import statistik

    assert statistik.cari("IISMA 2025", None, ["S1"])  # IISMA mencakup S1 dan vokasi
    assert not statistik.cari("IISMA 2025", None, ["S3"])  # tidak ada data S3
    assert statistik.cari("Gates Cambridge", None, ["S3"])
    assert not statistik.cari("Gates Cambridge", None, ["S1"])


def test_tingkat_persaingan_program_tanpa_data_mengikuti_kalibrasi():
    from app.rekomendasi.peluang import tingkat_persaingan

    assert tingkat_persaingan("Beasiswa Djarum", None, False) == "sangat_ketat"
    assert tingkat_persaingan("Erasmus Mundus", None, True) == "ketat"
    assert tingkat_persaingan("Beasiswa Pemda Kabupaten", None, False) == "longgar"
    assert tingkat_persaingan("Beasiswa Universitas Luar X", None, True) == "ketat"
    assert tingkat_persaingan("Beasiswa Yayasan Lokal", None, False) == "sedang"


def test_peluang_untuk_program_tanpa_data_menyebut_tingkat():
    h = peluang_untuk(_P(ipk=3.4), _B("Beasiswa Yayasan Lokal"), "memenuhi", 1.0, ["a", "b"], [])
    assert h["_tingkat"] == "sedang" and h["_dasar_peluang"] == "perkiraan"
    assert any("diperkirakan sedang" in a for a in h["_alasan_peluang"])


def test_pencocokan_statistik_tidak_salah_penyelenggara():
    from app.rekomendasi import statistik

    # Beasiswa Unggulan milik Kemendikbud tidak boleh dipakai untuk Beasiswa UNGGULAN kampus atau Kemenag
    assert statistik.cari("Beasiswa Unggulan", "Kementerian Pendidikan Tinggi, Sains, dan Teknologi")
    assert not statistik.cari("Beasiswa UNGGULAN", "Universitas Udayana")
    assert not statistik.cari("Beasiswa Unggulan Keagamaan Sarjana", "Kementerian Agama Republik Indonesia")
    # LPDP-AAS bukan program LPDP reguler
    assert not any(
        e["program"].startswith("LPDP") for e in statistik.cari("Australia Awards Indonesia: LPDP-AAS", "LPDP-AAS")
    )
    assert statistik.cari("Beasiswa LPDP Tahap 1 2026", "LPDP")
    # Türkiye dan Pertamina
    assert statistik.rasio_terbaru(statistik.cari("Türkiye Scholarships (Graduate)", "Türkiye Scholarships")) == 0.041
    assert statistik.cari("Beasiswa Pertamina Sobat Bumi 2026", "Pertamina Foundation")


def test_teladan_hanya_milik_tanoto():
    from app.rekomendasi import statistik

    assert statistik.cari("Beasiswa TELADAN", "Tanoto Foundation")
    assert not statistik.cari("Beasiswa Kepemimpinan Teladan", "Kementerian Pendidikan Tinggi, Sains, dan Teknologi")
    assert not statistik.cari("Tanoto Foundation: BEACON", "Tanoto Foundation")


def test_perkecil_gambar_dan_batas_total(tmp_path):
    import io

    from PIL import Image

    from app.services import dokumen

    besar = io.BytesIO()
    Image.effect_noise((3000, 2000), 80).convert("RGB").save(besar, "JPEG", quality=95)
    kecil = dokumen.perkecil_gambar("foto.jpg", besar.getvalue(), 1600)
    assert len(kecil) < len(besar.getvalue())
    assert max(Image.open(io.BytesIO(kecil)).size) <= 1600
    assert dokumen.perkecil_gambar("a.pdf", b"%PDF", 1600) == b"%PDF"
    assert dokumen.perkecil_gambar("rusak.png", b"bukan gambar", 1600) == b"bukan gambar"
