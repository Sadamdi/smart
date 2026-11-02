"""Data DEMONSTRASI untuk presentasi dan uji manual. Bukan data beasiswa nyata.

Setiap beasiswa diberi awalan "[DEMO]", tautannya memakai domain contoh, dan tenggatnya dihitung dari hari ini. Dua akun demo
(mahasiswa dan admin) dibuat dengan kata sandi acak yang ditulis ke Dokument/local/AKUN-DEMO.md (diabaikan git).
Aman diulang. Hapus semuanya dengan --hapus.

Pemakaian (dari apps/backend, DATABASE_URL di .env):
    uv run python -m scripts.seed_demo --konfirmasi
    uv run python -m scripts.seed_demo --hapus
"""

import argparse
import secrets
from datetime import date, timedelta
from pathlib import Path

from sqlalchemy import create_engine, delete, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import hash_sandi
from app.models import Beasiswa, BerkasWajib, Pengguna, Persyaratan, Sumber

URL_SUMBER = "demo://smart"
EMAIL_MHS = "demo.mahasiswa@example.com"
EMAIL_ADMIN = "demo.admin@example.com"
BERKAS_AKUN = Path(__file__).resolve().parents[3] / "Dokument" / "local" / "AKUN-DEMO.md"

# (nama, penyelenggara, jenjang, hari ke tenggat, manfaat, syarat [(jenis, batas, dapat_dikejar)], berkas)
DEMO = [
    (
        "Beasiswa Prestasi Teknologi",
        "Yayasan Contoh Teknologi",
        ["S1"],
        21,
        "Biaya kuliah per semester dan dana pembinaan",
        [("ipk_minimum", {"nilai": 3.0}, True), ("jenjang", {"nilai": ["S1"]}, False)],
        ["Transkrip nilai", "KTP", "Esai motivasi"],
    ),
    (
        "Beasiswa Riset Muda",
        "Lembaga Riset Contoh",
        ["S1", "S2"],
        35,
        "Dana riset dan pendampingan peneliti",
        [("ipk_minimum", {"nilai": 3.6}, True), ("semester_minimum", {"nilai": 6}, True)],
        ["Proposal riset", "Transkrip nilai"],
    ),
    (
        "Beasiswa Pemimpin Kampus Negeri",
        "Kementerian Contoh",
        ["S1"],
        28,
        "Tunjangan bulanan dan pelatihan kepemimpinan",
        [("jenis_kampus", {"nilai": "negeri"}, False), ("ipk_minimum", {"nilai": 3.25}, True)],
        ["Surat rekomendasi dosen", "Transkrip nilai", "SK organisasi"],
    ),
    (
        "Beasiswa Pascasarjana Dalam Negeri",
        "Dana Pendidikan Contoh",
        ["S2"],
        45,
        "Biaya pendidikan penuh dan tunjangan hidup",
        [("jenjang", {"nilai": ["S2"]}, False), ("ipk_minimum", {"nilai": 3.5}, True)],
        ["Ijazah S1", "Rencana studi"],
    ),
    (
        "Beasiswa Bahasa dan Budaya Luar Negeri",
        "Lembaga Pertukaran Contoh",
        ["S1", "S2"],
        60,
        "Tiket pergi pulang, tunjangan hidup, dan kursus bahasa",
        [("sertifikat_bahasa", {"jenis": "toefl", "nilai": 500}, True), ("usia_maksimum", {"nilai": 25}, False)],
        ["Paspor", "Sertifikat bahasa", "Surat rekomendasi"],
    ),
    (
        "Beasiswa Wirausaha Mahasiswa",
        "Yayasan Contoh Usaha",
        ["D3", "D4", "S1"],
        18,
        "Modal usaha dan pendampingan bisnis",
        [("semester_maksimum", {"nilai": 8}, False)],
        ["Rencana usaha", "KTM"],
    ),
    (
        "Beasiswa Bantuan Biaya Pendidikan",
        "Pemerintah Daerah Contoh",
        ["D3", "D4", "S1"],
        50,
        "Bantuan biaya kuliah",
        [("penghasilan_maksimum", {"nilai": 4000000}, False), ("domisili", {"nilai": ["Malang", "Jawa Timur"]}, False)],
        ["Surat keterangan penghasilan", "KTP"],
    ),
    (
        "Beasiswa Kecerdasan Buatan",
        "Perusahaan Teknologi Contoh",
        ["S1"],
        14,
        "Uang saku bulanan dan program magang",
        [("ipk_minimum", {"nilai": 3.7}, True), ("semester_minimum", {"nilai": 5}, True)],
        ["Transkrip nilai", "Portofolio", "Surat rekomendasi dosen"],
    ),
]


def _mesin():
    url = get_settings().database_url
    if not url:
        raise SystemExit("DATABASE_URL belum diisi di apps/backend/.env")
    return create_engine(url)


def hapus() -> None:
    with Session(_mesin()) as sesi:
        sumber = sesi.scalar(select(Sumber).where(Sumber.url == URL_SUMBER))
        if sumber is not None:
            sesi.execute(delete(Beasiswa).where(Beasiswa.sumber_id == sumber.id))
            sesi.delete(sumber)
        sesi.execute(delete(Pengguna).where(Pengguna.email.in_([EMAIL_MHS, EMAIL_ADMIN])))
        sesi.commit()
    BERKAS_AKUN.unlink(missing_ok=True)
    print("Data demo dihapus.")


def isi() -> None:
    hari = date.today()
    with Session(_mesin()) as sesi:
        sumber = sesi.scalar(select(Sumber).where(Sumber.url == URL_SUMBER))
        if sumber is None:
            sumber = Sumber(
                nama="Data demonstrasi SMART", url=URL_SUMBER, jenis="input_manual", aktif=False, status_terakhir="berhasil"
            )
            sesi.add(sumber)
            sesi.flush()
        baru = 0
        for nama, penyelenggara, jenjang, hari_ke, manfaat, syarat, berkas in DEMO:
            judul = f"[DEMO] {nama}"
            b = sesi.scalar(select(Beasiswa).where(Beasiswa.sumber_id == sumber.id, Beasiswa.nama == judul))
            if b is None:
                b = Beasiswa(
                    sumber_id=sumber.id,
                    nama=judul,
                    penyelenggara=penyelenggara,
                    negara="Indonesia",
                    jenjang=jenjang,
                    manfaat=manfaat,
                    tautan_resmi="https://smart.example/demo/" + nama.lower().replace(" ", "-"),
                    status="terbit",
                    sidik_isi=nama,
                )
                sesi.add(b)
                sesi.flush()
                for jenis, batas, kejar in syarat:
                    sesi.add(Persyaratan(beasiswa_id=b.id, jenis=jenis, nilai_batas=batas, dapat_dikejar=kejar))
                for nama_berkas in berkas:
                    sesi.add(BerkasWajib(beasiswa_id=b.id, nama_berkas=nama_berkas))
                baru += 1
            b.tenggat = hari + timedelta(days=hari_ke)  # tenggat selalu relatif terhadap hari ini
            b.status = "terbit"
        akun: list[tuple[str, str, str]] = []
        for email, nama, peran in ((EMAIL_MHS, "Mahasiswa Demo", "mahasiswa"), (EMAIL_ADMIN, "Admin Demo", "admin")):
            sandi = secrets.token_urlsafe(12)
            p = sesi.scalar(select(Pengguna).where(Pengguna.email == email))
            if p is None:
                p = Pengguna(email=email, nama=nama, peran=peran, kata_sandi=hash_sandi(sandi))
                if peran == "mahasiswa":
                    p.kampus, p.jenis_kampus, p.program_studi = (
                        "UIN Maulana Malik Ibrahim Malang",
                        "negeri",
                        "Teknik Informatika",
                    )
                    p.jenjang, p.semester, p.ipk, p.minat = "S1", 5, 3.55, ["teknologi", "riset", "kepemimpinan"]
                    p.kota_domisili, p.kewarganegaraan = "Malang", "Indonesia"
                sesi.add(p)
                akun.append((peran, email, sandi))
        sesi.commit()
    if akun:
        BERKAS_AKUN.parent.mkdir(parents=True, exist_ok=True)
        BERKAS_AKUN.write_text(
            "# Akun demo (lokal, diabaikan git)\n\n| Peran | Email | Kata sandi |\n| --- | --- | --- |\n"
            + "".join(f"| {p} | {e} | {s} |\n" for p, e, s in akun),
            encoding="utf8",
        )
        print(f"Akun demo dibuat; kata sandi ada di {BERKAS_AKUN}")
    print(f"{baru} beasiswa demo baru; {len(DEMO)} beasiswa demo terbit dengan tenggat relatif hari ini.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--konfirmasi", action="store_true", help="wajib untuk mengisi data demo")
    ap.add_argument("--hapus", action="store_true", help="hapus semua data demo")
    a = ap.parse_args()
    if a.hapus:
        hapus()
    elif a.konfirmasi:
        isi()
    else:
        raise SystemExit("Tambahkan --konfirmasi (isi) atau --hapus.")
