"""Ekspor data dan kasus uji untuk mesin luring di perangkat (mobile): tabel wilayah dan berkas emas hasil perhitungan server.

Dijalankan dari apps/backend: uv run python scripts/ekspor_lokal.py
"""

import itertools
import json
from datetime import date
from pathlib import Path

from app.rekomendasi import wilayah as W
from app.rekomendasi.kelayakan import ProfilKelayakan, nilai_kelayakan
from app.rekomendasi.peluang import estimasi_peluang, kekuatan_profil
from app.services.kartu import metrik

TUJUAN = Path(__file__).resolve().parents[2] / "mobile"
HARI = date(2026, 11, 18)

SYARAT = [
    [],
    [("lainnya", {"teks": "Aktif berorganisasi"})],
    [("jenjang", {"nilai": ["S1"]})],
    [("jenjang", {"nilai": ["S2", "S3"]}), ("ipk_minimum", {"nilai": 3.25})],
    [("ipk_minimum", {"nilai": 3.0}), ("semester_minimum", {"nilai": 3})],
    [("ipk_minimum", {"nilai": 3.5}), ("semester_maksimum", {"nilai": 8}), ("jenjang", {"nilai": ["S1", "D4"]})],
    [("domisili", {"nilai": ["Jawa Timur"]}), ("jenjang", {"nilai": ["S1"]})],
    [("domisili", {"nilai": ["Kota Malang", "Kabupaten Malang"]}), ("ipk_minimum", {"nilai": 2.75})],
    [("domisili", {"nilai": ["Indonesia"]}), ("kewarganegaraan", {"nilai": ["WNI"]})],
    [("kewarganegaraan", {"nilai": ["Warga Negara Indonesia (WNI)"]}), ("ipk_minimum", {"nilai": 3.0})],
    [("kewarganegaraan", {"nilai": ["All countries"]}), ("sertifikat_bahasa", {"nilai": 520, "jenis": "toefl"})],
    [("sertifikat_bahasa", {"nilai": 6.5, "jenis": "ielts"}), ("ipk_minimum", {"nilai": 3.0})],
    [("jenis_kampus", {"nilai": ["PTN"]}), ("ipk_minimum", {"nilai": 3.0})],
    [("usia_maksimum", {"nilai": 25}), ("ipk_minimum", {"nilai": 3.0})],
    [("penghasilan_maksimum", {"nilai": 5000000}), ("jenjang", {"nilai": ["S1"]})],
    [("berkas_pendukung", {"nama": "CV"}), ("ipk_minimum", {"nilai": 3.0})],
    [("domisili", {"nilai": ["Warga Kota Malang"]}), ("ipk_minimum", {"nilai": 3.0})],
    [("lainnya", {"teks": "Ditujukan bagi siswa SMA"}), ("jenjang", {"nilai": ["S1"]}), ("ipk_minimum", {"nilai": 3.0})],
    [("lainnya", {"teks": "Khusus mahasiswa Universitas Brawijaya"}), ("ipk_minimum", {"nilai": 3.0})],
    [("jenjang", {"nilai": ["S2"]}), ("ipk_minimum", {"nilai": 3.0}), ("sertifikat_bahasa", {"nilai": 500, "jenis": "toefl"})],
    [("domisili", {"nilai": ["Papua"]}), ("kewarganegaraan", {"nilai": ["Indonesia"]}), ("ipk_minimum", {"nilai": 3.0})],
    [("kewarganegaraan", {"nilai": ["bukan Indonesia"]}), ("ipk_minimum", {"nilai": 3.0})],
]

PROFIL = [
    dict(),
    dict(jenjang="S1", semester=5, ipk=3.55, jenis_kampus="PTN", kota_domisili="Malang", negara_domisili="Indonesia", provinsi_domisili="Jawa Timur", kewarganegaraan="WNI", skor_bahasa={"toefl": 520}, tanggal_lahir="2004-05-10", penghasilan_orang_tua=3000000, berkas_diunggah=["cv", "CV"]),
    dict(jenjang="S1", semester=8, ipk=2.4, jenis_kampus="PTS", kota_domisili="Surabaya", provinsi_domisili="Jatim", kewarganegaraan="Indonesia", skor_bahasa={"IELTS": "6,0"}, tanggal_lahir="1999-01-01", penghasilan_orang_tua=9000000, jenjang_tuju=["S2"]),
    dict(jenjang="D3", semester=3, ipk=3.0, kota_domisili="Jayapura", kewarganegaraan="Warga Negara Indonesia"),
    dict(jenjang="S2", semester=3, ipk=3.8, negara_domisili="Singapore", kewarganegaraan="Singapore", skor_bahasa={"toefl": 600}),
    dict(jenjang="S1", semester=7, ipk=3.2, daerah_asal=["Malang", "Jawa Timur"], kota_domisili="Bandung", provinsi_domisili="Jawa Barat", kewarganegaraan="WNI"),
    dict(jenjang="S3", semester=1, ipk=3.9, jenjang_tuju=["S3"], kewarganegaraan="Indonesia"),
    dict(jenjang="S1", semester=2, ipk=3.0, skor_bahasa={"toefl": 480}, negara_domisili="Indonesia"),
]

LANJUTAN = [
    None,
    {"prestasi": [{"tingkat": "nasional"}, {"tingkat": "provinsi"}], "organisasi": [1, 2], "sertifikat": [1], "pengalaman": [1]},
    {"prestasi": [{"tingkat": "internasional"}] * 3, "organisasi": [1, 2, 3], "sertifikat": [1, 2, 3], "pengalaman": [1, 2]},
]

BEASISWA = [
    ("Beasiswa Prestasi Nusantara", "Yayasan A", False, None),
    ("Beasiswa LPDP Reguler", "LPDP", False, 0.2),
    ("Chevening Scholarships", "Pemerintah Inggris", True, None),
    ("KIP Kuliah", "Kemdikbud", False, None),
]


def _profil(d):
    d = dict(d)
    if "tanggal_lahir" in d:
        d["tanggal_lahir"] = date.fromisoformat(d["tanggal_lahir"])
    d["berkas_diunggah"] = set(d.get("berkas_diunggah", []))
    return ProfilKelayakan(**d)


def main() -> None:
    wil = {
        "negara": W._KUNCI_NEGARA,
        "provinsi": W._KUNCI_PROVINSI,
        "kota": W._KOTA_PROVINSI,
        "negara_asal": W.NEGARA_ASAL,
    }
    (TUJUAN / "assets" / "data" / "wilayah.json").write_text(json.dumps(wil, ensure_ascii=False), encoding="utf-8")

    kasus = []
    for (si, s), (pi, p), (li, pl), (bi, (nama, peny, luar, dasar)) in itertools.product(
        enumerate(SYARAT), enumerate(PROFIL), enumerate(LANJUTAN), enumerate(BEASISWA)
    ):
        if (si + pi + li + bi) % 3:  # ambil sebagian saja agar berkas emas tetap kecil
            continue
        hasil = nilai_kelayakan(s, _profil(p), HARI)
        m = metrik(hasil.skor, hasil.alasan, hasil.catatan_kekurangan)
        kuat = kekuatan_profil(p.get("ipk"), pl, p.get("skor_bahasa"))
        est = estimasi_peluang(
            kategori=hasil.kategori,
            ada_syarat_terukur=m["syarat_total"] > 0,
            nama=nama,
            penyelenggara=peny,
            luar_negeri=luar,
            kekuatan=kuat,
            dasar_statistik=dasar,
            jumlah_syarat=m["syarat_total"],
        )
        kasus.append(
            {
                "profil": p,
                "lanjutan": pl,
                "syarat": [[j, b] for j, b in s],
                "beasiswa": {"nama": nama, "penyelenggara": peny, "luar_negeri": luar, "dasar_statistik": dasar},
                "hasil": {
                    "kategori": hasil.kategori,
                    "skor": hasil.skor,
                    "alasan": hasil.alasan,
                    "catatan": hasil.catatan_kekurangan,
                    "metrik": m,
                    "kekuatan": kuat,
                    "estimasi": est,
                },
            }
        )
    (TUJUAN / "test" / "golden_lokal.json").write_text(
        json.dumps({"hari_ini": HARI.isoformat(), "kasus": kasus}, ensure_ascii=False), encoding="utf-8"
    )
    print("kasus:", len(kasus))


if __name__ == "__main__":
    main()
