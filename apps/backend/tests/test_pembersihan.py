"""Pembersihan otomatis: dokumen lampiran chat dan butir memori yang tak terpakai."""

import uuid
from datetime import UTC, datetime, timedelta

from app.core.config import Settings
from app.models import DokumenPengguna, MemoriPengguna, Pengguna
from app.services import pembersihan
from tests.conftest import SETTINGS_UJI
from tests.test_integrasi_db import sesi  # noqa: F401 (fixture)


def _pengguna(sesi) -> Pengguna:
    p = Pengguna(email=f"{uuid.uuid4().hex[:8]}@contoh.id", kata_sandi="x", nama="Uji")
    sesi.add(p)
    sesi.flush()
    return p


def _dok(sesi, p, tmp_path, asal, umur_hari, ukuran=10, terpakai_hari=None):
    f = tmp_path / f"{uuid.uuid4().hex}.bin"
    f.write_bytes(b"x" * ukuran)
    d = DokumenPengguna(
        pengguna_id=p.id,
        jenis="cv",
        nama_berkas="a.pdf",
        lokasi_penyimpanan=str(f),
        asal=asal,
        tanggal_unggah=datetime.now(UTC) - timedelta(days=umur_hari),
        terakhir_dipakai=None if terpakai_hari is None else datetime.now(UTC) - timedelta(days=terpakai_hari),
    )
    sesi.add(d)
    sesi.flush()
    return d, f


def test_lampiran_chat_lama_dihapus_tetapi_dokumen_profil_tidak(sesi, tmp_path):
    p = _pengguna(sesi)
    lama_chat, f1 = _dok(sesi, p, tmp_path, "chat", umur_hari=45)
    lama_profil, f2 = _dok(sesi, p, tmp_path, "profil", umur_hari=400)
    baru_chat, f3 = _dok(sesi, p, tmp_path, "chat", umur_hari=2)
    dipakai_lagi, f4 = _dok(sesi, p, tmp_path, "chat", umur_hari=90, terpakai_hari=3)
    n = pembersihan.bersihkan_dokumen(sesi, SETTINGS_UJI, p)
    assert n == 1
    assert not f1.exists() and f2.exists() and f3.exists() and f4.exists()


def test_penuh_menghapus_lampiran_chat_terlama_sampai_di_bawah_target(sesi, tmp_path):
    p = _pengguna(sesi)
    kecil = Settings(**{**SETTINGS_UJI.model_dump(), "upload_total_maks_byte": 100})
    profil, fp = _dok(sesi, p, tmp_path, "profil", umur_hari=100, ukuran=40)
    a, fa = _dok(sesi, p, tmp_path, "chat", umur_hari=20, ukuran=30)  # lebih lama
    b, fb = _dok(sesi, p, tmp_path, "chat", umur_hari=10, ukuran=30)
    c, fc = _dok(sesi, p, tmp_path, "chat", umur_hari=3, ukuran=5)  # terlalu baru untuk dihapus walau penuh
    n = pembersihan.bersihkan_dokumen(sesi, kecil, p)  # 105 > 80% dari 100
    assert n >= 1 and not fa.exists()
    assert fp.exists() and fc.exists()
    r = pembersihan.ringkasan_penyimpanan(sesi, kecil, p)
    assert r["dokumen_profil"] == 1 and r["terpakai_byte"] <= 100


def test_memori_hanya_butir_otomatis_nonaktif_yang_lama(sesi):
    p = _pengguna(sesi)
    now = datetime.now(UTC)

    def butir(sumber, aktif, hari, dipakai=None):
        m = MemoriPengguna(pengguna_id=p.id, jenis="minat", isi=f"b{hari}{sumber}{aktif}", sumber=sumber, aktif=aktif)
        sesi.add(m)
        sesi.flush()
        m.dibuat_pada = now - timedelta(days=hari)
        m.terakhir_dipakai = None if dipakai is None else now - timedelta(days=dipakai)
        return m

    a = butir("chat", False, 60)  # otomatis, nonaktif, lama: dihapus
    b = butir("chat", True, 600)  # otomatis tetapi aktif: dipertahankan
    c = butir("manual", False, 600)  # ditulis sendiri: dipertahankan
    d = butir("chat", False, 60, dipakai=2)  # nonaktif tetapi baru dipakai: dipertahankan
    sesi.flush()
    assert pembersihan.bersihkan_memori(sesi, p, now) == 1
    sisa = {m.id for m in sesi.query(MemoriPengguna).filter_by(pengguna_id=p.id)}
    assert a.id not in sisa and {b.id, c.id, d.id} <= sisa


def test_batas_butir_otomatis_membuang_yang_paling_lama_tak_dipakai(sesi, monkeypatch):
    p = _pengguna(sesi)
    monkeypatch.setattr(pembersihan, "BATAS_OTOMATIS", 3)
    now = datetime.now(UTC)
    ms = []
    for i in range(5):
        m = MemoriPengguna(pengguna_id=p.id, jenis="minat", isi=f"x{i}", sumber="chat", aktif=True)
        sesi.add(m)
        sesi.flush()
        m.dibuat_pada = now - timedelta(days=10 - i)  # x0 paling lama
        ms.append(m)
    assert pembersihan.bersihkan_memori(sesi, p, now) == 2
    sisa = {m.isi for m in sesi.query(MemoriPengguna).filter_by(pengguna_id=p.id)}
    assert sisa == {"x2", "x3", "x4"}
