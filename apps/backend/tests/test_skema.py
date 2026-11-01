"""Pemeriksaan skema tanpa basis data: model, migrasi, dan dokumen harus sama (13 tabel)."""

import os
import re
import subprocess
import sys

from app.models import TABEL_SMART, Base

BACKEND = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def test_model_memuat_13_tabel_sesuai_dokumen():
    assert set(Base.metadata.tables) == set(TABEL_SMART)
    assert len(TABEL_SMART) == 13


def test_kolom_inti_ada():
    t = Base.metadata.tables
    assert {
        "email",
        "kata_sandi",
        "peran",
        "ipk",
        "semester",
        "vektor_profil",
        "penghasilan_orang_tua",
        "skor_bahasa",
        "kewarganegaraan",
    } <= set(t["pengguna"].columns.keys())
    assert {"sidik_isi", "vektor", "tautan_resmi", "tenggat", "status"} <= set(t["beasiswa"].columns.keys())
    assert {"skor", "kategori", "alasan", "catatan_kekurangan"} <= set(t["rekomendasi"].columns.keys())


def test_migrasi_offline_membuat_semua_tabel_dan_ekstensi_vector():
    env = {
        **os.environ,
        "DATABASE_URL": "postgresql+psycopg://u:p@db.contoh.supabase.co:5432/postgres",
        "APP_ENV": "dev",
    }
    hasil = subprocess.run(  # noqa: S603
        [sys.executable, "-m", "alembic", "upgrade", "head", "--sql"],
        cwd=BACKEND,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    sql = hasil.stdout
    dibuat = set(re.findall(r"CREATE TABLE (\w+)", sql)) - {"alembic_version"}
    assert dibuat == set(TABEL_SMART)
    assert "CREATE EXTENSION IF NOT EXISTS vector" in sql
    assert "USING hnsw" in sql
    assert "uq_notifikasi_pengingat" in sql  # pengingat tidak boleh ganda
