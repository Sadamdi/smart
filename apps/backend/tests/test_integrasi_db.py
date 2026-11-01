"""Uji ujung ke ujung memakai repositori SQL sungguhan pada basis data pengembangan atau uji.

Aman: setiap uji berjalan di dalam transaksi luar yang SELALU dibatalkan (rollback), sehingga tidak ada data tertinggal dan
tidak ada operasi hapus massal. Dilewati bila DATABASE_URL kosong atau APP_ENV=prod (termasuk di CI).
"""

import uuid
from datetime import date, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db import get_session
from app.main import app
from app.models import Beasiswa, BerkasWajib, Persyaratan, Sumber
from tests.conftest import SETTINGS_UJI, kepala

B = "/api/v1"
_S = get_settings()
pytestmark = pytest.mark.skipif(
    not _S.database_url or _S.app_env == "prod", reason="butuh DATABASE_URL pengembangan atau uji"
)


@pytest.fixture
def sesi():
    mesin = create_engine(_S.database_url, pool_pre_ping=True)
    koneksi = mesin.connect()
    luar = koneksi.begin()
    sesi = Session(bind=koneksi, join_transaction_mode="create_savepoint", expire_on_commit=False)
    yield sesi
    sesi.close()
    luar.rollback()  # tidak ada yang tersimpan
    koneksi.close()
    mesin.dispose()


@pytest.fixture
def klien_db(sesi):
    app.dependency_overrides[get_session] = lambda: sesi
    app.dependency_overrides[get_settings] = lambda: SETTINGS_UJI
    from app.core.ratelimit import pembatas_login

    pembatas_login._gagal.clear()
    yield TestClient(app)
    app.dependency_overrides.clear()


def _daftar(klien, email):
    r = klien.post(
        f"{B}/auth/register",
        json={"nama": "Uji Integrasi", "email": email, "kata_sandi": "kata-sandi-panjang"},
    )
    assert r.status_code == 201, r.text
    return r.json()["data"]


def test_alur_akun_lengkap_pada_basis_data_sungguhan(klien_db):
    email = f"uji-{uuid.uuid4().hex[:8]}@example.com"
    data = _daftar(klien_db, email)
    h = kepala(data["token_akses"])
    assert (
        klien_db.post(
            f"{B}/auth/register",
            json={"nama": "X", "email": email.upper(), "kata_sandi": "kata-sandi-panjang"},
        ).status_code
        == 409
    )
    assert klien_db.get(f"{B}/me", headers=h).json()["data"]["email"] == email
    r = klien_db.put(
        f"{B}/me/profil",
        headers=h,
        json={"kampus": "UIN Malang", "jenjang": "S1", "semester": 5, "ipk": "3.60", "minat": ["data"]},
    )
    assert r.status_code == 200 and r.json()["data"]["ipk"] == "3.60"
    assert (
        klien_db.post(
            f"{B}/auth/login", json={"email": email, "kata_sandi": "kata-sandi-panjang"}
        ).status_code
        == 200
    )
    # logout mencabut token (versi_token naik di basis data)
    assert klien_db.post(f"{B}/auth/logout", headers=h).status_code == 200
    assert klien_db.get(f"{B}/me", headers=h).status_code == 401
    baru = klien_db.post(f"{B}/auth/login", json={"email": email, "kata_sandi": "kata-sandi-panjang"}).json()[
        "data"
    ]
    assert klien_db.delete(f"{B}/me", headers=kepala(baru["token_akses"])).status_code == 200
    assert klien_db.get(f"{B}/me", headers=kepala(baru["token_akses"])).status_code == 401


def test_dua_pengguna_tidak_saling_melihat_data(klien_db):
    a = _daftar(klien_db, f"a-{uuid.uuid4().hex[:8]}@example.com")
    b = _daftar(klien_db, f"b-{uuid.uuid4().hex[:8]}@example.com")
    klien_db.put(f"{B}/me/profil", headers=kepala(a["token_akses"]), json={"kampus": "Kampus A"})
    assert klien_db.get(f"{B}/me", headers=kepala(b["token_akses"])).json()["data"]["kampus"] is None
    assert klien_db.get(f"{B}/me", headers=kepala(a["token_akses"])).json()["data"]["kampus"] == "Kampus A"


def test_daftar_dan_detail_beasiswa_sungguhan(klien_db, sesi):
    sumber = Sumber(
        id=uuid.uuid4(),
        nama="Sumber Uji",
        url=f"https://uji.example/{uuid.uuid4().hex}",
        jenis="input_manual",
    )
    sesi.add(sumber)
    sesi.flush()
    hari_ini = date.today()
    terbit = Beasiswa(
        id=uuid.uuid4(),
        sumber_id=sumber.id,
        nama="Beasiswa Uji Terbit",
        penyelenggara="Uji",
        negara="Indonesia",
        jenjang=["S1", "S2"],
        tenggat=hari_ini + timedelta(days=30),
        tautan_resmi="https://uji.example/terbit",
        status="terbit",
    )
    sesi.add_all(
        [
            terbit,
            Beasiswa(
                id=uuid.uuid4(),
                sumber_id=sumber.id,
                nama="Beasiswa Uji Tertunda",
                tenggat=hari_ini + timedelta(days=30),
                tautan_resmi="https://uji.example/x",
                status="menunggu_validasi",
            ),
            Beasiswa(
                id=uuid.uuid4(),
                sumber_id=sumber.id,
                nama="Beasiswa Uji Lewat",
                tenggat=hari_ini - timedelta(days=1),
                tautan_resmi="https://uji.example/y",
                status="terbit",
            ),
        ]
    )
    sesi.flush()
    sesi.add_all(
        [
            Persyaratan(
                id=uuid.uuid4(),
                beasiswa_id=terbit.id,
                jenis="ipk_minimum",
                nilai_batas={"nilai": 3.5},
                dapat_dikejar=True,
            ),
            BerkasWajib(id=uuid.uuid4(), beasiswa_id=terbit.id, nama_berkas="Transkrip nilai"),
        ]
    )
    sesi.flush()
    h = kepala(_daftar(klien_db, f"c-{uuid.uuid4().hex[:8]}@example.com")["token_akses"])
    daftar = klien_db.get(f"{B}/beasiswa?q=Beasiswa Uji&jenjang=S2", headers=h).json()["data"]
    assert [x["nama"] for x in daftar] == ["Beasiswa Uji Terbit"]
    detail = klien_db.get(f"{B}/beasiswa/{terbit.id}", headers=h).json()["data"]
    assert (
        detail["persyaratan"][0]["jenis"] == "ipk_minimum"
        and detail["berkas_wajib"][0]["nama_berkas"] == "Transkrip nilai"
    )
    assert klien_db.get(f"{B}/beasiswa?q=Tertunda", headers=h).json()["data"] == []


def test_kolom_versi_token_ada_di_basis_data(sesi):
    ada = sesi.execute(
        text(
            "select 1 from information_schema.columns where table_name='pengguna' and column_name='versi_token'"
        )
    ).scalar()
    assert ada == 1
