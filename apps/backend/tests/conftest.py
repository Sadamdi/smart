import pytest
from fastapi.testclient import TestClient

from app.api.deps import get_beasiswa_repo, get_pengguna_repo
from app.api.v1.beasiswa import profil_kelayakan
from app.core.config import Settings, get_settings
from app.core.ratelimit import pembatas_login
from app.main import app
from app.rekomendasi.kelayakan import ProfilKelayakan
from tests.fakes import BeasiswaRepoPalsu, PenggunaRepoPalsu

SETTINGS_UJI = Settings(
    _env_file=None,
    app_env="test",
    jwt_secret="rahasia-uji-yang-cukup-panjang-untuk-hs256-123456",
    jwt_access_menit=15,
    jwt_refresh_hari=30,
)


@pytest.fixture
def pengguna_repo():
    return PenggunaRepoPalsu()


@pytest.fixture
def beasiswa_repo():
    return BeasiswaRepoPalsu([])


@pytest.fixture
def klien(pengguna_repo, beasiswa_repo):
    app.dependency_overrides[get_pengguna_repo] = lambda: pengguna_repo
    app.dependency_overrides[get_beasiswa_repo] = lambda: beasiswa_repo
    app.dependency_overrides[get_settings] = lambda: SETTINGS_UJI
    app.dependency_overrides[profil_kelayakan] = lambda: ProfilKelayakan()
    pembatas_login._gagal.clear()
    yield TestClient(app)
    app.dependency_overrides.clear()


def daftarkan(klien, email="mahasiswa@example.com", nama="Mahasiswa Uji", sandi="kata-sandi-panjang"):
    r = klien.post("/api/v1/auth/register", json={"nama": nama, "email": email, "kata_sandi": sandi})
    assert r.status_code == 201, r.text
    return r.json()["data"]


def kepala(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}
