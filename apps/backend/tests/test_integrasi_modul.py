"""Uji ujung ke ujung modul admin, rekomendasi, dokumen, interaksi, kalender, notifikasi, dan chatbot.

Memakai basis data sungguhan dalam transaksi luar yang selalu dibatalkan (lihat test_integrasi_db.py).
"""

import uuid
from datetime import date, timedelta

import pytest
from sqlalchemy import update

from app.core.config import Settings, get_settings
from app.core.errors import UpstreamUnavailable
from app.models import Beasiswa, BerkasWajib, Pengguna, Persyaratan, Sumber
from tests.conftest import SETTINGS_UJI, kepala
from tests.test_integrasi_db import B, _daftar, klien_db, sesi  # noqa: F401 (fixture)

_S = get_settings()
pytestmark = [
    pytest.mark.usefixtures("klien_db"),
    pytest.mark.skipif(not _S.database_url or _S.app_env == "prod", reason="butuh DATABASE_URL pengembangan atau uji"),
]

HARI = date.today()


def _akun(klien, awalan="m"):
    return kepala(_daftar(klien, f"{awalan}-{uuid.uuid4().hex[:8]}@example.com")["token_akses"])


def _admin(klien, sesi):
    email = f"admin-{uuid.uuid4().hex[:8]}@example.com"
    _daftar(klien, email)
    sesi.execute(update(Pengguna).where(Pengguna.email == email).values(peran="admin"))
    sesi.flush()
    token = klien.post(f"{B}/auth/login", json={"email": email, "kata_sandi": "kata-sandi-panjang"}).json()["data"]
    return kepala(token["token_akses"])


def _sumber(sesi):
    s = Sumber(id=uuid.uuid4(), nama="Sumber Uji", url=f"https://uji.example/{uuid.uuid4().hex}", jenis="input_manual")
    sesi.add(s)
    sesi.flush()
    return s


def _beasiswa(sesi, sumber, nama, tenggat=None, status="terbit", syarat=(), berkas=(), **kw):
    b = Beasiswa(
        id=uuid.uuid4(),
        sumber_id=sumber.id,
        nama=nama,
        penyelenggara="Penyelenggara Uji",
        jenjang=["S1"],
        tenggat=tenggat,
        tautan_resmi="https://uji.example/" + uuid.uuid4().hex,
        status=status,
        **kw,
    )
    sesi.add(b)
    sesi.flush()
    for jenis, batas in syarat:
        sesi.add(Persyaratan(beasiswa_id=b.id, jenis=jenis, nilai_batas=batas))
    for nama_berkas in berkas:
        sesi.add(BerkasWajib(beasiswa_id=b.id, nama_berkas=nama_berkas))
    sesi.flush()
    return b


# ---------- admin ----------


def test_mahasiswa_tidak_boleh_mengakses_admin(klien_db):
    h = _akun(klien_db)
    assert klien_db.get(f"{B}/admin/antrean-validasi", headers=h).status_code == 403
    assert klien_db.get(f"{B}/admin/laporan").status_code == 401


def test_alur_validasi_admin_sampai_terbit_dan_terlihat_mahasiswa(klien_db, sesi):
    admin, mhs = _admin(klien_db, sesi), _akun(klien_db)
    b = _beasiswa(
        sesi, _sumber(sesi), "Beasiswa Menunggu Admin", status="menunggu_validasi", alasan_ditandai="tenggat kosong"
    )
    antre = klien_db.get(f"{B}/admin/antrean-validasi", headers=admin).json()["data"]
    assert any(x["id"] == str(b.id) and x["alasan_ditandai"] == "tenggat kosong" for x in antre)
    # tanpa tenggat tidak boleh terbit
    assert klien_db.post(f"{B}/admin/beasiswa/{b.id}/terbitkan", headers=admin).status_code == 422
    # tenggat kurang dari tiga hari ditolak
    klien_db.put(f"{B}/admin/beasiswa/{b.id}", headers=admin, json={"tenggat": str(HARI + timedelta(days=1))})
    assert klien_db.post(f"{B}/admin/beasiswa/{b.id}/terbitkan", headers=admin).status_code == 422
    r = klien_db.put(
        f"{B}/admin/beasiswa/{b.id}",
        headers=admin,
        json={
            "tenggat": str(HARI + timedelta(days=20)),
            "persyaratan": [{"jenis": "ipk_minimum", "nilai_batas": {"nilai": 3.0}, "dapat_dikejar": True}],
            "berkas_wajib": ["Transkrip nilai"],
        },
    )
    assert r.status_code == 200 and r.json()["data"]["berkas_wajib"][0]["nama_berkas"] == "Transkrip nilai"
    assert klien_db.get(f"{B}/beasiswa/{b.id}", headers=mhs).status_code == 404  # belum terbit
    t = klien_db.post(f"{B}/admin/beasiswa/{b.id}/terbitkan", headers=admin)
    assert t.status_code == 200 and t.json()["data"]["status"] == "terbit"
    assert klien_db.get(f"{B}/beasiswa/{b.id}", headers=mhs).status_code == 200
    assert klien_db.post(f"{B}/admin/beasiswa/{b.id}/terbitkan", headers=admin).status_code == 409


def test_admin_menolak_dan_input_manual_dan_sumber(klien_db, sesi):
    admin = _admin(klien_db, sesi)
    _akun(klien_db)
    b = _beasiswa(sesi, _sumber(sesi), "Beasiswa Ditolak", status="menunggu_validasi")
    r = klien_db.post(f"{B}/admin/beasiswa/{b.id}/tolak", headers=admin, json={"alasan": "bukan beasiswa"})
    assert r.json()["data"]["status"] == "ditolak"
    m = klien_db.post(
        f"{B}/admin/beasiswa",
        headers=admin,
        json={
            "nama": "Beasiswa Manual Uji",
            "tautan_resmi": "https://uji.example/manual",
            "tenggat": str(HARI + timedelta(days=30)),
        },
    )
    assert m.status_code == 201 and m.json()["data"]["status"] == "menunggu_validasi"
    nama = f"Sumber Baru {uuid.uuid4().hex[:6]}"
    s = klien_db.post(
        f"{B}/admin/sumber",
        headers=admin,
        json={"nama": nama, "url": f"https://baru.example/{uuid.uuid4().hex}", "jenis": "pantau_otomatis"},
    )
    assert s.status_code == 201
    u = klien_db.put(f"{B}/admin/sumber/{s.json()['data']['id']}", headers=admin, json={"aktif": False})
    assert u.json()["data"]["aktif"] is False
    assert any(x["nama"] == nama for x in klien_db.get(f"{B}/admin/sumber", headers=admin).json()["data"])
    lap = klien_db.get(f"{B}/admin/laporan", headers=admin).json()["data"]
    assert lap["beasiswa_per_status"]["ditolak"] >= 1 and lap["jumlah_mahasiswa"] >= 1


# ---------- rekomendasi ----------


def test_rekomendasi_per_kategori_dengan_alasan_dan_catatan(klien_db, sesi):
    h = _akun(klien_db)
    klien_db.put(
        f"{B}/me/profil",
        headers=h,
        json={
            "jenjang": "S1",
            "semester": 5,
            "ipk": "3.50",
            "jenis_kampus": "negeri",
            "program_studi": "Teknik Informatika",
            "minat": ["teknologi"],
        },
    )
    s = _sumber(sesi)
    ok = _beasiswa(
        sesi,
        s,
        "Beasiswa Teknologi Uji",
        HARI + timedelta(days=30),
        syarat=[("ipk_minimum", {"nilai": 3.0}), ("jenjang", {"nilai": ["S1"]})],
        manfaat="teknologi informatika",
    )
    hampir = _beasiswa(
        sesi, s, "Beasiswa Prestasi Uji", HARI + timedelta(days=30), syarat=[("ipk_minimum", {"nilai": 3.65})]
    )
    belum = _beasiswa(sesi, s, "Beasiswa Magister Uji", HARI + timedelta(days=30), syarat=[("jenjang", {"nilai": ["S2"]})])
    data = klien_db.get(f"{B}/rekomendasi", headers=h).json()["data"]
    kategori = {x["beasiswa"]["id"]: x for x in data}
    assert kategori[str(ok.id)]["kategori"] == "memenuhi" and kategori[str(ok.id)]["alasan"]
    assert kategori[str(hampir.id)]["kategori"] == "hampir_memenuhi"
    assert any("IPK kurang" in c for c in kategori[str(hampir.id)]["catatan_kekurangan"])
    assert kategori[str(belum.id)]["kategori"] == "belum_memenuhi"
    urutan = [x["kategori"] for x in data]
    assert urutan == sorted(urutan, key=["memenuhi", "hampir_memenuhi", "belum_memenuhi"].index)
    assert all("skor" not in x for x in data)  # tidak ada persen peluang
    only = klien_db.get(f"{B}/rekomendasi?kategori=memenuhi", headers=h).json()["data"]
    assert only and all(x["kategori"] == "memenuhi" for x in only)
    ring = klien_db.get(f"{B}/rekomendasi/ringkasan", headers=h).json()["data"]
    assert ring["memenuhi"] >= 1 and ring["hampir_memenuhi"] >= 1 and ring["belum_memenuhi"] >= 1
    # profil berubah lalu hitung ulang: IPK naik, beasiswa prestasi kini memenuhi
    klien_db.put(f"{B}/me/profil", headers=h, json={"ipk": "3.80"})
    r = klien_db.post(f"{B}/rekomendasi/hitung-ulang", headers=h).json()["data"]
    assert {x["beasiswa"]["id"]: x["kategori"] for x in r}[str(hampir.id)] == "memenuhi"


def test_rekomendasi_tidak_memuat_beasiswa_tertunda_atau_lewat(klien_db, sesi):
    h = _akun(klien_db)
    s = _sumber(sesi)
    tunda = _beasiswa(sesi, s, "Tertunda", HARI + timedelta(days=30), status="menunggu_validasi")
    lewat = _beasiswa(sesi, s, "Lewat", HARI - timedelta(days=2))
    ids = {x["beasiswa"]["id"] for x in klien_db.get(f"{B}/rekomendasi", headers=h).json()["data"]}
    assert str(tunda.id) not in ids and str(lewat.id) not in ids


# ---------- dokumen ----------


def test_unggah_cv_dibaca_dikoreksi_dan_diterapkan_ke_profil(klien_db, tmp_path):
    from app.core.config import get_settings
    from app.main import app

    app.dependency_overrides[get_settings] = lambda: Settings(**{**SETTINGS_UJI.model_dump(), "upload_dir": str(tmp_path)})
    h = _akun(klien_db)
    cv = "Nama: Uji\nIPK 3,80 dari 4,00\nSemester 5\nTOEFL ITP 520\nKetua BEM Fakultas Sains\n"
    r = klien_db.post(
        f"{B}/me/dokumen", headers=h, data={"jenis": "cv"}, files={"berkas": ("cv.txt", cv.encode(), "text/plain")}
    )
    assert r.status_code == 201, r.text
    d = r.json()["data"]
    assert (
        d["status_baca"] == "selesai"
        and d["hasil_baca"]["ipk"] == 3.8
        and d["hasil_baca"]["skor_bahasa"] == {"toefl": 520.0}
    )
    assert d["hasil_baca"]["semester"] == 5 and d["hasil_baca"]["pengalaman_organisasi"]
    kor = klien_db.put(
        f"{B}/me/dokumen/{d['id']}/hasil-baca", headers=h, json={"hasil_baca": {**d["hasil_baca"], "ipk": 3.7}}
    )
    assert kor.json()["data"]["hasil_baca"]["ipk"] == 3.7
    t = klien_db.post(f"{B}/me/dokumen/{d['id']}/terapkan-ke-profil", headers=h).json()["data"]
    assert set(t["kolom_terisi"]) == {"ipk", "semester", "skor_bahasa", "profil_lanjutan.organisasi"}
    assert klien_db.get(f"{B}/me", headers=h).json()["data"]["ipk"] == "3.70"
    assert len(klien_db.get(f"{B}/me/dokumen", headers=h).json()["data"]) == 1
    assert klien_db.delete(f"{B}/me/dokumen/{d['id']}", headers=h).status_code == 200
    assert klien_db.get(f"{B}/me/dokumen/{d['id']}", headers=h).status_code == 404
    app.dependency_overrides[get_settings] = lambda: SETTINGS_UJI


def test_unggah_menolak_tipe_ukuran_dan_isolasi_pengguna(klien_db, tmp_path):
    from app.core.config import get_settings
    from app.main import app

    app.dependency_overrides[get_settings] = lambda: Settings(
        **{**SETTINGS_UJI.model_dump(), "upload_dir": str(tmp_path), "upload_maks_byte": 100}
    )
    a, b = _akun(klien_db, "a"), _akun(klien_db, "b")
    assert (
        klien_db.post(
            f"{B}/me/dokumen", headers=a, data={"jenis": "cv"}, files={"berkas": ("x.exe", b"MZ", "application/x")}
        ).status_code
        == 422
    )
    assert (
        klien_db.post(
            f"{B}/me/dokumen", headers=a, data={"jenis": "cv"}, files={"berkas": ("x.txt", b"a" * 200, "text/plain")}
        ).status_code
        == 422
    )
    ok = klien_db.post(
        f"{B}/me/dokumen", headers=a, data={"jenis": "cv"}, files={"berkas": ("x.txt", b"IPK 3,5", "text/plain")}
    ).json()["data"]
    assert klien_db.get(f"{B}/me/dokumen/{ok['id']}", headers=b).status_code == 404
    assert klien_db.get(f"{B}/me/dokumen", headers=b).json()["data"] == []
    app.dependency_overrides[get_settings] = lambda: SETTINGS_UJI


# ---------- interaksi, checklist, kalender, notifikasi ----------


def test_simpan_checklist_kalender_tugas_dan_notifikasi(klien_db, sesi):
    h = _akun(klien_db)
    b = _beasiswa(sesi, _sumber(sesi), "Beasiswa Simpan Uji", HARI + timedelta(days=5), berkas=["KTP", "Transkrip"])
    lain = _beasiswa(sesi, _sumber(sesi), "Beasiswa Jauh", HARI + timedelta(days=90), berkas=["Esai"])
    assert klien_db.post(f"{B}/beasiswa/{b.id}/interaksi", headers=h, json={"aksi": "rencana_daftar"}).status_code == 422
    assert klien_db.post(f"{B}/beasiswa/{b.id}/interaksi", headers=h, json={"aksi": "simpan"}).status_code == 201
    klien_db.post(f"{B}/beasiswa/{b.id}/interaksi", headers=h, json={"aksi": "simpan"})  # idempotent
    klien_db.post(
        f"{B}/beasiswa/{b.id}/interaksi", headers=h, json={"aksi": "rencana_daftar", "status_rencana": "akan_daftar"}
    )
    klien_db.post(f"{B}/beasiswa/{lain.id}/interaksi", headers=h, json={"aksi": "klik"})
    ter = klien_db.get(f"{B}/me/tersimpan", headers=h).json()["data"]
    assert [x["beasiswa"]["id"] for x in ter] == [str(b.id)] and ter[0]["status_rencana"] == "akan_daftar"
    cl = klien_db.get(f"{B}/me/checklist", headers=h).json()["data"]
    assert [x["nama_berkas"] for x in cl[0]["berkas"]] == ["KTP", "Transkrip"] and not any(
        x["selesai"] for x in cl[0]["berkas"]
    )
    ktp = cl[0]["berkas"][0]["id"]
    assert klien_db.put(f"{B}/me/checklist/{ktp}", headers=h, json={"selesai": True}).status_code == 200
    assert klien_db.get(f"{B}/me/checklist", headers=h).json()["data"][0]["berkas"][0]["selesai"] is True
    # berkas beasiswa yang tidak disimpan tidak dapat dicentang
    berkas_lain = sesi.query(BerkasWajib).filter_by(beasiswa_id=lain.id).one()
    assert klien_db.put(f"{B}/me/checklist/{berkas_lain.id}", headers=h, json={"selesai": True}).status_code == 404
    # tugas pribadi dan kalender
    t = klien_db.post(
        f"{B}/me/tugas", headers=h, json={"judul": "Minta surat rekomendasi", "tanggal": str(HARI + timedelta(days=2))}
    )
    assert t.status_code == 201
    kal = klien_db.get(f"{B}/me/kalender", headers=h).json()["data"]
    assert [a["jenis"] for a in kal] == ["tugas", "tenggat"]
    tid = t.json()["data"]["id"]
    assert klien_db.put(f"{B}/me/tugas/{tid}", headers=h, json={"selesai": True}).json()["data"]["selesai"] is True
    assert klien_db.get(f"{B}/me/kalender?dari={HARI}&sampai={HARI - timedelta(days=1)}", headers=h).status_code == 422
    # notifikasi tenggat muncul sekali, tidak ganda
    n1 = klien_db.get(f"{B}/notifikasi", headers=h).json()["data"]
    n2 = klien_db.get(f"{B}/notifikasi", headers=h).json()["data"]
    assert len(n1) == len(n2) == 1 and "5 hari lagi" in n1[0]["pesan"] and not n1[0]["dibaca"]
    assert klien_db.put(f"{B}/notifikasi/{n1[0]['id']}/baca", headers=h).status_code == 200
    assert klien_db.get(f"{B}/notifikasi", headers=h).json()["data"][0]["dibaca"] is True
    assert klien_db.put(f"{B}/notifikasi/baca-semua", headers=h).status_code == 200
    # batal simpan
    assert klien_db.delete(f"{B}/beasiswa/{b.id}/interaksi/simpan", headers=h).status_code == 200
    assert klien_db.get(f"{B}/me/tersimpan", headers=h).json()["data"] == []
    assert klien_db.delete(f"{B}/me/tugas/{tid}", headers=h).status_code == 200


def test_tugas_dan_notifikasi_milik_orang_lain_tidak_dapat_diakses(klien_db, sesi):
    a, b = _akun(klien_db, "a"), _akun(klien_db, "b")
    tid = klien_db.post(f"{B}/me/tugas", headers=a, json={"judul": "Rahasia", "tanggal": str(HARI)}).json()["data"]["id"]
    assert klien_db.put(f"{B}/me/tugas/{tid}", headers=b, json={"selesai": True}).status_code == 404
    assert klien_db.delete(f"{B}/me/tugas/{tid}", headers=b).status_code == 404


# ---------- chatbot ----------


def test_chat_memakai_data_basis_data_dan_menyimpan_riwayat(klien_db, sesi, monkeypatch):
    sesi.execute(update(Beasiswa).values(status="kedaluwarsa"))  # abaikan data nyata; hanya data uji yang dipakai
    sesi.flush()
    h = _akun(klien_db)
    b = _beasiswa(sesi, _sumber(sesi), "Beasiswa Tanoto Uji", HARI + timedelta(days=30), manfaat="Rp 1.000.000 per bulan")
    diterima = {}

    def palsu(settings, sistem, pesan, timeout=30.0):
        diterima["sistem"], diterima["pesan"] = sistem, pesan
        return "Beasiswa Tanoto Uji memiliki tenggat sesuai data."

    monkeypatch.setattr("app.services.llm.tanya", palsu)
    r = klien_db.post(f"{B}/chat", headers=h, json={"pesan": "Apa manfaat beasiswa Tanoto?"})
    assert r.status_code == 200, r.text
    d = r.json()["data"]
    assert "Tanoto" in d["jawaban"] and any(x["id"] == str(b.id) for x in d["rujukan"])
    assert "HANYA data" in diterima["sistem"] and "Rp 1.000.000 per bulan" in diterima["pesan"]
    assert len(klien_db.get(f"{B}/chat/riwayat", headers=h).json()["data"]) == 1
    assert klien_db.delete(f"{B}/chat/riwayat", headers=h).status_code == 200
    assert klien_db.get(f"{B}/chat/riwayat", headers=h).json()["data"] == []


def test_chat_layanan_ai_mati_memberi_pesan_jelas_dan_batas_panjang(klien_db):
    h = _akun(klien_db)
    assert klien_db.get(f"{B}/chat/status", headers=h).json()["data"]["tersedia"] is False
    r = klien_db.post(f"{B}/chat", headers=h, json={"pesan": "halo"})
    assert r.status_code == 503 and r.json()["error"]["code"] == "UPSTREAM_UNAVAILABLE"
    assert klien_db.post(f"{B}/chat", headers=h, json={"pesan": "x" * 2001}).status_code == 422
    assert klien_db.get(f"{B}/chat/riwayat", headers=h).json()["data"] == []


def test_chat_batas_harian(klien_db, monkeypatch):
    from app.core.config import get_settings
    from app.main import app

    app.dependency_overrides[get_settings] = lambda: Settings(**{**SETTINGS_UJI.model_dump(), "ai_batas_harian": 1})
    h = _akun(klien_db)
    monkeypatch.setattr("app.services.llm.tanya", lambda *a, **k: "ok")
    assert klien_db.post(f"{B}/chat", headers=h, json={"pesan": "satu"}).status_code == 200
    assert klien_db.post(f"{B}/chat", headers=h, json={"pesan": "dua"}).status_code == 429
    app.dependency_overrides[get_settings] = lambda: SETTINGS_UJI


def test_llm_tanya_tanpa_konfigurasi_melempar_galat():
    from app.services import llm

    with pytest.raises(UpstreamUnavailable):
        llm.tanya(SETTINGS_UJI, "s", "p")
