"""Menguji algoritma dengan beberapa profil sintetis terhadap beasiswa terbit sebenarnya (hanya baca, tidak menulis).

Jalankan di server: python -m scripts.simulasi_profil
"""

from collections import Counter
from datetime import date
from types import SimpleNamespace

from sqlalchemy import select

from app.db import sesi_baru
from app.models import Beasiswa
from app.rekomendasi.kelayakan import ProfilKelayakan
from app.rekomendasi.mesin import susun
from app.services import rekomendasi as rek
from app.services.kartu import luar_negeri, peluang_untuk

KUAT = {
    "prestasi": [{"nama": "Juara OSN", "tingkat": "nasional"}, {"nama": "Juara lomba", "tingkat": "provinsi"}],
    "organisasi": [{"nama": "BEM"}, {"nama": "HMJ"}, {"nama": "UKM"}],
    "sertifikat": [{"nama": "TOEFL"}, {"nama": "Dicoding"}, {"nama": "Panitia", "jenis": "kepanitiaan"}],
    "pengalaman": [{"nama": "Magang"}, {"nama": "Relawan"}],
}

PROFIL = {
    "A. S1 kuat (IPK 3,85, prestasi nasional, TOEFL 560)": dict(
        p=dict(jenjang="S1", semester=5, ipk=3.85, jenis_kampus="negeri", skor_bahasa={"toefl": 560}),
        pl=KUAT,
        minat=["teknologi", "riset"],
        prodi="Teknik Informatika",
    ),
    "B. S1 rata-rata (IPK 3,2, tanpa isian CV)": dict(
        p=dict(jenjang="S1", semester=3, ipk=3.2, jenis_kampus="swasta"), pl={}, minat=[], prodi="Manajemen"
    ),
    "C. D3 vokasi kurang mampu (IPK 3,0)": dict(
        p=dict(jenjang="D3", semester=4, ipk=3.0, jenis_kampus="swasta", penghasilan_orang_tua=1500000),
        pl={},
        minat=["teknik"],
        prodi="Teknik Mesin",
    ),
    "D. S1 tingkat akhir kejar S2 luar negeri (sem 8, IPK 3,7, IELTS 7)": dict(
        p=dict(jenjang="S1", semester=8, ipk=3.7, jenis_kampus="negeri", skor_bahasa={"ielts": 7.0}),
        pl=KUAT,
        minat=["riset"],
        prodi="Fisika",
    ),
    "E. S2 kejar S3 (IPK 3,8, IELTS 7)": dict(
        p=dict(jenjang="S2", semester=3, ipk=3.8, jenis_kampus="negeri", skor_bahasa={"ielts": 7.0}),
        pl=KUAT,
        minat=["riset", "kebijakan"],
        prodi="Ilmu Politik",
    ),
}


def main() -> None:
    hari = date.today()
    with sesi_baru() as sesi:
        masukan = rek._masukan(sesi, hari)
        beasiswa = {b.id: b for b in sesi.scalars(select(Beasiswa))}
    print(f"Beasiswa dinilai: {len(masukan)}")
    for nama, cfg in PROFIL.items():
        profil = ProfilKelayakan(
            kewarganegaraan="Indonesia",
            negara_domisili="Indonesia",
            kota_domisili="Malang",
            provinsi_domisili="Jawa Timur",
            **cfg["p"],
        )
        hasil = susun(profil, cfg["minat"], cfg["prodi"], masukan, hari)
        per = {"dalam": Counter(), "luar": Counter()}
        peng = SimpleNamespace(ipk=cfg["p"].get("ipk"), profil_lanjutan=cfg["pl"], skor_bahasa=cfg["p"].get("skor_bahasa"))
        baris = []
        for h in hasil:
            b = beasiswa[h.beasiswa_id]
            per["luar" if luar_negeri(b.negara) else "dalam"][h.kategori] += 1
            e = peluang_untuk(peng, b, h.kategori, h.skor_kelayakan, h.alasan, h.catatan_kekurangan)
            if e["estimasi_peluang"] is not None:
                baris.append((e["estimasi_peluang"], h.kategori, b.nama[:62], ",".join(b.jenjang or [])))
        print(f"\n== {nama}")
        for w in ("dalam", "luar"):
            c = per[w]
            print(f"  {w}: memenuhi {c['memenuhi']}, hampir {c['hampir_memenuhi']}, belum {c['belum_memenuhi']}")
        baris.sort(reverse=True)
        for pel, kat, nm, jj in baris[:6]:
            print(f"   {pel:>3}% {kat[:9]:9} {nm} [{jj}]")


if __name__ == "__main__":
    main()
