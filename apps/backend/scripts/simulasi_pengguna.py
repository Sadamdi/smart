"""Membuat pengguna SIMULASI beserta interaksinya untuk melatih pemeringkat LightGBM, atau menghapusnya.

Pengguna simulasi bukan mahasiswa nyata. Alamat surelnya selalu simulasi<nomor>@sim.smart.invalid sehingga mudah dikenali
dan dihapus. Perilakunya (klik, simpan, rencana daftar) dibangkitkan dari model preferensi acak per pengguna dengan derau
dan bias posisi, sehingga bukan fungsi persis dari fitur. Model yang dilatih darinya wajib disebut "dilatih dari
pengguna simulasi", bukan dari perilaku mahasiswa nyata.

Pemakaian (dari apps/backend, DATABASE_URL di .env):
    uv run python -m scripts.simulasi_pengguna --buat 60
    uv run python -m scripts.simulasi_pengguna --hapus
"""

import argparse
import math
import random
import secrets
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import create_engine, delete, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import hash_sandi
from app.models import Interaksi, Pengguna, Rekomendasi
from app.rekomendasi.mesin import susun
from app.services.rekomendasi import _masukan, profil_dari, teks_tambahan

DOMAIN = "sim.smart.invalid"
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
]
PRODI = [
    "Teknik Informatika",
    "Sistem Informasi",
    "Kedokteran",
    "Akuntansi",
    "Manajemen",
    "Pendidikan Guru",
    "Hukum Ekonomi Syariah",
    "Biologi",
    "Agroteknologi",
    "Psikologi",
]
KOTA = [
    ("Malang", "Jawa Timur"),
    ("Surabaya", "Jawa Timur"),
    ("Jakarta", "DKI Jakarta"),
    ("Bandung", "Jawa Barat"),
    ("Yogyakarta", "DI Yogyakarta"),
    ("Semarang", "Jawa Tengah"),
    ("Makassar", "Sulawesi Selatan"),
    ("Medan", "Sumatera Utara"),
    ("Kupang", "Nusa Tenggara Timur"),
    ("Banjarmasin", "Kalimantan Selatan"),
]
KONDISI = ["disabilitas", "ekonomi_kurang_mampu", "yatim_piatu", "daerah_3t"]


def _sigmoid(x: float) -> float:
    return 1.0 / (1.0 + math.exp(-x))


def hapus(sesi: Session) -> int:
    ids = list(sesi.scalars(select(Pengguna.id).where(Pengguna.email.like(f"%@{DOMAIN}"))))
    if ids:
        sesi.execute(delete(Interaksi).where(Interaksi.pengguna_id.in_(ids)))
        sesi.execute(delete(Rekomendasi).where(Rekomendasi.pengguna_id.in_(ids)))
        sesi.execute(delete(Pengguna).where(Pengguna.id.in_(ids)))
    sesi.commit()
    return len(ids)


def buat(sesi: Session, n: int, hari: date, benih: int = 11) -> tuple[int, int]:
    rnd = random.Random(benih)  # noqa: S311 (data simulasi, bukan kriptografi)
    hapus(sesi)
    masukan = _masukan(sesi, hari)
    if len(masukan) < 5:
        raise SystemExit("Beasiswa terbit terlalu sedikit untuk simulasi.")
    sandi = hash_sandi(secrets.token_urlsafe(24))  # tidak ada yang bisa masuk sebagai pengguna simulasi
    total_interaksi = 0
    for i in range(1, n + 1):
        kota, provinsi = rnd.choice(KOTA)
        jenjang = rnd.choices(["S1", "S2", "D3", "D4"], weights=[78, 14, 4, 4])[0]
        p = Pengguna(
            email=f"simulasi{i:03d}@{DOMAIN}",
            kata_sandi=sandi,
            nama=f"Pengguna Simulasi {i:03d}",
            kota_domisili=kota,
            kampus=rnd.choice(["Kampus Negeri Contoh", "Kampus Swasta Contoh"]),
            jenis_kampus=rnd.choice(["negeri", "negeri", "swasta"]),
            program_studi=rnd.choice(PRODI),
            jenjang=jenjang,
            semester=rnd.randint(1, 10) if jenjang != "S2" else rnd.randint(1, 4),
            ipk=round(rnd.uniform(2.7, 3.95), 2),
            minat=rnd.sample(MINAT, rnd.randint(2, 3)),
            penghasilan_orang_tua=rnd.choice([None, 1_500_000, 3_000_000, 6_000_000, 12_000_000]),
            kewarganegaraan="Indonesia",
            tanggal_lahir=date(rnd.randint(1999, 2006), rnd.randint(1, 12), rnd.randint(1, 28)),
            kondisi_khusus=[rnd.choice(KONDISI)] if rnd.random() < 0.18 else None,
            profil_lanjutan={
                "provinsi_asal": provinsi,
                "kota_asal": kota,
                "organisasi": [{"nama": f"Himpunan {rnd.choice(MINAT)}"}] if rnd.random() < 0.5 else [],
                "keahlian": rnd.sample(MINAT, 2),
            },
        )
        sesi.add(p)
        sesi.flush()
        hasil = susun(
            profil_dari(sesi, p),
            p.minat,
            p.program_studi,
            masukan,
            hari,
            kondisi_khusus=p.kondisi_khusus,
            catatan=teks_tambahan(p),
        )
        # selera tersembunyi per pengguna: bobot kelayakan, kemiripan, kesukaan tenggat longgar, dan ambang
        w_layak, w_mirip = rnd.uniform(0.8, 2.6), rnd.uniform(1.0, 3.2)
        suka_longgar = rnd.uniform(-0.4, 0.6)
        ambang = rnd.uniform(1.6, 2.6)
        for pos, h in enumerate(hasil):
            terlihat = 1.0 / (1.0 + 0.12 * pos)  # bias posisi: urutan atas lebih sering dilihat
            if rnd.random() > terlihat:
                continue
            u = w_layak * h.skor_kelayakan + w_mirip * h.skor_kemiripan + rnd.gauss(0, 0.55)
            if h.tenggat and (h.tenggat - hari).days > 14:
                u += suka_longgar
            if h.kategori == "belum_memenuhi":
                u -= 0.9
            if rnd.random() > _sigmoid(2.2 * (u - ambang)):
                continue
            waktu = datetime.now(UTC) - timedelta(days=rnd.randint(0, 28), hours=rnd.randint(0, 23))
            sesi.add(Interaksi(pengguna_id=p.id, beasiswa_id=h.beasiswa_id, aksi="klik", waktu=waktu))
            total_interaksi += 1
            if rnd.random() < _sigmoid(1.6 * (u - ambang - 0.3)):
                sesi.add(Interaksi(pengguna_id=p.id, beasiswa_id=h.beasiswa_id, aksi="simpan", waktu=waktu))
                total_interaksi += 1
                if h.kategori != "belum_memenuhi" and rnd.random() < _sigmoid(1.6 * (u - ambang - 0.6)):
                    sesi.add(
                        Interaksi(
                            pengguna_id=p.id,
                            beasiswa_id=h.beasiswa_id,
                            aksi="rencana_daftar",
                            status_rencana="akan_daftar",
                            waktu=waktu,
                        )
                    )
                    total_interaksi += 1
    sesi.commit()
    return n, total_interaksi


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--buat", type=int, metavar="N")
    ap.add_argument("--hapus", action="store_true")
    a = ap.parse_args()
    if bool(a.buat) == a.hapus:
        raise SystemExit("Pilih tepat satu: --buat N atau --hapus")
    settings = get_settings()
    if not settings.database_url:
        raise SystemExit("DATABASE_URL belum diisi")
    with Session(create_engine(settings.database_url)) as sesi:
        if a.hapus:
            print(f"{hapus(sesi)} pengguna simulasi dihapus.")
        else:
            if not 1 <= a.buat <= 500:
                raise SystemExit("N harus 1 sampai 500")
            pengguna, interaksi = buat(sesi, a.buat, date.today())
            print(f"{pengguna} pengguna simulasi dan {interaksi} interaksi dibuat.")


if __name__ == "__main__":
    main()
