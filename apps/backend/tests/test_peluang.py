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
    assert persaingan_dasar("Chevening", None, True) == DASAR_KETAT
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

    class _P2:
        id = "11111111-1111-1111-1111-111111111111"

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
    assert statistik.rasio_terbaru(entri) == 0.19
    assert statistik.cari("Beasiswa Tanpa Data", None) == []
    assert statistik.rasio_terbaru([]) is None
    # KIP Kuliah hanya punya kuota, tanpa rasio: dasar tetap perkiraan
    assert statistik.rasio_terbaru(statistik.cari("KIP Kuliah", None)) is None


def test_peluang_untuk_memakai_statistik_dan_menandai_dasarnya():
    h = peluang_untuk(_P(ipk=3.6), _B("LPDP Reguler", "Kemenkeu", "Indonesia"), "memenuhi", 1.0, ["a", "b"], [])
    assert h["_dasar_peluang"] == "statistik" and h["_statistik"]
    assert h["_alasan_peluang"][0].startswith("Persaingan memakai rasio")
    h2 = peluang_untuk(_P(ipk=3.6), _B("Beasiswa Lokal Biasa"), "memenuhi", 1.0, ["a", "b"], [])
    assert h2["_dasar_peluang"] == "perkiraan" and h2["_statistik"] == []
