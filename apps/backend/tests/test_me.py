from tests.conftest import daftarkan, kepala

B = "/api/v1"


def test_ubah_profil_hanya_kolom_yang_dikirim(klien):
    data = daftarkan(klien)
    h = kepala(data["token_akses"])
    r = klien.put(
        f"{B}/me/profil",
        headers=h,
        json={
            "kampus": "UIN Malang",
            "jenjang": "S1",
            "semester": 5,
            "ipk": "3.60",
            "minat": ["teknologi", "data"],
        },
    )
    assert r.status_code == 200
    p = r.json()["data"]
    assert (
        p["kampus"] == "UIN Malang"
        and p["semester"] == 5
        and p["ipk"] == "3.60"
        and p["minat"] == ["teknologi", "data"]
    )
    r2 = klien.put(f"{B}/me/profil", headers=h, json={"ips_terakhir": "3.75"})
    p2 = r2.json()["data"]
    assert p2["ips_terakhir"] == "3.75" and p2["kampus"] == "UIN Malang"  # kolom lain tidak berubah


def test_profil_validasi_ditolak_422(klien):
    h = kepala(daftarkan(klien)["token_akses"])
    for badan in (
        {"ipk": "4.5"},
        {"ipk": "-1"},
        {"semester": 0},
        {"semester": 15},
        {"jenjang": "S9"},
        {"jenis_kampus": "asing"},
        {"penghasilan_orang_tua": -1},
    ):
        r = klien.put(f"{B}/me/profil", headers=h, json=badan)
        assert r.status_code == 422, badan
        assert r.json()["error"]["code"] == "VALIDATION"


def test_profil_tidak_bisa_mengubah_peran_atau_email(klien):
    h = kepala(daftarkan(klien)["token_akses"])
    klien.put(f"{B}/me/profil", headers=h, json={"peran": "admin", "email": "lain@example.com"})
    p = klien.get(f"{B}/me", headers=h).json()["data"]
    assert p["peran"] == "mahasiswa" and p["email"] == "mahasiswa@example.com"


def test_preferensi_notifikasi(klien):
    h = kepala(daftarkan(klien)["token_akses"])
    r = klien.put(f"{B}/me/preferensi-notifikasi", headers=h, json={"email": False, "push": True})
    assert r.json()["data"]["preferensi_notifikasi"] == {"email": False, "push": True}


def test_ekspor_hanya_data_milik_sendiri(klien):
    a = kepala(daftarkan(klien, email="a@example.com", nama="A")["token_akses"])
    daftarkan(klien, email="b@example.com", nama="B")
    r = klien.get(f"{B}/me/ekspor", headers=a)
    assert r.status_code == 200 and r.json()["data"]["profil"]["email"] == "a@example.com"


def test_hapus_akun_menghapus_dan_token_tidak_berlaku(klien, pengguna_repo):
    data = daftarkan(klien)
    h = kepala(data["token_akses"])
    assert klien.delete(f"{B}/me", headers=h).status_code == 200
    assert pengguna_repo.data == {}
    assert klien.get(f"{B}/me", headers=h).status_code == 401
