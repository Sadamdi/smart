"""Uji 80 skenario pada lapisan layanan backend untuk semua fitur, tanpa menyimpan data apa pun.

Seluruh pekerjaan berlangsung di satu transaksi luar yang SELALU di-rollback (sesi memakai savepoint, `commit`
dinonaktifkan). Tidak ada akun yang dibuat lewat endpoint, tidak ada kata sandi yang dipakai (kata sandi palsu yang
bukan hash sah), dan tidak ada panggilan LLM. Di akhir, jumlah baris tabel pengguna, rekomendasi, interaksi (dan
beberapa tabel lain) diverifikasi sama seperti sebelum skrip berjalan.

Pemakaian (dari apps/backend, DATABASE_URL di lingkungan):
    python -m scripts.uji_80_skenario [--keluaran berkas.json] [--benih 80] [--jumlah 80]
"""

import argparse
import json
import random
import re
import sys
import time
import traceback
import uuid
from collections import Counter, defaultdict
from datetime import date, timedelta
from decimal import Decimal
from itertools import pairwise

from pydantic import ValidationError
from sqlalchemy import create_engine, func, select, text, update
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.errors import NotFound, ValidationFailed
from app.models import (
    Beasiswa,
    BerkasWajib,
    Interaksi,
    Notifikasi,
    Pengguna,
    Persyaratan,
    Rekomendasi,
    Sumber,
    TugasPribadi,
)
from app.rekomendasi import wilayah
from app.rekomendasi.kelayakan import (
    BELUM,
    HAMPIR,
    MEMENUHI,
    OK,
    ProfilKelayakan,
    nilai_kelayakan,
    periksa_syarat,
)
from app.rekomendasi.mesin import susun
from app.schemas.pengguna import PenggunaOut, ProfilIn
from app.services import aktivitas as akt
from app.services import beasiswa as svc_beasiswa
from app.services import chat as svc_chat
from app.services import dokumen as svc_dokumen
from app.services import profil as svc_profil
from app.services import rekomendasi as svc_rek
from app.services.rekomendasi import _masukan, _usang, profil_dari

FITUR = [
    "profil",
    "rekomendasi",
    "detail_beasiswa",
    "aktivitas",
    "pembaca_cv",
    "chat",
    "invarian",
]
TABEL_DIJAGA = [
    "pengguna",
    "rekomendasi",
    "interaksi",
    "notifikasi",
    "tugas_pribadi",
    "checklist_pengguna",
    "beasiswa",
    "sumber",
]
PASTI = re.compile(r"pasti\s+(di)?terima|dijamin|pasti\s+lolos|100\s*%|persen\s+peluang|pasti\s+berhasil", re.I)
INVALID_STATUS = {"terpenuhi", "dalam_toleransi", "gagal", "tidak_diketahui"}

# ----------------------------------------------------------------------------------------------------------------------
# Pembangkit profil
# ----------------------------------------------------------------------------------------------------------------------

KAMPUS = [
    ("UIN Maulana Malik Ibrahim Malang", "negeri"),
    ("Universitas Indonesia", "negeri"),
    ("Institut Teknologi Bandung", "negeri"),
    ("Universitas Gadjah Mada", "negeri"),
    ("Universitas Airlangga", "negeri"),
    ("Universitas Muhammadiyah Malang", "swasta"),
    ("Universitas Telkom", "swasta"),
    ("Universitas Islam Indonesia", "swasta"),
    ("Universitas Kristen Petra", "swasta"),
    ("Politeknik Negeri Malang", "negeri"),
    ("Universitas Syiah Kuala", "negeri"),
    ("Universitas Cenderawasih", "negeri"),
]
PRODI = [
    "Teknik Informatika",
    "Sistem Informasi",
    "Kedokteran",
    "Akuntansi",
    "Manajemen",
    "Pendidikan Guru Sekolah Dasar",
    "Hukum Ekonomi Syariah",
    "Biologi",
    "Agroteknologi",
    "Psikologi",
    "Teknik Sipil",
    "Ilmu Komunikasi",
    "Farmasi",
    "Sastra Inggris",
]
MINAT = [
    "teknologi",
    "riset",
    "kepemimpinan",
    "kesehatan",
    "bisnis",
    "seni",
    "pendidikan",
    "lingkungan",
    "pertanian",
    "hukum",
    "keagamaan",
    "olahraga",
    "data",
    "kewirausahaan",
]
KOTA_PROV = [
    ("Malang", "Jawa Timur"),
    ("Kota Surabaya", "Jawa Timur"),
    ("Jakarta Selatan", "DKI Jakarta"),
    ("Bandung", "Jawa Barat"),
    ("Yogyakarta", "DI Yogyakarta"),
    ("Medan", "Sumatera Utara"),
    ("Banda Aceh", "Aceh"),
    ("Makassar", "Sulawesi Selatan"),
    ("Denpasar", "Bali"),
    ("Jayapura", "Papua"),
    ("Pontianak", "Kalimantan Barat"),
    ("Kupang", "Nusa Tenggara Timur"),
    ("Kabupaten Sleman", "DI Yogyakarta"),
    ("Semarang", "Jawa Tengah"),
    ("Padang", "Sumatera Barat"),
    ("Ternate", "Maluku Utara"),
    ("Mataram", "Nusa Tenggara Barat"),
    ("Balikpapan", "Kalimantan Timur"),
]
NEGARA_LUAR = [
    ("Malaysia", "Kuala Lumpur"),
    ("Jepang", "Tokyo"),
    ("Japan", "Osaka"),
    ("Australia", "Melbourne"),
    ("Mesir", "Kairo"),
    ("Amerika Serikat", "Boston"),
    ("Singapura", "Singapura"),
    ("Arab Saudi", "Madinah"),
    ("Inggris", "London"),
    ("Jerman", "Berlin"),
    ("Korea Selatan", "Seoul"),
    ("Belanda", "Leiden"),
]
WARGA_ASING = ["Malaysia", "Nigeria", "Warga Negara Asing", "Jepang", "Yaman"]
KONDISI_SAH = ["disabilitas", "ekonomi_kurang_mampu", "yatim_piatu", "daerah_3t", "penghafal_quran", "anak_tenaga_kesehatan"]

INVALID = [
    ("ipk di atas 4", {"ipk": "4.5"}),
    ("ipk negatif", {"ipk": "-0.1"}),
    ("ipk tiga desimal", {"ipk": "3.456"}),
    ("semester nol", {"semester": 0}),
    ("semester 15", {"semester": 15}),
    ("jenjang tidak dikenal", {"jenjang": "S5"}),
    ("jenis kampus tidak dikenal", {"jenis_kampus": "campuran"}),
    ("negara tidak ada", {"negara_domisili": "Atlantis"}),
    ("provinsi tidak ada", {"provinsi_domisili": "Gotham"}),
    ("kondisi khusus tidak sah", {"kondisi_khusus": ["sakti"]}),
    ("penghasilan negatif", {"penghasilan_orang_tua": -5}),
    ("minat lebih dari 20", {"minat": [f"m{i}" for i in range(21)]}),
    ("tanggal lahir bukan tanggal", {"tanggal_lahir": "bukan-tanggal"}),
    ("tanggal lahir di masa depan", {"tanggal_lahir": "2999-01-01"}),
    ("kewarganegaraan terlalu panjang", {"kewarganegaraan": "x" * 81}),
    ("skor bahasa bersarang", {"skor_bahasa": {"toefl": [1, 2]}}),
    ("nama kosong", {"nama": "   "}),
    ("prestasi tingkat tidak sah", {"profil_lanjutan": {"prestasi": [{"nama": "Juara", "tingkat": "dunia"}]}}),
    ("jenis sekolah tidak sah", {"profil_lanjutan": {"jenis_sekolah": "Homeschool"}}),
    ("target studi jenjang tidak sah", {"profil_lanjutan": {"target_studi": {"jenjang": ["S9"]}}}),
]


def _ipk_acak(r: random.Random) -> Decimal:
    return Decimal(str(round(r.uniform(2.0, 4.0), 2)))


def bangun_profil(i: int, r: random.Random, hari_ini: date) -> dict:
    """Satu profil. 24 profil pertama adalah kasus tepi tetap; sisanya acak dengan benih tetap."""
    p: dict = {}
    jenjang = ["D3", "D4", "S1", "S2", "S3"][i % 5] if i < 40 else r.choice(["D3", "D4", "S1", "S1", "S1", "S2", "S3"])
    p["jenjang"] = jenjang
    maks_sem = {"D3": 6, "D4": 8, "S1": 8, "S2": 4, "S3": 8}[jenjang]
    p["semester"] = r.choice([1, 2, maks_sem, 14, r.randint(1, maks_sem)])
    ipk_tepi = [
        Decimal("2.00"),
        Decimal("2.49"),
        Decimal("3.00"),
        Decimal("3.50"),
        Decimal("3.99"),
        Decimal("4.00"),
        Decimal("2.75"),
        Decimal("3.25"),
    ]
    p["ipk"] = ipk_tepi[i % len(ipk_tepi)] if i < 24 else _ipk_acak(r)
    if i % 17 == 5:
        p["ips_terakhir"] = Decimal(str(round(r.uniform(2.0, 4.0), 2)))
    kampus, jenis = r.choice(KAMPUS)
    p["kampus"], p["jenis_kampus"] = kampus, jenis
    p["program_studi"] = r.choice(PRODI)
    p["minat"] = r.sample(MINAT, r.randint(0, 4))
    umur = r.choice([17, 18, 20, 22, 24, 26, 29, 30, 31, 34, 35, 40, 45])
    p["tanggal_lahir"] = date(hari_ini.year - umur, r.randint(1, 12), r.randint(1, 28)).isoformat()
    # kewarganegaraan
    pilihan_warga = ["Indonesia", "WNI", "Warga Negara Indonesia", "Indonesia", "WNI", "asing", "asing", "kosong"]
    w = pilihan_warga[i % len(pilihan_warga)] if i < 40 else r.choice(pilihan_warga)
    if w == "asing":
        w = r.choice(WARGA_ASING)
    p["kewarganegaraan"] = None if w == "kosong" else w
    # domisili
    luar = (i % 5 == 3) if i < 40 else (r.random() < 0.22)
    if luar:
        negara, kota = r.choice(NEGARA_LUAR)
        p["negara_domisili"], p["kota_domisili"] = negara, kota
        if r.random() < 0.3:
            p["provinsi_domisili"] = r.choice(wilayah.PROVINSI_INDONESIA)  # harus dikosongkan oleh layanan profil
    else:
        kota, prov = r.choice(KOTA_PROV)
        p["negara_domisili"] = r.choice(["Indonesia", "Indonesia", "indonesia", "INDONESIA"]) if i % 6 == 0 else "Indonesia"
        p["provinsi_domisili"] = prov if i % 7 else prov.lower()
        p["kota_domisili"] = kota
    p["penghasilan_orang_tua"] = r.choice([None, 0, 500_000, 1_500_000, 3_000_000, 5_000_000, 8_000_000, 15_000_000])
    # skor bahasa
    k = i % 9
    if k == 1:
        p["skor_bahasa"] = {"toefl": r.choice([450, 480, 500, 523, 550, 577, 600, 650])}
    elif k == 2:
        p["skor_bahasa"] = {"ielts": r.choice([5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0])}
    elif k == 3:
        p["skor_bahasa"] = {"toefl": r.choice([500, 550]), "ielts": r.choice([6.0, 6.5, 7.0])}
    elif k == 4:
        p["skor_bahasa"] = {"TOEFL": 550}  # kunci huruf besar
    elif k == 5:
        p["skor_bahasa"] = {"ielts": "6.5"}  # nilai berupa teks angka
    elif k == 6:
        p["skor_bahasa"] = {"toefl": "belum ada"}  # nilai teks bukan angka
    elif k == 7 and i >= 24:
        p["skor_bahasa"] = {"toefl": r.randint(400, 677)}
    kk = r.sample(KONDISI_SAH, r.randint(0, 2))
    p["kondisi_khusus"] = kk
    if i % 4 == 0:
        p["catatan_tambahan"] = r.choice(
            ["Aktif di komunitas riset", "Ingin studi lanjut ke luar negeri", "Penerima beasiswa daerah"]
        )
    if i % 3 == 0:
        kota_a, prov_a = r.choice(KOTA_PROV)
        p["profil_lanjutan"] = {
            "provinsi_asal": prov_a,
            "kota_asal": kota_a,
            "jenis_sekolah": r.choice(["SMA", "SMK", "MA", "Pesantren", "Lainnya"]),
            "tahun_lulus": r.choice([2018, 2020, 2022, 2023]),
            "organisasi": [{"nama": "BEM Fakultas", "jabatan": "Ketua", "tahun": 2024}],
            "prestasi": [
                {"nama": "Juara lomba karya tulis", "tingkat": r.choice(["kota", "provinsi", "nasional"]), "tahun": 2023}
            ],
            "keahlian": r.sample(["python", "statistika", "desain", "pidato", "analisis data"], 2),
            "target_studi": {"jenjang": ["S2"], "negara": ["Jepang"], "bidang": ["teknologi"]},
        }
    if i == 0:  # kasus tepi: hampir semua kolom kosong
        for kol in (
            "ipk",
            "semester",
            "jenis_kampus",
            "kota_domisili",
            "kewarganegaraan",
            "tanggal_lahir",
            "negara_domisili",
            "provinsi_domisili",
            "penghasilan_orang_tua",
            "skor_bahasa",
            "kondisi_khusus",
            "minat",
            "profil_lanjutan",
            "catatan_tambahan",
            "ips_terakhir",
        ):
            p.pop(kol, None)
    if i == 1:  # nilai None eksplisit
        p.update({"ipk": None, "semester": None, "tanggal_lahir": None, "penghasilan_orang_tua": None, "skor_bahasa": None})
    return p


def kelengkapan_acuan(p: dict) -> int:
    """Acuan tujuh data utama (sama dengan klien mobile dan web): jenjang, semester, ipk, jenis kampus, kota, warga, lahir."""
    return sum(
        bool(p.get(k) not in (None, ""))
        for k in ("jenjang", "semester", "ipk", "jenis_kampus", "kota_domisili", "kewarganegaraan", "tanggal_lahir")
    )


def kelengkapan_keluaran(o: PenggunaOut) -> int:
    return sum(
        [
            bool(o.jenjang),
            o.semester is not None,
            o.ipk is not None,
            bool(o.jenis_kampus),
            bool(o.kota_domisili),
            bool(o.kewarganegaraan),
            o.tanggal_lahir is not None,
        ]
    )


def teks_cv(p: dict, i: int) -> tuple[str, dict]:
    """CV sintetis dengan variasi penulisan, dan nilai yang seharusnya terbaca."""
    ekspektasi: dict = {}
    baris = ["CURRICULUM VITAE", f"Nama: Mahasiswa Uji {i}", "Telepon: 0812 3456 7890", f"Kampus: {p.get('kampus', '-')}"]
    ipk = p.get("ipk")
    if ipk is not None:
        v = float(ipk)
        gaya = i % 6
        if gaya == 0:
            baris.append(f"IPK: {v:.2f}".replace(".", ","))
        elif gaya == 1:
            baris.append(f"GPA {v:.2f}")
        elif gaya == 2:
            baris.append(f"Indeks Prestasi Kumulatif = {v:.2f}")
        elif gaya == 3:
            baris.append(f"IPK {v:.2f} dari skala 4.00")
        elif gaya == 4:
            baris.append(f"Cumulative GPA: {v:.2f}")
        else:
            baris.append(f"IPK saat ini {v:.2f}")
        ekspektasi["ipk"] = v
    if p.get("semester") is not None:
        s = p["semester"]
        gaya = i % 5
        romawi = {
            1: "I",
            2: "II",
            3: "III",
            4: "IV",
            5: "V",
            6: "VI",
            7: "VII",
            8: "VIII",
            9: "IX",
            10: "X",
            11: "XI",
            12: "XII",
            13: "XIII",
            14: "XIV",
        }[s]
        baris.append(
            [f"Semester {s}", f"Smt. {romawi}", f"semester ke-{s}", f"Sem: {s}", f"Sedang menempuh semester {romawi}"][gaya]
        )
        ekspektasi["semester"] = s
    sb = p.get("skor_bahasa") or {}
    nilai_toefl = sb.get("toefl", sb.get("TOEFL"))
    if isinstance(nilai_toefl, (int, float)):
        baris.append(["TOEFL ITP: ", "TOEFL score ", "Skor TOEFL: ", "TOEFL "][i % 4] + str(nilai_toefl))
        ekspektasi.setdefault("skor_bahasa", {})["toefl"] = float(nilai_toefl)
    nilai_ielts = sb.get("ielts")
    if isinstance(nilai_ielts, (int, float)):
        t = f"{float(nilai_ielts):.1f}"
        baris.append(
            ["IELTS Academic ", "IELTS: ", "Skor IELTS ", "IELTS overall band "][i % 4]
            + (t.replace(".", ",") if i % 2 else t)
        )
        ekspektasi.setdefault("skor_bahasa", {})["ielts"] = float(nilai_ielts)
    if i % 3 == 0:
        baris.append("Pengalaman: Ketua HMJ Teknologi periode 2023")
    baris.append("Tahun masuk 2022; lulus SMA 2021.")
    return "\n".join(baris), ekspektasi


# ----------------------------------------------------------------------------------------------------------------------
# Rangka pencatat hasil
# ----------------------------------------------------------------------------------------------------------------------


class Pencatat:
    def __init__(self) -> None:
        self.skenario: dict[tuple[str, int], list[str]] = defaultdict(list)
        self.dijalankan: dict[str, set[int]] = defaultdict(set)
        self.cek_total = Counter()
        self.pelanggaran: dict[str, list[dict]] = defaultdict(list)
        self.catatan: list[str] = []
        self.galat: list[dict] = []
        self.bug: list[dict] = []

    def mulai(self, fitur: str, i: int) -> None:
        self.dijalankan[fitur].add(i)
        self.skenario.setdefault((fitur, i), [])

    def cek(self, fitur: str, i: int, kondisi: bool, pesan: str) -> bool:
        self.dijalankan[fitur].add(i)
        self.skenario.setdefault((fitur, i), [])
        self.cek_total[fitur] += 1
        if not kondisi:
            self.skenario[(fitur, i)].append(pesan)
        return bool(kondisi)

    def invarian(self, nama: str, i: int, kondisi: bool, contoh: str) -> None:
        self.cek("invarian", i, kondisi, f"[{nama}] {contoh}")
        self.cek_total[f"inv:{nama}"] += 1
        if not kondisi:
            self.pelanggaran[nama].append({"profil": i, "contoh": contoh})

    def galat_tak_terduga(self, fitur: str, i: int, exc: Exception) -> None:
        self.cek(fitur, i, False, f"galat tak terduga {type(exc).__name__}: {str(exc)[:200]}")
        self.galat.append(
            {
                "fitur": fitur,
                "profil": i,
                "galat": f"{type(exc).__name__}: {str(exc)[:300]}",
                "jejak": traceback.format_exc(limit=4)[-700:],
            }
        )


class RepoSementara:
    """Pengganti PenggunaRepoSql: menyimpan lewat flush saja (tidak pernah commit)."""

    def __init__(self, sesi: Session) -> None:
        self.sesi = sesi

    def simpan(self, pengguna: Pengguna) -> Pengguna:
        self.sesi.flush()
        self.sesi.refresh(pengguna)
        return pengguna


def _larang_commit(*_a, **_k):
    raise RuntimeError("commit dilarang dalam uji ini")


# ----------------------------------------------------------------------------------------------------------------------
# Fitur
# ----------------------------------------------------------------------------------------------------------------------


def uji_profil(c: Pencatat, sesi: Session, repo: RepoSementara, i: int, payload: dict, hari_ini: date) -> Pengguna | None:
    f = "profil"
    c.mulai(f, i)
    # 1. validasi skema
    try:
        data = ProfilIn(**payload)
    except ValidationError as exc:
        c.cek(f, i, False, f"profil sah ditolak: {str(exc)[:200]}")
        return None
    # 2. input tidak sah ditolak
    nama_tidak_sah, tidak_sah = INVALID[i % len(INVALID)]
    ditolak = False
    try:
        ProfilIn(**tidak_sah)
    except ValidationError:
        ditolak = True
    c.cek(f, i, ditolak, f"input tidak sah diterima: {nama_tidak_sah}")
    # 3. simpan lewat layanan
    p = Pengguna(email=f"uji80-{i}-{uuid.uuid4().hex[:6]}@uji80.invalid", kata_sandi="!bukan-hash!", nama=f"Uji80 {i}")
    sesi.add(p)
    sesi.flush()
    try:
        svc_profil.ubah_profil(repo, p, data)
    except Exception as exc:
        c.galat_tak_terduga(f, i, exc)
        return p
    out = PenggunaOut.model_validate(p)
    # nilai yang dikirim tersimpan (dengan kanonikalisasi negara dan provinsi)
    for kol in payload:
        if kol in ("profil_lanjutan",):
            continue
        harapan = getattr(data, kol)
        if kol == "provinsi_domisili" and (p.negara_domisili and p.negara_domisili != wilayah.NEGARA_ASAL):
            harapan = None
        tersimpan = getattr(p, kol)
        if isinstance(harapan, Decimal):
            ok = tersimpan is not None and Decimal(tersimpan) == harapan
        else:
            ok = tersimpan == harapan
        c.cek(f, i, ok, f"kolom {kol} tidak tersimpan benar: kirim={harapan!r} simpan={tersimpan!r}")
    if "profil_lanjutan" in payload:
        pl = p.profil_lanjutan or {}
        c.cek(
            f,
            i,
            pl.get("kota_asal") == payload["profil_lanjutan"].get("kota_asal"),
            "profil lanjutan kota_asal tidak tersimpan",
        )
        c.cek(
            f,
            i,
            len(pl.get("organisasi", [])) == len(payload["profil_lanjutan"].get("organisasi", [])),
            "organisasi profil lanjutan hilang",
        )
    # domisili
    if payload.get("negara_domisili"):
        baku = wilayah.negara_kanonik(payload["negara_domisili"])
        c.cek(f, i, p.negara_domisili == baku, f"negara_domisili tidak kanonik: {p.negara_domisili!r} != {baku!r}")
        if baku == wilayah.NEGARA_ASAL and payload.get("provinsi_domisili"):
            c.cek(
                f,
                i,
                p.provinsi_domisili == wilayah.provinsi_kanonik(payload["provinsi_domisili"]),
                "provinsi_domisili tidak tersimpan",
            )
        if baku != wilayah.NEGARA_ASAL:
            c.cek(f, i, p.provinsi_domisili is None, "provinsi_domisili tidak dikosongkan untuk domisili luar negeri")
    # kelengkapan tujuh data utama
    acuan = kelengkapan_acuan(payload)
    c.cek(f, i, kelengkapan_keluaran(out) == acuan, f"kelengkapan {kelengkapan_keluaran(out)} != acuan {acuan}")
    # pembaruan sebagian: hanya kolom yang dikirim berubah
    sebelum = (p.jenjang, p.kota_domisili, p.kampus)
    svc_profil.ubah_profil(repo, p, ProfilIn(nama=f"Uji80 {i} ubah"))
    c.cek(
        f,
        i,
        p.nama.endswith("ubah") and (p.jenjang, p.kota_domisili, p.kampus) == sebelum,
        "ubah sebagian mengubah kolom lain",
    )
    # kewarganegaraan WNI dan sinonimnya tersimpan apa adanya (dinormalisasi hanya di mesin)
    c.cek(f, i, out.id is not None and out.preferensi_notifikasi is not None, "keluaran profil tidak lengkap")
    return p


def uji_rekomendasi(c: Pencatat, sesi: Session, p: Pengguna, i: int, hari_ini: date, masukan: list) -> list:
    f = "rekomendasi"
    c.mulai(f, i)
    hasil = svc_rek.hitung(sesi, p, hari_ini)
    n = len(masukan)
    kat = Counter(h.kategori for h in hasil)
    c.cek(f, i, len(hasil) == n, f"jumlah hasil {len(hasil)} != beasiswa terbit tak kedaluwarsa {n}")
    c.cek(f, i, sum(kat.values()) == len(hasil), "jumlah per kategori tidak sama dengan total")
    c.cek(f, i, set(kat) <= {MEMENUHI, HAMPIR, BELUM}, f"kategori tidak dikenal {set(kat)}")
    rr = svc_rek.daftar(sesi, p, hari_ini, None)
    c.cek(f, i, len(rr) == len(hasil), f"daftar {len(rr)} != hitung {len(hasil)}")
    rg = svc_rek.ringkasan(sesi, p, hari_ini)
    c.cek(f, i, rg == {k: kat.get(k, 0) for k in (MEMENUHI, HAMPIR, BELUM)}, f"ringkasan {rg} != hitung {dict(kat)}")
    for k in (MEMENUHI, HAMPIR, BELUM):
        ck = svc_rek.daftar(sesi, p, hari_ini, k)
        c.cek(f, i, len(ck) == kat.get(k, 0) and all(r.kategori == k for r, _ in ck), f"filter kategori {k} salah")
    # alasan dan kekurangan
    for r, b in rr:
        if r.kategori == MEMENUHI:
            c.cek(f, i, bool(r.alasan), f"memenuhi tanpa alasan: {b.nama[:50]}")
        else:
            c.cek(f, i, bool(r.catatan_kekurangan), f"{r.kategori} tanpa catatan kekurangan: {b.nama[:50]}")
        teks = " ".join([str(x) for x in (r.alasan or [])] + [str(x) for x in (r.catatan_kekurangan or [])])
        c.cek(f, i, not PASTI.search(teks), f"pernyataan pasti pada {b.nama[:50]}: {teks[:100]}")
        c.cek(f, i, 0 <= float(r.skor) <= 1.0001, f"skor di luar 0..1: {r.skor}")
        c.cek(f, i, b.tenggat is None or b.tenggat >= hari_ini, f"tenggat lewat ditampilkan: {b.nama[:50]}")
        c.cek(f, i, b.status == "terbit", "beasiswa tidak terbit ditampilkan")
    # urutan
    urutan = {MEMENUHI: 0, HAMPIR: 1, BELUM: 2}
    kunci = [(urutan[r.kategori], -float(r.skor), b.tenggat or date.max) for r, b in rr]
    c.cek(f, i, kunci == sorted(kunci), "urutan daftar tidak menurut kategori, skor, tenggat")
    # tanpa duplikat
    c.cek(f, i, len({b.id for _, b in rr}) == len(rr), "beasiswa ganda dalam daftar")
    # deterministik
    ulang = svc_rek.hitung(sesi, p, hari_ini)
    c.cek(
        f,
        i,
        [(h.beasiswa_id, h.kategori, h.skor) for h in hasil] == [(h.beasiswa_id, h.kategori, h.skor) for h in ulang],
        "hitung ulang pada profil sama memberi hasil berbeda",
    )
    # hitung ulang otomatis (_usang)
    T = sesi.scalar(select(func.now()))
    c.cek(f, i, _usang(sesi, p) is False, "_usang True padahal baru dihitung")
    ipk_lama, semester_lama = p.ipk, p.semester
    p.ipk = Decimal("4.00") if (ipk_lama or Decimal(0)) < Decimal("3.5") else Decimal("2.00")
    p.semester = max(1, min(14, (p.semester or 3) + 1))
    p.diubah_pada = T + timedelta(hours=1)  # waktu dalam transaksi tetap; majukan agar mirip profil diubah kemudian
    sesi.flush()
    c.cek(f, i, _usang(sesi, p) is True, "_usang False setelah profil diubah")
    baru = svc_rek.daftar(sesi, p, hari_ini, None)
    segar = susun(
        profil_dari(sesi, p),
        p.minat,
        p.program_studi,
        masukan,
        hari_ini,
        kondisi_khusus=p.kondisi_khusus,
        catatan=svc_rek.teks_tambahan(p),
    )
    kat_segar = Counter(h.kategori for h in segar)
    kat_baru = Counter(r.kategori for r, _ in baru)
    c.cek(
        f,
        i,
        all(kat_baru.get(k, 0) == kat_segar.get(k, 0) for k in (MEMENUHI, HAMPIR, BELUM)),
        "daftar setelah profil diubah tidak sesuai profil baru",
    )
    sesi.execute(update(Rekomendasi).where(Rekomendasi.pengguna_id == p.id).values(diubah_pada=T + timedelta(hours=2)))
    sesi.flush()
    c.cek(f, i, _usang(sesi, p) is False, "_usang True padahal hasil lebih baru dari profil")
    sesi.execute(update(Rekomendasi).where(Rekomendasi.pengguna_id == p.id).values(versi_model="aturan-0.1"))
    sesi.flush()
    c.cek(f, i, _usang(sesi, p) is True, "_usang False padahal versi model lama")
    svc_rek.daftar(sesi, p, hari_ini, None)  # hitung ulang kembali
    # kembalikan profil
    p.ipk = ipk_lama
    p.semester = semester_lama
    p.diubah_pada = T + timedelta(hours=1)
    sesi.flush()
    return svc_rek.hitung(sesi, p, hari_ini)  # hasil tersimpan kembali sesuai profil asli


def uji_detail(c: Pencatat, sesi: Session, p: Pengguna, i: int, hari_ini: date, rek_baris: dict, sepuluh: list) -> None:
    f = "detail_beasiswa"
    c.mulai(f, i)
    profil = profil_dari(sesi, p)
    for b in sepuluh:
        syarat = list(sesi.scalars(select(Persyaratan).where(Persyaratan.beasiswa_id == b.id)))
        try:
            n = svc_beasiswa.nilai_untuk(syarat, profil, hari_ini, b.jenjang)
        except Exception as exc:
            c.galat_tak_terduga(f, i, exc)
            continue
        c.cek(f, i, n.kelayakan.kategori in (MEMENUHI, HAMPIR, BELUM), "kategori detail tidak sah")
        c.cek(
            f,
            i,
            all(v in INVALID_STATUS for v in n.status_syarat.values()),
            f"status syarat tidak sah {set(n.status_syarat.values())}",
        )
        c.cek(f, i, all(0 <= k <= len(syarat) for k in n.status_syarat), "indeks status syarat di luar rentang")
        stat = list(n.status_syarat.values())
        kat = n.kelayakan.kategori
        if kat == MEMENUHI:
            c.cek(
                f,
                i,
                bool(stat) and all(s == "terpenuhi" for s in stat),
                f"memenuhi tetapi ada syarat tidak terpenuhi: {b.nama[:40]}",
            )
        elif kat == BELUM:
            c.cek(f, i, "gagal" in stat, f"belum memenuhi tanpa syarat gagal: {b.nama[:40]}")
        else:
            c.cek(f, i, "gagal" not in stat, f"hampir memenuhi tetapi ada syarat gagal: {b.nama[:40]}")
        r = rek_baris.get(b.id)
        if r is not None:
            c.cek(f, i, r.kategori == kat, f"kategori detail {kat} != rekomendasi {r.kategori}: {b.nama[:40]}")
            c.cek(
                f,
                i,
                abs(float(r.skor_kelayakan) - n.kelayakan.skor) < 1e-3,
                "skor kelayakan detail berbeda dari rekomendasi",
            )
        teks = " ".join(n.catatan_syarat.values())
        c.cek(f, i, not PASTI.search(teks), "catatan syarat memuat pernyataan pasti")


def uji_invarian(c: Pencatat, sesi: Session, p: Pengguna, i: int, hari_ini: date, masukan: list, r: random.Random) -> None:
    base = profil_dari(sesi, p)

    def kategori_semua(pr: ProfilKelayakan) -> dict:
        return {m.id: nilai_kelayakan(m.syarat, pr, hari_ini) for m in masukan}

    def salin(**kw) -> ProfilKelayakan:
        d = dict(base.__dict__)
        d["berkas_diunggah"] = set(base.berkas_diunggah)
        d["daerah_asal"] = list(base.daerah_asal)
        d.update(kw)
        return ProfilKelayakan(**d)

    # 1. IPK naik tidak menurunkan jumlah memenuhi (profil lain tetap), juga per beasiswa
    tangga = [2.0, 2.25, 2.5, 2.75, 3.0, 3.25, 3.5, 3.75, 4.0]
    jumlah, per = [], []
    for v in tangga:
        h = kategori_semua(salin(ipk=v))
        jumlah.append(sum(1 for x in h.values() if x.kategori == MEMENUHI))
        per.append({k: x.kategori for k, x in h.items()})
    c.invarian("ipk_monoton_jumlah", i, all(a <= b for a, b in pairwise(jumlah)), f"memenuhi menurut IPK {tangga}: {jumlah}")
    urut = {MEMENUHI: 0, HAMPIR: 1, BELUM: 2}
    turun = [
        m.nama[:50] for m in masukan if any(urut[per[k + 1][m.id]] > urut[per[k][m.id]] for k in range(len(tangga) - 1))
    ]
    c.invarian("ipk_monoton_per_beasiswa", i, not turun, f"kategori memburuk saat IPK naik: {turun[:3]}")

    # 2. jenjang di luar syarat jenjang tidak pernah memenuhi
    salah = []
    for jj in ("D3", "D4", "S1", "S2", "S3"):
        h = kategori_semua(salin(jenjang=jj))
        for m in masukan:
            for jenis, batas in m.syarat:
                if jenis != "jenjang":
                    continue
                diminta = (batas or {}).get("nilai")
                diminta = [diminta] if isinstance(diminta, str) else list(diminta or [])
                if diminta and jj not in diminta and h[m.id].kategori == MEMENUHI:
                    salah.append(f"{jj} memenuhi {m.nama[:40]} (syarat {diminta})")
    c.invarian("jenjang_luar_syarat", i, not salah, "; ".join(salah[:3]))
    kol_salah = []
    jenjang_beasiswa = {
        b.id: b.jenjang for b in sesi.scalars(select(Beasiswa).where(Beasiswa.id.in_([m.id for m in masukan])))
    }
    if base.jenjang:
        h = kategori_semua(base)
        for m in masukan:
            jb = jenjang_beasiswa.get(m.id) or []
            punya_syarat = any(j == "jenjang" and (b or {}).get("nilai") for j, b in m.syarat)
            # bila ada baris syarat jenjang, itulah yang berlaku (konflik dengan kolom dilaporkan sebagai catatan data)
            if jb and not punya_syarat and base.jenjang not in jb and h[m.id].kategori == MEMENUHI:
                kol_salah.append(f"{base.jenjang} memenuhi {m.nama[:40]} (kolom jenjang {jb})")
    c.invarian("jenjang_kolom_beasiswa", i, not kol_salah, "; ".join(kol_salah[:3]))

    # 3. WNI, Indonesia, Warga Negara Indonesia sama
    ref = None
    sama = True
    contoh = ""
    for nama in ("Indonesia", "WNI", "Warga Negara Indonesia", "wni", "INDONESIA"):
        h = {k: (x.kategori, round(x.skor, 6)) for k, x in kategori_semua(salin(kewarganegaraan=nama)).items()}
        if ref is None:
            ref = h
        elif h != ref:
            sama = False
            contoh = f"{nama} berbeda dari Indonesia"
    c.invarian("wni_setara", i, sama, contoh)

    # 4. negara luar negeri tidak cocok dengan syarat domisili Indonesia
    negara_luar = NEGARA_LUAR[i % len(NEGARA_LUAR)][0]
    luar = salin(
        negara_domisili=wilayah.negara_kanonik(negara_luar), provinsi_domisili=None, kota_domisili=None, daerah_asal=[]
    )
    salah_indonesia, salah_daerah = [], []
    for m in masukan:
        for jenis, batas in m.syarat:
            if jenis != "domisili":
                continue
            diminta = (batas or {}).get("nilai")
            diminta = [diminta] if isinstance(diminta, str) else [str(x) for x in (diminta or [])]
            if not diminta:
                continue
            h = periksa_syarat(jenis, batas, luar, hari_ini)
            if h is None:
                continue
            if (
                any(d.lower().strip() in ("indonesia", "wilayah indonesia", "seluruh indonesia") for d in diminta)
                and h.status == OK
            ):
                salah_indonesia.append(f"{negara_luar} cocok dengan syarat {diminta} pada {m.nama[:40]}")
            elif all(wilayah.provinsi_kanonik(d) or wilayah.provinsi_dari_kota(d) for d in diminta) and h.status == OK:
                salah_daerah.append(f"{negara_luar} cocok dengan syarat daerah {diminta} pada {m.nama[:40]}")
    c.invarian("negara_luar_vs_domisili_indonesia", i, not salah_indonesia, "; ".join(salah_indonesia[:3]))
    c.invarian("negara_luar_vs_domisili_daerah", i, not salah_daerah, "; ".join(salah_daerah[:3]))
    # profil sendiri yang berdomisili luar negeri, dinilai lewat rekomendasi tersimpan
    # 5. beasiswa tanpa syarat terukur tidak pernah memenuhi (profil sangat lengkap dan profil ini)
    lengkap = salin(
        jenjang="S1",
        semester=5,
        ipk=4.0,
        jenis_kampus="negeri",
        kota_domisili="Malang",
        negara_domisili="Indonesia",
        provinsi_domisili="Jawa Timur",
        tanggal_lahir=date(hari_ini.year - 20, 1, 1),
        penghasilan_orang_tua=0,
        kewarganegaraan="Indonesia",
        skor_bahasa={"toefl": 677, "ielts": 9},
    )
    tanpa = []
    h_lengkap = kategori_semua(lengkap)
    h_ini = kategori_semua(base)
    for m in masukan:
        terukur = [periksa_syarat(j, b, lengkap, hari_ini) for j, b in m.syarat]
        if all(t is None for t in terukur):
            if h_lengkap[m.id].kategori == MEMENUHI or h_ini[m.id].kategori == MEMENUHI:
                tanpa.append(m.nama[:50])
    c.invarian("tanpa_syarat_terukur", i, not tanpa, f"memenuhi tanpa syarat terukur: {tanpa[:3]}")

    # 6. tenggat lewat tidak ditampilkan
    rr = svc_rek.daftar(sesi, p, hari_ini, None)
    lewat = [b.nama[:50] for _, b in rr if b.tenggat is not None and b.tenggat < hari_ini]
    c.invarian("tenggat_lewat_tidak_tampil", i, not lewat, f"tampil walau lewat: {lewat[:3]}")
    # profil kosong sama sekali tidak boleh memenuhi beasiswa yang punya syarat terukur
    kosong = ProfilKelayakan()
    h0 = kategori_semua(kosong)
    salah0 = [
        m.nama[:50]
        for m in masukan
        if h0[m.id].kategori == MEMENUHI and any(periksa_syarat(j, b, lengkap, hari_ini) is not None for j, b in m.syarat)
    ]
    c.invarian("profil_kosong_tidak_memenuhi", i, not salah0, f"profil kosong memenuhi: {salah0[:3]}")
    # 7. konsistensi kategori terhadap skor_bahasa berformat berbeda
    for kunci_a, kunci_b in (("toefl", "TOEFL"), ("ielts", "IELTS")):
        a = kategori_semua(salin(skor_bahasa={kunci_a: 600 if kunci_a == "toefl" else 7.5}))
        b = kategori_semua(salin(skor_bahasa={kunci_b: 600 if kunci_a == "toefl" else 7.5}))
        beda = [m.nama[:40] for m in masukan if a[m.id].kategori != b[m.id].kategori]
        c.invarian("skor_bahasa_huruf_besar_setara", i, not beda, f"{kunci_a} vs {kunci_b}: {beda[:2]}")
    # 8. skor bahasa tidak numerik tidak boleh membuat galat
    try:
        kategori_semua(salin(skor_bahasa={"toefl": "belum ada", "ielts": "n/a"}))
        galat = ""
    except Exception as exc:
        galat = f"{type(exc).__name__}: {exc}"
    c.invarian("skor_bahasa_teks_tidak_galat", i, not galat, galat)


def uji_cv(c: Pencatat, i: int, payload: dict, acc: dict) -> None:
    f = "pembaca_cv"
    c.mulai(f, i)
    teks, harapan = teks_cv(payload, i)
    try:
        hasil = svc_dokumen.baca_dengan_aturan(teks)
    except Exception as exc:
        c.galat_tak_terduga(f, i, exc)
        return
    for kol in ("ipk", "semester"):
        if kol in harapan:
            acc[kol][1] += 1
            ok = hasil.get(kol) == harapan[kol]
            acc[kol][0] += int(ok)
            c.cek(f, i, ok, f"{kol}: terbaca {hasil.get(kol)!r}, seharusnya {harapan[kol]!r}")
        else:
            c.cek(f, i, kol not in hasil, f"{kol} terbaca {hasil.get(kol)!r} padahal tidak ada di CV")
    for nama in ("toefl", "ielts"):
        ada = nama in harapan.get("skor_bahasa", {})
        if ada:
            acc[nama][1] += 1
            ok = (hasil.get("skor_bahasa") or {}).get(nama) == harapan["skor_bahasa"][nama]
            acc[nama][0] += int(ok)
            c.cek(
                f,
                i,
                ok,
                f"{nama}: terbaca {(hasil.get('skor_bahasa') or {}).get(nama)!r}, seharusnya {harapan['skor_bahasa'][nama]!r}",
            )
        else:
            c.cek(f, i, nama not in (hasil.get("skor_bahasa") or {}), f"{nama} terbaca padahal tidak ada di CV")
    if i % 3 == 0:
        acc["organisasi"][1] += 1
        ok = bool(hasil.get("pengalaman_organisasi"))
        acc["organisasi"][0] += int(ok)
        c.cek(f, i, ok, "organisasi tidak terbaca")


def uji_chat(c: Pencatat, sesi: Session, p: Pengguna, i: int, hari_ini: date) -> None:
    f = "chat"
    c.mulai(f, i)
    pesan_uji = [
        "Beasiswa apa yang cocok untuk saya?",
        "Ceritakan tentang LPDP dan Chevening",
        "beasiswa unggulan",
        "",
        "%%%% ____ \\\\",
        "'; DROP TABLE pengguna; -- beasiswa",
        "scholarship Jepang Monbukagakusho",
        "a b c",
    ]
    pesan = pesan_uji[i % len(pesan_uji)]
    try:
        cari = svc_chat.cari_beasiswa(sesi, pesan, hari_ini)
        data, rujukan = svc_chat.susun_data(sesi, p, pesan, hari_ini)
    except Exception as exc:
        c.galat_tak_terduga(f, i, exc)
        return
    c.cek(f, i, len(cari) <= svc_chat.KONTEKS_MAKS, "cari_beasiswa melebihi batas konteks")
    c.cek(
        f,
        i,
        all(b.status == "terbit" and (b.tenggat is None or b.tenggat >= hari_ini) for b in cari),
        "cari_beasiswa memuat beasiswa tidak terlihat",
    )
    tg = [b.tenggat or date.max for b in cari]
    c.cek(f, i, tg == sorted(tg), "cari_beasiswa tidak urut tenggat")
    c.cek(f, i, data.startswith("Profil:"), "data tidak diawali Profil")
    c.cek(f, i, f"jenjang={p.jenjang}" in data, "jenjang profil tidak ada pada data")
    c.cek(f, i, len(set(rujukan)) == len(rujukan), "rujukan ganda")
    ada = {b.id for b in sesi.scalars(select(Beasiswa).where(Beasiswa.id.in_(rujukan)))} if rujukan else set()
    c.cek(f, i, ada == set(rujukan), "rujukan menunjuk beasiswa yang tidak ada")
    c.cek(
        f,
        i,
        not PASTI.search(data),
        f"data chat memuat pernyataan pasti: {PASTI.search(data) and PASTI.search(data).group(0)}",
    )
    n_rek = data.count("\nRekomendasi:")
    c.cek(f, i, n_rek <= svc_chat.KONTEKS_MAKS, "rekomendasi pada data melebihi batas")
    # tidak ada tenggat lewat pada baris data
    for tgl in re.findall(r"tenggat (\d{4}-\d{2}-\d{2})", data):
        c.cek(f, i, date.fromisoformat(tgl) >= hari_ini, f"tenggat lewat pada data chat: {tgl}")


def uji_aktivitas(c: Pencatat, sesi: Session, p: Pengguna, lain: Pengguna, i: int, hari_ini: date, sintetik: dict) -> None:
    f = "aktivitas"
    c.mulai(f, i)
    b, kedaluwarsa, dekat = sintetik["b"], sintetik["kedaluwarsa"], sintetik["dekat"]
    # simpan (idempoten)
    akt.catat_interaksi(sesi, p, b.id, "simpan", None, hari_ini)
    akt.catat_interaksi(sesi, p, b.id, "simpan", None, hari_ini)
    n = sesi.scalar(
        select(func.count())
        .select_from(Interaksi)
        .where(Interaksi.pengguna_id == p.id, Interaksi.aksi == "simpan", Interaksi.beasiswa_id == b.id)
    )
    c.cek(f, i, n == 1, f"simpan ganda menghasilkan {n} baris")
    akt.catat_interaksi(sesi, p, dekat.id, "simpan", None, hari_ini)
    akt.catat_interaksi(sesi, p, b.id, "klik", None, hari_ini)
    ts = akt.tersimpan(sesi, p, hari_ini)
    c.cek(f, i, {x.id for x, _ in ts} >= {b.id, dekat.id}, "beasiswa tersimpan tidak muncul")
    c.cek(
        f,
        i,
        [x.tenggat or date.max for x, _ in ts] == sorted(x.tenggat or date.max for x, _ in ts),
        "tersimpan tidak urut tenggat",
    )
    # rencana daftar
    try:
        akt.catat_interaksi(sesi, p, b.id, "rencana_daftar", None, hari_ini)
        c.cek(f, i, False, "rencana_daftar tanpa status diterima")
    except ValidationFailed:
        c.cek(f, i, True, "")
    status = ["akan_daftar", "sudah_daftar", "tidak_jadi"][i % 3]
    akt.catat_interaksi(sesi, p, b.id, "rencana_daftar", status, hari_ini)
    rencana = dict((x.id, s) for x, s in akt.tersimpan(sesi, p, hari_ini))
    c.cek(f, i, rencana.get(b.id) == status, f"status rencana {rencana.get(b.id)!r} != {status!r}")
    akt.catat_interaksi(sesi, p, b.id, "rencana_daftar", "sudah_daftar", hari_ini)
    rencana = dict((x.id, s) for x, s in akt.tersimpan(sesi, p, hari_ini))
    c.cek(f, i, rencana.get(b.id) == "sudah_daftar", "rencana terbaru tidak dipakai")
    # beasiswa kedaluwarsa dan tidak ada
    for target, nama in ((kedaluwarsa.id, "kedaluwarsa"), (uuid.uuid4(), "tidak ada")):
        try:
            akt.catat_interaksi(sesi, p, target, "simpan", None, hari_ini)
            c.cek(f, i, False, f"simpan beasiswa {nama} diterima")
        except NotFound:
            c.cek(f, i, True, "")
    # checklist
    cl = {x.id: berkas for x, berkas in akt.checklist(sesi, p, hari_ini)}
    c.cek(f, i, b.id in cl and len(cl[b.id]) == 2 and not any(s for _, s in cl[b.id]), "checklist awal salah")
    berkas = sesi.scalars(select(BerkasWajib).where(BerkasWajib.beasiswa_id == b.id).order_by(BerkasWajib.nama_berkas)).all()
    akt.centang(sesi, p, berkas[0].id, True, hari_ini)
    akt.centang(sesi, p, berkas[0].id, True, hari_ini)
    cl = {x.id: dict((w.id, s) for w, s in br) for x, br in akt.checklist(sesi, p, hari_ini)}
    c.cek(f, i, cl[b.id][berkas[0].id] is True and cl[b.id][berkas[1].id] is False, "centang tidak tercermin")
    akt.centang(sesi, p, berkas[0].id, False, hari_ini)
    cl = {x.id: dict((w.id, s) for w, s in br) for x, br in akt.checklist(sesi, p, hari_ini)}
    c.cek(f, i, cl[b.id][berkas[0].id] is False, "buka centang tidak tercermin")
    akt.centang(sesi, p, berkas[1].id, True, hari_ini)
    # pengguna lain tidak ikut tercentang dan tidak boleh mencentang berkas yang tidak ia simpan
    try:
        akt.centang(sesi, lain, berkas[1].id, True, hari_ini)
        c.cek(f, i, False, "pengguna lain mencentang berkas yang tidak disimpannya")
    except NotFound:
        c.cek(f, i, True, "")
    c.cek(
        f, i, all(not s for _, br in akt.checklist(sesi, lain, hari_ini) for _, s in br), "checklist bocor ke pengguna lain"
    )
    # tugas pribadi
    tgl = hari_ini + timedelta(days=2)
    t = akt.tambah_tugas(sesi, p, f"Tugas uji {i}", tgl)
    c.cek(f, i, t.id is not None and t.selesai is False, "tugas baru salah")
    akt.ubah_tugas(sesi, p, t.id, {"selesai": True, "judul": "Diubah"})
    t2 = sesi.get(TugasPribadi, t.id)
    c.cek(f, i, t2.selesai is True and t2.judul == "Diubah", "ubah tugas gagal")
    try:
        akt.ubah_tugas(sesi, lain, t.id, {"judul": "Retas"})
        c.cek(f, i, False, "pengguna lain mengubah tugas")
    except NotFound:
        c.cek(f, i, True, "")
    try:
        akt.hapus_tugas(sesi, lain, t.id)
        c.cek(f, i, False, "pengguna lain menghapus tugas")
    except NotFound:
        c.cek(f, i, True, "")
    # kalender
    kal = akt.kalender(sesi, p, hari_ini, hari_ini + timedelta(days=30), hari_ini)
    jenis = {(a["jenis"], a["ref_id"]) for a in kal}
    c.cek(f, i, ("tugas", t.id) in jenis and ("tenggat", dekat.id) in jenis, "kalender tidak memuat tugas dan tenggat")
    tg = [(a["tanggal"], a["jenis"]) for a in kal]
    c.cek(f, i, tg == sorted(tg), "kalender tidak urut")
    for dari, sampai, nama in (
        (hari_ini, hari_ini - timedelta(days=1), "terbalik"),
        (hari_ini, hari_ini + timedelta(days=400), "lebih setahun"),
    ):
        try:
            akt.kalender(sesi, p, dari, sampai, hari_ini)
            c.cek(f, i, False, f"rentang kalender {nama} diterima")
        except ValidationFailed:
            c.cek(f, i, True, "")
    akt.hapus_tugas(sesi, p, t.id)
    c.cek(f, i, sesi.get(TugasPribadi, t.id) is None, "hapus tugas gagal")
    try:
        akt.hapus_tugas(sesi, p, t.id)
        c.cek(f, i, False, "hapus tugas dua kali diterima")
    except NotFound:
        c.cek(f, i, True, "")
    # notifikasi pengingat
    daftar1 = akt.daftar_notifikasi(sesi, p, hari_ini)
    ids = {bb.id for _, bb in daftar1}
    c.cek(f, i, dekat.id in ids, "pengingat untuk tenggat dekat tidak dibuat")
    c.cek(f, i, b.id not in ids, "pengingat dibuat untuk tenggat jauh")
    c.cek(f, i, kedaluwarsa.id not in ids, "pengingat untuk beasiswa kedaluwarsa")
    daftar2 = akt.daftar_notifikasi(sesi, p, hari_ini)
    c.cek(f, i, len(daftar2) == len(daftar1), "pengingat ganda pada pembacaan kedua")
    c.cek(f, i, akt.buat_pengingat(sesi, p, hari_ini) == 0, "buat_pengingat membuat ganda")
    nid = daftar1[0][0].id
    akt.tandai_dibaca(sesi, p, nid)
    sesi.refresh(daftar1[0][0])
    c.cek(f, i, daftar1[0][0].dibaca is True, "tandai dibaca gagal")
    try:
        akt.tandai_dibaca(sesi, lain, nid)
        c.cek(f, i, False, "pengguna lain menandai notifikasi")
    except NotFound:
        c.cek(f, i, True, "")
    akt.tandai_semua_dibaca(sesi, p)
    c.cek(
        f,
        i,
        all(sesi.get(Notifikasi, n.id).dibaca for n, _ in akt.daftar_notifikasi(sesi, p, hari_ini)),
        "tandai semua dibaca gagal",
    )
    c.cek(
        f,
        i,
        all(n.pengguna_id == lain.id for n, _ in akt.daftar_notifikasi(sesi, lain, hari_ini)),
        "notifikasi bocor ke pengguna lain",
    )
    # batal simpan
    akt.batal_simpan(sesi, p, b.id)
    akt.batal_simpan(sesi, p, b.id)  # idempoten
    c.cek(f, i, b.id not in {x.id for x, _ in akt.tersimpan(sesi, p, hari_ini)}, "batal simpan gagal")
    c.cek(
        f,
        i,
        b.id not in {x.id for x, _ in akt.checklist(sesi, p, hari_ini)},
        "checklist masih memuat beasiswa tidak tersimpan",
    )


# ----------------------------------------------------------------------------------------------------------------------
# Utama
# ----------------------------------------------------------------------------------------------------------------------


def hitung_tabel(engine) -> dict[str, int]:
    with engine.connect() as k:
        return {t: k.execute(text("select count(*) from " + t)).scalar_one() for t in TABEL_DIJAGA}  # noqa: S608


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--keluaran", default="uji-80-skenario-backend.json")
    ap.add_argument("--benih", type=int, default=80)
    ap.add_argument("--jumlah", type=int, default=80)
    args = ap.parse_args()

    url = get_settings().database_url
    if not url:
        print("DATABASE_URL belum diisi", file=sys.stderr)
        return 2
    engine = create_engine(url, pool_pre_ping=True)
    sebelum = hitung_tabel(engine)
    hari_ini = date.today()
    mulai = time.time()
    c = Pencatat()
    r = random.Random(args.benih)  # noqa: S311
    profil_semua = [bangun_profil(i, r, hari_ini) for i in range(args.jumlah)]

    conn = engine.connect()
    luar = conn.begin()
    sesi = Session(bind=conn, join_transaction_mode="create_savepoint", expire_on_commit=False)
    sesi.commit = _larang_commit  # type: ignore[method-assign]
    repo = RepoSementara(sesi)
    acc = {k: [0, 0] for k in ("ipk", "semester", "toefl", "ielts", "organisasi")}
    info: dict = {}
    try:
        masukan = _masukan(sesi, hari_ini)
        info["beasiswa_terbit_aktif"] = len(masukan)
        info["beasiswa_terbit_total"] = sesi.scalar(
            select(func.count()).select_from(Beasiswa).where(Beasiswa.status == "terbit")
        )
        info["terbit_tenggat_lewat_tidak_tampil"] = [
            b.nama[:60]
            for b in sesi.scalars(select(Beasiswa).where(Beasiswa.status == "terbit", Beasiswa.tenggat < hari_ini))
        ]
        jenjang_kolom = {
            b.id: b.jenjang for b in sesi.scalars(select(Beasiswa).where(Beasiswa.id.in_([m.id for m in masukan])))
        }
        konflik, tanpa_jenjang = [], 0
        for m in masukan:
            sy = [
                set((b or {}).get("nilai") or []) if not isinstance((b or {}).get("nilai"), str) else {b["nilai"]}
                for j, b in m.syarat
                if j == "jenjang"
            ]
            sy = set().union(*sy) if sy else set()
            kol = set(jenjang_kolom.get(m.id) or [])
            if sy and kol and kol < sy:
                konflik.append(f"{m.nama[:60]} (syarat jenjang {sorted(sy)}, kolom {sorted(kol)})")
            if not sy and not kol:
                tanpa_jenjang += 1
        info["catatan_data_konflik_jenjang"] = {"jumlah": len(konflik), "contoh": konflik[:8]}
        info["catatan_data_tanpa_info_jenjang"] = tanpa_jenjang
        ids_lewat = set(sesi.scalars(select(Beasiswa.id).where(Beasiswa.status == "terbit", Beasiswa.tenggat < hari_ini)))
        c.cek("invarian", -1, not (ids_lewat & {m.id for m in masukan}), "beasiswa tenggat lewat masuk ke _masukan")
        sepuluh = list(
            sesi.scalars(
                select(Beasiswa)
                .where(Beasiswa.status == "terbit", (Beasiswa.tenggat.is_(None)) | (Beasiswa.tenggat >= hari_ini))
                .order_by(func.coalesce(Beasiswa.tenggat, date.max), Beasiswa.id)
                .limit(10)
            )
        )
        pengguna: list[Pengguna | None] = []
        ringkas_profil: list[dict] = []
        for i, payload in enumerate(profil_semua):
            print(f"profil {i} t={time.time() - mulai:.0f}s", file=sys.stderr, flush=True)
            p = None
            try:
                p = uji_profil(c, sesi, repo, i, payload, hari_ini)
            except Exception as exc:
                c.galat_tak_terduga("profil", i, exc)
            pengguna.append(p)
            if p is None:
                continue
            try:
                hasil = uji_rekomendasi(c, sesi, p, i, hari_ini, masukan)
                kat = Counter(h.kategori for h in hasil)
                rek_baris = {
                    rr.beasiswa_id: rr for rr in sesi.scalars(select(Rekomendasi).where(Rekomendasi.pengguna_id == p.id))
                }
                ringkas_profil.append(
                    {
                        "profil": i,
                        "jenjang": p.jenjang,
                        "semester": p.semester,
                        "ipk": str(p.ipk) if p.ipk is not None else None,
                        "negara": p.negara_domisili,
                        "provinsi": p.provinsi_domisili,
                        "kewarganegaraan": p.kewarganegaraan,
                        "memenuhi": kat.get(MEMENUHI, 0),
                        "hampir_memenuhi": kat.get(HAMPIR, 0),
                        "belum_memenuhi": kat.get(BELUM, 0),
                    }
                )
            except Exception as exc:
                c.galat_tak_terduga("rekomendasi", i, exc)
                rek_baris = {}
            try:
                uji_detail(c, sesi, p, i, hari_ini, rek_baris, sepuluh)
            except Exception as exc:
                c.galat_tak_terduga("detail_beasiswa", i, exc)
            try:
                uji_invarian(c, sesi, p, i, hari_ini, masukan, r)
            except Exception as exc:
                c.galat_tak_terduga("invarian", i, exc)
            try:
                uji_cv(c, i, profil_semua[i], acc)
            except Exception as exc:
                c.galat_tak_terduga("pembaca_cv", i, exc)
            try:
                uji_chat(c, sesi, p, i, hari_ini)
            except Exception as exc:
                c.galat_tak_terduga("chat", i, exc)

        # data sintetik (hanya di dalam transaksi) untuk uji aktivitas
        sumber = Sumber(nama="Uji80 sumber", url=f"https://uji80.invalid/{uuid.uuid4().hex}", jenis="input_manual")
        sesi.add(sumber)
        sesi.flush()

        def buat_beasiswa(nama: str, tenggat: date | None) -> Beasiswa:
            b = Beasiswa(
                sumber_id=sumber.id,
                nama=nama,
                penyelenggara="Uji80",
                tautan_resmi="https://uji80.invalid/b",
                status="terbit",
                tenggat=tenggat,
                sidik_isi=uuid.uuid4().hex,
            )
            sesi.add(b)
            sesi.flush()
            return b

        sint_b = buat_beasiswa("Uji80 Beasiswa Jauh", hari_ini + timedelta(days=60))
        sint_dekat = buat_beasiswa("Uji80 Beasiswa Dekat", hari_ini + timedelta(days=3))
        sint_lewat = buat_beasiswa("Uji80 Beasiswa Lewat", hari_ini - timedelta(days=1))
        for bb in (sint_b, sint_dekat, sint_lewat):
            sesi.add_all(
                [BerkasWajib(beasiswa_id=bb.id, nama_berkas="KTP"), BerkasWajib(beasiswa_id=bb.id, nama_berkas="Transkrip")]
            )
        sesi.flush()
        sintetik = {"b": sint_b, "dekat": sint_dekat, "kedaluwarsa": sint_lewat}
        # beasiswa kedaluwarsa tidak boleh muncul pada rekomendasi, detail, dan pencarian chat
        valid = [p for p in pengguna if p is not None]
        for i, p in enumerate(pengguna):
            if p is None:
                continue
            try:
                lain = valid[(valid.index(p) + 1) % len(valid)]
                uji_aktivitas(c, sesi, p, lain, i, hari_ini, sintetik)
                ids = {b.id for _, b in svc_rek.daftar(sesi, p, hari_ini, None, paksa=True)}
                c.cek("aktivitas", i, sint_lewat.id not in ids, "beasiswa sintetik kedaluwarsa muncul pada rekomendasi")
                c.cek(
                    "aktivitas",
                    i,
                    sint_b.id in ids and sint_dekat.id in ids,
                    "beasiswa sintetik aktif tidak muncul pada rekomendasi",
                )
                c.invarian("tenggat_lewat_sintetik", i, sint_lewat.id not in ids, "beasiswa kedaluwarsa sintetik tampil")
                cari = svc_chat.cari_beasiswa(sesi, "Uji80 beasiswa lewat dekat jauh", hari_ini)
                c.cek("chat", i, sint_lewat.id not in {b.id for b in cari}, "chat memuat beasiswa kedaluwarsa")
                detail_ok = True
                try:
                    from app.repositories.beasiswa import BeasiswaRepoSql

                    BeasiswaRepoSql(sesi).detail(sint_lewat.id, hari_ini)
                    detail_ok = BeasiswaRepoSql(sesi).detail(sint_lewat.id, hari_ini) is None
                except Exception:
                    detail_ok = False
                c.cek("detail_beasiswa", i, detail_ok, "detail beasiswa kedaluwarsa dapat dibuka")
            except Exception as exc:
                c.galat_tak_terduga("aktivitas", i, exc)
        info["profil"] = ringkas_profil
    finally:
        try:
            sesi.close()
        finally:
            luar.rollback()
            conn.close()
    sesudah = hitung_tabel(engine)
    utuh = sebelum == sesudah
    durasi = round(time.time() - mulai, 1)

    # ------------------------------------------------------------------ ringkasan
    tabel = {}
    for f in FITUR:
        ids = sorted(i for i in c.dijalankan[f] if i >= 0)
        lulus = [i for i in ids if not c.skenario[(f, i)]]
        tabel[f] = {
            "skenario": len(ids),
            "lulus": len(lulus),
            "gagal": [i for i in ids if c.skenario[(f, i)]],
            "cek": c.cek_total[f],
        }
    gagal_detail = {f"{f}:{i}": c.skenario[(f, i)][:8] for (f, i) in c.skenario if c.skenario[(f, i)] and i >= 0}
    keluaran = {
        "tanggal": hari_ini.isoformat(),
        "durasi_detik": durasi,
        "jumlah_profil": args.jumlah,
        "benih": args.benih,
        "info": {k: v for k, v in info.items() if k != "profil"},
        "tabel_sebelum": sebelum,
        "tabel_sesudah": sesudah,
        "tidak_ada_data_tersimpan": utuh,
        "per_fitur": tabel,
        "akurasi_cv": {
            k: {"benar": v[0], "total": v[1], "persen": round(100 * v[0] / v[1], 1) if v[1] else None}
            for k, v in acc.items()
        },
        "invarian": {
            nama: {"diperiksa": c.cek_total[f"inv:{nama}"], "pelanggaran": len(v), "contoh": v[:5]}
            for nama, v in sorted(c.pelanggaran.items())
        },
        "invarian_diperiksa": {k[4:]: v for k, v in sorted(c.cek_total.items()) if k.startswith("inv:")},
        "galat_tak_terduga": c.galat[:40],
        "rincian_gagal": gagal_detail,
        "profil": info.get("profil", []),
        "profil_masukan": profil_semua,
    }
    with open(args.keluaran, "w", encoding="utf8") as fh:
        json.dump(keluaran, fh, ensure_ascii=False, indent=1, default=str)
    print(f"selesai {durasi}s; data utuh: {utuh}; sebelum={sebelum} sesudah={sesudah}")
    for f, t in tabel.items():
        print(f"{f:18s} {t['lulus']:3d}/{t['skenario']:3d} lulus ({t['cek']} cek)")
    print("akurasi CV:", keluaran["akurasi_cv"])
    print("pelanggaran invarian:", {k: v["pelanggaran"] for k, v in keluaran["invarian"].items()})
    print("galat tak terduga:", len(c.galat))
    return 0 if utuh else 1


if __name__ == "__main__":
    raise SystemExit(main())
