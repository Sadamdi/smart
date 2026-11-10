from datetime import date, timedelta

from tests.conftest import daftarkan, kepala
from tests.fakes import buat_beasiswa

B = "/api/v1"
HARI_INI = date.today()


def _masuk(klien):
    return kepala(daftarkan(klien)["token_akses"])


def test_daftar_wajib_login(klien):
    assert klien.get(f"{B}/beasiswa").status_code == 401


def test_hanya_terbit_dan_belum_lewat_yang_tampil(klien, beasiswa_repo):
    beasiswa_repo.semua += [
        buat_beasiswa("Terbit Besok", HARI_INI + timedelta(days=1)),
        buat_beasiswa("Menunggu Validasi", HARI_INI + timedelta(days=10), status="menunggu_validasi"),
        buat_beasiswa("Kedaluwarsa", HARI_INI - timedelta(days=1)),
        buat_beasiswa("Ditolak", HARI_INI + timedelta(days=5), status="ditolak"),
        buat_beasiswa("Tanpa Tenggat", None),
    ]
    r = klien.get(f"{B}/beasiswa", headers=_masuk(klien))
    assert r.status_code == 200
    assert [b["nama"] for b in r.json()["data"]] == ["Terbit Besok"]


def test_filter_dan_pencarian(klien, beasiswa_repo):
    beasiswa_repo.semua += [
        buat_beasiswa("Beasiswa Unggulan", HARI_INI + timedelta(days=3), jenjang=["S1"], penyelenggara="Kemendikdasmen"),
        buat_beasiswa("LPDP Magister", HARI_INI + timedelta(days=4), jenjang=["S2"], penyelenggara="LPDP"),
        buat_beasiswa("Beasiswa Luar Negeri", HARI_INI + timedelta(days=5), jenjang=["S2"], negara="Jepang"),
    ]
    h = _masuk(klien)
    assert [b["nama"] for b in klien.get(f"{B}/beasiswa?jenjang=S2", headers=h).json()["data"]] == [
        "LPDP Magister",
        "Beasiswa Luar Negeri",
    ]
    assert [b["nama"] for b in klien.get(f"{B}/beasiswa?q=lpdp", headers=h).json()["data"]] == ["LPDP Magister"]
    assert [b["nama"] for b in klien.get(f"{B}/beasiswa?negara=Jepang", headers=h).json()["data"]] == [
        "Beasiswa Luar Negeri"
    ]
    assert klien.get(f"{B}/beasiswa?jenjang=S9", headers=h).status_code == 422


def test_paginasi_kursor_tanpa_duplikat(klien, beasiswa_repo):
    beasiswa_repo.semua += [buat_beasiswa(f"Beasiswa {i}", HARI_INI + timedelta(days=i + 1)) for i in range(5)]
    h = _masuk(klien)
    r1 = klien.get(f"{B}/beasiswa?batas=2", headers=h).json()
    assert len(r1["data"]) == 2 and r1["meta"]["kursor_berikut"]
    r2 = klien.get(f"{B}/beasiswa?batas=2&kursor={r1['meta']['kursor_berikut']}", headers=h).json()
    r3 = klien.get(f"{B}/beasiswa?batas=2&kursor={r2['meta']['kursor_berikut']}", headers=h).json()
    nama = [b["nama"] for r in (r1, r2, r3) for b in r["data"]]
    assert nama == [f"Beasiswa {i}" for i in range(5)] and r3["meta"]["kursor_berikut"] is None
    assert klien.get(f"{B}/beasiswa?kursor=rusak", headers=h).status_code == 422


def test_detail_dan_404(klien, beasiswa_repo):
    b = buat_beasiswa("Detail", HARI_INI + timedelta(days=2))
    tersembunyi = buat_beasiswa("Tersembunyi", HARI_INI + timedelta(days=2), status="menunggu_validasi")
    beasiswa_repo.semua += [b, tersembunyi]
    h = _masuk(klien)
    r = klien.get(f"{B}/beasiswa/{b.id}", headers=h)
    assert (
        r.status_code == 200
        and r.json()["data"]["nama"] == "Detail"
        and r.json()["data"]["tautan_resmi"].startswith("https://")
    )
    assert klien.get(f"{B}/beasiswa/{tersembunyi.id}", headers=h).status_code == 404
    assert klien.get(f"{B}/beasiswa/00000000-0000-0000-0000-000000000000", headers=h).status_code == 404
    assert klien.get(f"{B}/beasiswa/bukan-uuid", headers=h).status_code == 422


def test_detail_menilai_syarat_terhadap_profil(klien, beasiswa_repo):
    from app.api.v1.beasiswa import profil_kelayakan
    from app.main import app
    from app.models import Persyaratan
    from app.rekomendasi.kelayakan import ProfilKelayakan

    b = buat_beasiswa("Dinilai", HARI_INI + timedelta(days=9))
    beasiswa_repo.semua.append(b)
    beasiswa_repo.syarat[b.id] = [
        Persyaratan(beasiswa_id=b.id, jenis="ipk_minimum", nilai_batas={"nilai": 3.5}, dapat_dikejar=False),
        Persyaratan(beasiswa_id=b.id, jenis="jenjang", nilai_batas={"nilai": ["S1"]}, dapat_dikejar=False),
    ]
    app.dependency_overrides[profil_kelayakan] = lambda: ProfilKelayakan(ipk=3.7, jenjang="S1")
    h = _masuk(klien)
    d = klien.get(f"{B}/beasiswa/{b.id}", headers=h).json()["data"]
    assert [s["status"] for s in d["persyaratan"]] == ["terpenuhi", "terpenuhi"]
    assert d["kategori"] == "memenuhi" and d["alasan"] and d["catatan_kekurangan"] == []
    assert all(s["catatan"] for s in d["persyaratan"])
