import uuid
from datetime import UTC, datetime, timedelta

from app.core.security import AKSES, PENYEGAR, buat_token
from tests.conftest import SETTINGS_UJI, daftarkan, kepala

B = "/api/v1"


def test_daftar_berhasil_tidak_membocorkan_rahasia(klien):
    data = daftarkan(klien)
    assert data["pengguna"]["peran"] == "mahasiswa"
    assert "kata_sandi" not in data["pengguna"] and "versi_token" not in data["pengguna"]
    assert data["token_akses"] and data["token_penyegar"]


def test_daftar_ganda_409_dan_peran_tidak_bisa_dipilih(klien):
    daftarkan(klien)
    r = klien.post(
        f"{B}/auth/register",
        json={"nama": "X", "email": "MAHASISWA@example.com", "kata_sandi": "kata-sandi-panjang"},
    )
    assert r.status_code == 409 and r.json()["error"]["code"] == "CONFLICT"
    r2 = klien.post(
        f"{B}/auth/register",
        json={"nama": "Y", "email": "lain@example.com", "kata_sandi": "kata-sandi-panjang", "peran": "admin"},
    )
    assert r2.json()["data"]["pengguna"]["peran"] == "mahasiswa"


def test_daftar_validasi_422(klien):
    assert (
        klien.post(
            f"{B}/auth/register",
            json={"nama": "X", "email": "bukan-email", "kata_sandi": "kata-sandi-panjang"},
        ).status_code
        == 422
    )
    r = klien.post(f"{B}/auth/register", json={"nama": "X", "email": "a@example.com", "kata_sandi": "pendek"})
    assert r.status_code == 422 and r.json()["error"]["code"] == "VALIDATION"


def test_masuk_benar_dan_salah(klien):
    daftarkan(klien)
    ok = klien.post(f"{B}/auth/login", json={"email": "mahasiswa@example.com", "kata_sandi": "kata-sandi-panjang"})
    assert ok.status_code == 200 and ok.json()["data"]["kedaluwarsa_detik"] == 900
    salah = klien.post(f"{B}/auth/login", json={"email": "mahasiswa@example.com", "kata_sandi": "salah-sekali"})
    tak_ada = klien.post(f"{B}/auth/login", json={"email": "tidakada@example.com", "kata_sandi": "kata-sandi-panjang"})
    assert salah.status_code == tak_ada.status_code == 401
    assert salah.json()["error"]["message"] == tak_ada.json()["error"]["message"]  # tidak membocorkan keberadaan akun


def test_masuk_dibatasi_setelah_lima_kali_gagal(klien):
    daftarkan(klien)
    for _ in range(5):
        assert (
            klien.post(f"{B}/auth/login", json={"email": "mahasiswa@example.com", "kata_sandi": "salah-sekali"}).status_code
            == 401
        )
    r = klien.post(f"{B}/auth/login", json={"email": "mahasiswa@example.com", "kata_sandi": "kata-sandi-panjang"})
    assert r.status_code == 429 and r.json()["error"]["code"] == "RATE_LIMITED"


def test_me_tanpa_token_dan_token_rusak_401(klien):
    assert klien.get(f"{B}/me").status_code == 401
    assert klien.get(f"{B}/me", headers=kepala("bukan.token.valid")).status_code == 401


def test_token_kedaluwarsa_401(klien):
    data = daftarkan(klien)
    pid = klien.get(f"{B}/me", headers=kepala(data["token_akses"])).json()["data"]["id"]
    lama = buat_token(uuid.UUID(pid), 0, AKSES, SETTINGS_UJI, sekarang=datetime.now(UTC) - timedelta(hours=2))
    r = klien.get(f"{B}/me", headers=kepala(lama))
    assert r.status_code == 401 and "kedaluwarsa" in r.json()["error"]["message"]


def test_token_penyegar_tidak_bisa_dipakai_sebagai_akses_dan_sebaliknya(klien):
    data = daftarkan(klien)
    assert klien.get(f"{B}/me", headers=kepala(data["token_penyegar"])).status_code == 401
    assert klien.post(f"{B}/auth/refresh", json={"token_penyegar": data["token_akses"]}).status_code == 401
    r = klien.post(f"{B}/auth/refresh", json={"token_penyegar": data["token_penyegar"]})
    assert r.status_code == 200 and r.json()["data"]["token_akses"]


def test_logout_mencabut_semua_token(klien):
    data = daftarkan(klien)
    h = kepala(data["token_akses"])
    assert klien.post(f"{B}/auth/logout", headers=h).status_code == 200
    assert klien.get(f"{B}/me", headers=h).status_code == 401
    assert klien.post(f"{B}/auth/refresh", json={"token_penyegar": data["token_penyegar"]}).status_code == 401


def test_ganti_kata_sandi_mencabut_token_lama_dan_memberi_token_baru(klien):
    data = daftarkan(klien)
    h = kepala(data["token_akses"])
    salah = klien.post(
        f"{B}/auth/ganti-kata-sandi",
        headers=h,
        json={"kata_sandi_lama": "bukan-ini", "kata_sandi_baru": "kata-sandi-baru-1"},
    )
    assert salah.status_code == 403
    ok = klien.post(
        f"{B}/auth/ganti-kata-sandi",
        headers=h,
        json={"kata_sandi_lama": "kata-sandi-panjang", "kata_sandi_baru": "kata-sandi-baru-1"},
    )
    assert ok.status_code == 200
    assert klien.get(f"{B}/me", headers=h).status_code == 401
    assert klien.get(f"{B}/me", headers=kepala(ok.json()["data"]["token_akses"])).status_code == 200
    assert (
        klien.post(f"{B}/auth/login", json={"email": "mahasiswa@example.com", "kata_sandi": "kata-sandi-baru-1"}).status_code
        == 200
    )


def test_token_pengguna_berbeda_memberi_data_berbeda(klien):
    a = daftarkan(klien, email="a@example.com", nama="A")
    b = daftarkan(klien, email="b@example.com", nama="B")
    me_a = klien.get(f"{B}/me", headers=kepala(a["token_akses"])).json()["data"]
    me_b = klien.get(f"{B}/me", headers=kepala(b["token_akses"])).json()["data"]
    assert me_a["email"] == "a@example.com" and me_b["email"] == "b@example.com" and me_a["id"] != me_b["id"]


def test_jenis_token_berbeda():
    assert AKSES != PENYEGAR
