"""Chatbot dengan lampiran dokumen, memori pengguna, enkripsi berkas, penyamaran data, dan alat laman resmi."""

import uuid
from datetime import timedelta
from pathlib import Path

import pytest

from app.core.config import Settings, get_settings
from app.main import app
from app.services import internet
from app.services.privasi import samarkan
from tests.conftest import SETTINGS_UJI
from tests.test_integrasi_db import B, klien_db, sesi  # noqa: F401 (fixture)
from tests.test_integrasi_modul import HARI, _akun, _beasiswa, _sumber

_S = get_settings()

CV = (
    "Nabila Putri\nsurel nabila.putri@contoh.id telepon 0812-3456-7890 NIM 240605110078\n"
    "IPK 3,72 semester 5 TOEFL 520\nKetua BEM Fakultas Sains dan Teknologi 2025\nJuara 2 Hackathon Nasional 2025\n"
)


def test_samarkan_menyembunyikan_data_pribadi_tetapi_menjaga_isi_analisis():
    hasil = samarkan(CV, "Nabila Putri")
    assert "nabila.putri@contoh.id" not in hasil and "0812" not in hasil and "240605110078" not in hasil
    assert "[surel]" in hasil and "[telepon]" in hasil and "[nomor identitas]" in hasil
    assert "Nabila" not in hasil and "Ketua BEM" in hasil and "Hackathon" in hasil


def test_alamat_laman_resmi_hanya_https_ke_host_publik():
    assert not internet.alamat_aman("http://contoh.id/x")
    assert not internet.alamat_aman("https://127.0.0.1/x")
    assert not internet.alamat_aman("https://10.0.0.5/x")
    assert not internet.alamat_aman("https://169.254.169.254/latest/meta-data")
    assert internet.bersihkan_html("<script>x()</script><p>Syarat &amp; tenggat</p>") == "Syarat tenggat"


pytestmark = pytest.mark.skipif(
    not _S.database_url or _S.app_env == "prod", reason="butuh DATABASE_URL pengembangan atau uji"
)


def _unggah(klien, h, nama, isi):
    from tests.test_integrasi_modul import B as _B

    r = klien.post(f"{_B}/me/dokumen", headers=h, data={"jenis": "cv"}, files={"berkas": (nama, isi, "text/plain")})
    assert r.status_code == 201, r.text
    return r.json()["data"]


def test_berkas_terenkripsi_di_disk_dan_memori_terisi(klien_db, tmp_path):
    app.dependency_overrides[get_settings] = lambda: Settings(**{**SETTINGS_UJI.model_dump(), "upload_dir": str(tmp_path)})
    try:
        h = _akun(klien_db)
        d = _unggah(klien_db, h, "cv.txt", CV.encode())
        berkas = [p for p in Path(tmp_path).rglob("*") if p.is_file()]
        assert berkas and all(b.read_bytes().startswith(b"SM1") for b in berkas)  # tidak ada teks mentah di disk
        asli = klien_db.get(f"{B}/me/dokumen/{d['id']}/berkas", headers=h)
        assert asli.status_code == 200 and asli.content == CV.encode()
        memori = klien_db.get(f"{B}/me/memori", headers=h).json()["data"]
        assert any("BEM" in m["isi"] for m in memori), memori
        satu = memori[0]["id"]
        assert klien_db.delete(f"{B}/me/memori/{satu}", headers=h).status_code == 200
        assert len(klien_db.get(f"{B}/me/memori", headers=h).json()["data"]) == len(memori) - 1
        assert klien_db.delete(f"{B}/me/memori", headers=h).status_code == 200
        assert klien_db.get(f"{B}/me/memori", headers=h).json()["data"] == []
        klien_db.delete(f"{B}/me/dokumen/{d['id']}", headers=h)
        assert not [p for p in Path(tmp_path).rglob("*") if p.is_file()]  # berkas dan teksnya ikut terhapus
    finally:
        app.dependency_overrides[get_settings] = lambda: SETTINGS_UJI


def test_chat_memakai_lampiran_memori_dan_data_tersamarkan(klien_db, sesi, tmp_path, monkeypatch):
    app.dependency_overrides[get_settings] = lambda: Settings(**{**SETTINGS_UJI.model_dump(), "upload_dir": str(tmp_path)})
    try:
        h = _akun(klien_db)
        klien_db.put(
            f"{B}/me/profil", headers=h, json={"nama": "Nabila Putri", "jenjang": "S1", "semester": 5, "ipk": "3.72"}
        )
        d = _unggah(klien_db, h, "cv.txt", CV.encode())
        s = _sumber(sesi)
        _beasiswa(sesi, s, "Beasiswa Kepemimpinan Uji", HARI + timedelta(days=30))
        tertangkap: dict = {}

        def palsu(settings, sistem, pesan, **kw):
            tertangkap["sistem"], tertangkap["pesan"] = sistem, pesan
            return "**Kekuatan**: memimpin BEM.\n\nSumber: dokumen cv.txt"

        monkeypatch.setattr("app.services.llm.tanya", palsu)
        r = klien_db.post(
            f"{B}/chat", headers=h, json={"pesan": "Nilai CV saya untuk Beasiswa Kepemimpinan Uji", "dokumen_ids": [d["id"]]}
        )
        assert r.status_code == 200, r.text
        prompt = tertangkap["pesan"]
        assert "Ketua BEM" in prompt and "Hackathon" in prompt  # isi dokumen sampai ke AI
        assert (
            "nabila.putri@contoh.id" not in prompt and "0812" not in prompt and "Nabila" not in prompt
        )  # data pribadi disamarkan
        assert "Memori tentang pengguna" in prompt and "Beasiswa Kepemimpinan Uji" in prompt
        assert "markdown" in tertangkap["sistem"] and "Sumber:" in tertangkap["sistem"]
        # dokumen milik orang lain tidak boleh dilampirkan
        lain = _akun(klien_db, "x")
        assert klien_db.post(f"{B}/chat", headers=lain, json={"pesan": "halo", "dokumen_ids": [d["id"]]}).status_code == 422
        assert (
            klien_db.post(f"{B}/chat", headers=h, json={"pesan": "halo", "dokumen_ids": [str(uuid.uuid4())]}).status_code
            == 422
        )
        # stream melaporkan sumber data
        monkeypatch.setattr("app.services.llm.tanya_stream", lambda *a, **k: iter(["ok"]))
        st = klien_db.post(f"{B}/chat/stream", headers=h, json={"pesan": "halo", "dokumen_ids": [d["id"]]})
        assert "dokumen cv.txt" in st.text
    finally:
        app.dependency_overrides[get_settings] = lambda: SETTINGS_UJI


def test_saklar_memori_ubah_butir_dan_statistik(klien_db, sesi, tmp_path, monkeypatch):
    app.dependency_overrides[get_settings] = lambda: Settings(**{**SETTINGS_UJI.model_dump(), "upload_dir": str(tmp_path)})
    try:
        h = _akun(klien_db)
        _unggah(klien_db, h, "cv.txt", CV.encode())
        butir = klien_db.get(f"{B}/me/memori", headers=h).json()["data"]
        assert butir and all(b["aktif"] for b in butir)
        st = klien_db.get(f"{B}/me/memori/statistik", headers=h).json()["data"]
        assert st["jumlah"] == st["jumlah_dipakai"] == len(butir) and st["perkiraan_token"] > 0
        # matikan satu butir: tidak dipakai dan beban turun
        satu = butir[0]
        ub = klien_db.patch(f"{B}/me/memori/{satu['id']}", headers=h, json={"aktif": False, "isi": "Isi sudah disunting"})
        assert (
            ub.status_code == 200
            and ub.json()["data"]["aktif"] is False
            and ub.json()["data"]["isi"] == "Isi sudah disunting"
        )
        st2 = klien_db.get(f"{B}/me/memori/statistik", headers=h).json()["data"]
        assert st2["jumlah_dipakai"] == st["jumlah"] - 1 and st2["perkiraan_token"] < st["perkiraan_token"]
        # saklar utama mati: tidak ada memori yang dikirim ke AI
        tertangkap: dict = {}
        monkeypatch.setattr("app.services.llm.tanya", lambda s, sis, pesan, **k: tertangkap.setdefault("p", pesan) or "ok")
        klien_db.put(f"{B}/me/memori/pengaturan", headers=h, json={"aktif": False})
        klien_db.post(f"{B}/chat", headers=h, json={"pesan": "halo"})
        assert "Memori tentang pengguna" not in tertangkap["p"]
        assert klien_db.get(f"{B}/me/memori/statistik", headers=h).json()["data"]["jumlah_dipakai"] == 0
    finally:
        app.dependency_overrides[get_settings] = lambda: SETTINGS_UJI


def test_riwayat_chat_statistik_ekspor_impor_dan_hapus_satu(klien_db, monkeypatch):
    h = _akun(klien_db)
    monkeypatch.setattr("app.services.llm.tanya", lambda *a, **k: "jawaban")
    for t in ("satu", "dua"):
        assert klien_db.post(f"{B}/chat", headers=h, json={"pesan": t}).status_code == 200
    st = klien_db.get(f"{B}/chat/statistik", headers=h).json()["data"]
    assert st["jumlah"] == 2 and st["tujuh_hari"] == 2 and st["terakhir"] is not None
    cadangan = klien_db.get(f"{B}/chat/ekspor", headers=h).json()["data"]
    assert sorted(c["pesan"] for c in cadangan) == ["dua", "satu"]  # waktu sama dalam satu transaksi uji
    riwayat = klien_db.get(f"{B}/chat/riwayat", headers=h).json()["data"]
    assert klien_db.delete(f"{B}/chat/riwayat/{riwayat[0]['id']}", headers=h).status_code == 200
    assert len(klien_db.get(f"{B}/chat/riwayat", headers=h).json()["data"]) == 1
    klien_db.delete(f"{B}/chat/riwayat", headers=h)
    pulih = klien_db.post(f"{B}/chat/impor", headers=h, json={"butir": cadangan}).json()["data"]
    assert pulih["dipulihkan"] == 2
    assert (
        klien_db.post(f"{B}/chat/impor", headers=h, json={"butir": cadangan}).json()["data"]["dipulihkan"] == 0
    )  # tidak ganda
    assert len(klien_db.get(f"{B}/chat/riwayat", headers=h).json()["data"]) == 2
    assert klien_db.delete(f"{B}/chat/riwayat/{uuid.uuid4()}", headers=h).status_code == 404
