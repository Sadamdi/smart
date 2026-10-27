import pytest

from app.core.config import Settings
from app.core.safety import DestructiveOperationRefused, pastikan_boleh_hapus

URL_DEV = "postgresql+psycopg://u:p@db.devref.supabase.co:5432/postgres"
URL_PROD = "postgresql+psycopg://u:p@db.prodref.supabase.co:5432/postgres"


def _s(**kw):
    return Settings(_env_file=None, **kw)


def test_ditolak_di_prod_walau_host_ada_di_daftar_putih():
    s = _s(app_env="prod", database_url=URL_DEV, destructive_db_hosts=["db.devref.supabase.co"])
    with pytest.raises(DestructiveOperationRefused):
        pastikan_boleh_hapus(s)


def test_ditolak_bila_daftar_putih_kosong():
    s = _s(app_env="test", database_url=URL_DEV, destructive_db_hosts=[])
    with pytest.raises(DestructiveOperationRefused):
        pastikan_boleh_hapus(s)


def test_ditolak_bila_host_di_luar_daftar_putih():
    s = _s(app_env="test", database_url=URL_PROD, destructive_db_hosts=["db.devref.supabase.co"])
    with pytest.raises(DestructiveOperationRefused):
        pastikan_boleh_hapus(s)


def test_ditolak_tanpa_database_url():
    s = _s(app_env="test", database_url=None, destructive_db_hosts=["db.devref.supabase.co"])
    with pytest.raises(DestructiveOperationRefused):
        pastikan_boleh_hapus(s)


def test_diizinkan_untuk_host_di_daftar_putih_pada_env_test():
    s = _s(app_env="test", database_url=URL_DEV, destructive_db_hosts=["DB.devref.supabase.co"])
    pastikan_boleh_hapus(s)


def test_daftar_putih_dari_string_dipisah_koma():
    s = _s(
        app_env="test",
        database_url=URL_DEV,
        destructive_db_hosts="db.devref.supabase.co, db.lain.supabase.co",
    )
    assert s.destructive_db_hosts == ["db.devref.supabase.co", "db.lain.supabase.co"]


def test_pooler_bersama_dibedakan_lewat_nama_pengguna():
    pooler = "aws-0-ap-southeast-1.pooler.supabase.com"
    dev = f"postgresql+psycopg://postgres.devref:p@{pooler}:5432/postgres"
    prod = f"postgresql+psycopg://postgres.prodref:p@{pooler}:5432/postgres"
    izin = [f"postgres.devref@{pooler}"]
    pastikan_boleh_hapus(_s(app_env="dev", database_url=dev, destructive_db_hosts=izin))
    with pytest.raises(DestructiveOperationRefused):
        pastikan_boleh_hapus(_s(app_env="dev", database_url=prod, destructive_db_hosts=izin))
