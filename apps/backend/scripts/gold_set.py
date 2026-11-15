"""Gold set: 20 profil mahasiswa rekaan yang beragam, dan lima saran teratas mesin untuk tiap profil (hanya baca).

Keluaran JSON dipakai penilai (manusia) untuk menandai tiap saran relevan atau tidak, lalu skor Precision@5 dihitung dengan
`--nilai berkas_penilaian.json` (daftar {"profil": id, "beasiswa": nama, "relevan": true/false}).

Pemakaian (dari apps/backend):
    python -m scripts.gold_set --keluar gold_set_kandidat.json
    python -m scripts.gold_set --nilai penilaian.json
"""

import argparse
import json
from datetime import date

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Beasiswa, Persyaratan
from app.rekomendasi.kelayakan import ProfilKelayakan
from app.rekomendasi.mesin import susun
from app.services.rekomendasi import _masukan

PROFIL = [
    ("G01", "S1", 5, 3.60, "Negeri", "Malang", "Teknik Informatika", ["teknologi", "kecerdasan buatan", "riset"], 1500000),
    ("G02", "S1", 3, 3.10, "Swasta", "Surabaya", "Akuntansi", ["keuangan", "bisnis"], 3500000),
    ("G03", "S1", 7, 3.85, "Negeri", "Jakarta", "Kedokteran", ["kesehatan", "penelitian"], 20000000),
    ("G04", "S1", 2, 2.90, "Negeri", "Kupang", "Pendidikan Matematika", ["pendidikan", "daerah terpencil"], 500000),
    ("G05", "S2", 2, 3.70, "Negeri", "Bandung", "Teknik Elektro", ["energi terbarukan", "riset"], 8000000),
    ("G06", "S1", 6, 3.40, "Swasta", "Medan", "Ilmu Hukum", ["hukum", "kebijakan publik"], 3500000),
    ("G07", "D3", 4, 3.30, "Negeri", "Blitar", "Teknik Sipil", ["infrastruktur"], 1500000),
    ("G08", "S1", 8, 3.55, "Negeri", "Yogyakarta", "Biologi", ["lingkungan", "konservasi"], 8000000),
    ("G09", "S1", 4, 3.25, "Negeri", "Makassar", "Psikologi", ["kesehatan mental", "konseling"], 1500000),
    ("G10", "S1", 5, 3.50, "Negeri", "Malang", "Ekonomi Syariah", ["ekonomi syariah", "dakwah"], 500000),
    ("G11", "S1", 3, 3.80, "Negeri", "Jayapura", "Kesehatan Masyarakat", ["kesehatan", "gizi"], 500000),
    ("G12", "S1", 6, 3.00, "Swasta", "Denpasar", "Desain Komunikasi Visual", ["seni", "desain", "budaya"], 8000000),
    ("G13", "S2", 1, 3.60, "Negeri", "Jakarta", "Manajemen", ["bisnis", "kewirausahaan"], 20000000),
    ("G14", "S1", 7, 3.45, "Negeri", "Bogor", "Agroteknologi", ["pertanian", "pangan"], 1500000),
    ("G15", "S1", 2, 3.20, "Negeri", "Banda Aceh", "Sastra Inggris", ["bahasa", "penerjemahan"], 3500000),
    ("G16", "S3", 2, 3.90, "Negeri", "Surabaya", "Teknik Informatika", ["riset", "machine learning"], 8000000),
    ("G17", "S1", 5, 3.70, "Negeri", "Malang", "Sistem Informasi", ["data", "startup"], 3500000),
    ("G18", "D4", 5, 3.35, "Swasta", "Bandung", "Farmasi", ["kesehatan", "obat"], 1500000),
    ("G19", "S1", 4, 3.65, "Negeri", "Semarang", "Arsitektur", ["desain", "kota"], 8000000),
    ("G20", "S1", 9, 2.80, "Swasta", "Medan", "Ilmu Komunikasi", ["media", "jurnalistik"], 3500000),
]


def _profil(r) -> ProfilKelayakan:
    return ProfilKelayakan(
        jenjang=r[1],
        semester=r[2],
        ipk=r[3],
        jenis_kampus=r[4],
        kota_domisili=r[5],
        negara_domisili="Indonesia",
        provinsi_domisili=None,
        daerah_asal=[],
        tanggal_lahir=date(2004, 5, 5),
        penghasilan_orang_tua=r[8],
        skor_bahasa=None,
        kewarganegaraan="Indonesia",
        berkas_diunggah=[],
    )


def kandidat(keluar: str) -> None:
    sesi = Session(create_engine(get_settings().database_url))
    hari = date.today()
    masukan = _masukan(sesi, hari)
    info = {b.id: b for b in sesi.scalars(select(Beasiswa))}
    syarat: dict = {}
    for s in sesi.scalars(select(Persyaratan)):
        syarat.setdefault(s.beasiswa_id, []).append(f"{s.jenis}:{s.nilai_batas}")
    hasil = []
    for r in PROFIL:
        top = susun(_profil(r), r[7], r[6], masukan, hari)
        top = [h for h in top if h.kategori != "belum_memenuhi"][:5]
        hasil.append(
            {
                "profil": r[0],
                "jenjang": r[1],
                "semester": r[2],
                "ipk": r[3],
                "prodi": r[6],
                "minat": r[7],
                "kota": r[5],
                "saran": [
                    {
                        "beasiswa": info[h.beasiswa_id].nama,
                        "penyelenggara": info[h.beasiswa_id].penyelenggara,
                        "jenjang": info[h.beasiswa_id].jenjang,
                        "kategori": h.kategori,
                        "skor": round(h.skor, 3),
                        "syarat": syarat.get(h.beasiswa_id, [])[:6],
                    }
                    for h in top
                ],
            }
        )
    json.dump(hasil, open(keluar, "w", encoding="utf-8"), ensure_ascii=False, indent=1, default=str)
    print("profil", len(hasil), "->", keluar)


def nilai(berkas: str) -> None:
    n = json.load(open(berkas, encoding="utf-8"))
    per: dict[str, list[bool]] = {}
    for x in n:
        per.setdefault(x["profil"], []).append(bool(x["relevan"]))
    p5 = [sum(v[:5]) / 5 for v in per.values()]
    print("profil", len(per), "Precision@5 rata-rata", round(sum(p5) / len(p5), 3))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--keluar")
    ap.add_argument("--nilai")
    a = ap.parse_args()
    nilai(a.nilai) if a.nilai else kandidat(a.keluar or "gold_set_kandidat.json")
