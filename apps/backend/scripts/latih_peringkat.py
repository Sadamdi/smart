"""Melatih model pemeringkat LightGBM dan menyimpannya ke model_peringkat_path (default data/model/peringkat.lgb).

Dua mode (dari apps/backend, DATABASE_URL di .env):

    uv run python -m scripts.latih_peringkat --dari-interaksi
        Memakai interaksi nyata (klik, simpan, rencana daftar). Menolak berjalan bila data terlalu sedikit
        (kurang dari 20 pengguna atau 200 pasangan), supaya model tidak dilatih dari data yang tidak cukup.

    uv run python -m scripts.latih_peringkat --demo-sintetis
        Memakai pengguna SINTETIS yang diberi label oleh aturan preferensi buatan. Hanya untuk memperagakan alur
        (fitur, pelatihan, urutan ulang, penjelasan SHAP). Versi model diberi awalan "demo-sintetis" dan tidak boleh
        disebut sebagai model yang dilatih dari perilaku mahasiswa nyata.

Evaluasi Precision@5 terhadap gold set dihitung dengan app.rekomendasi.peringkat.precision_at_k setelah tim menyusun
gold set (penilaian manusia atas pasangan mahasiswa dan beasiswa).
"""

import argparse
import random
import uuid
from collections import defaultdict
from datetime import date

import numpy as np
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Interaksi, Pengguna
from app.rekomendasi.kelayakan import ProfilKelayakan
from app.rekomendasi.mesin import HasilRekomendasi, susun
from app.rekomendasi.peringkat import fitur_dari, latih, simpan
from app.services.rekomendasi import _masukan, profil_dari, teks_tambahan

MIN_PENGGUNA = 20
MIN_PASANGAN = 200
LABEL_AKSI = {"klik": 1, "simpan": 2, "rencana_daftar": 3}


DOMAIN_SIMULASI = "@sim.smart.invalid"


def _kumpulkan(sesi: Session, hari: date, hanya_simulasi: bool = False) -> tuple[np.ndarray, np.ndarray, list[int]]:
    inter: dict[uuid.UUID, dict[uuid.UUID, int]] = defaultdict(dict)
    for i in sesi.scalars(select(Interaksi)):
        lama = inter[i.pengguna_id].get(i.beasiswa_id, 0)
        inter[i.pengguna_id][i.beasiswa_id] = max(lama, LABEL_AKSI.get(i.aksi, 0))
    masukan = _masukan(sesi, hari)
    x: list[list[float]] = []
    y: list[int] = []
    grup: list[int] = []
    for pid, label in inter.items():
        p = sesi.get(Pengguna, pid)
        if p is None or (hanya_simulasi and not p.email.endswith(DOMAIN_SIMULASI)):
            continue
        hasil = susun(
            profil_dari(sesi, p),
            p.minat,
            p.program_studi,
            masukan,
            hari,
            kondisi_khusus=p.kondisi_khusus,
            catatan=teks_tambahan(p),
        )
        if len(hasil) < 2:
            continue
        for h in hasil:
            x.append(fitur_dari(h, hari))
            y.append(label.get(h.beasiswa_id, 0))
        grup.append(len(hasil))
    return np.array(x), np.array(y), grup


def _sintetis(sesi: Session, hari: date, n: int = 120) -> tuple[np.ndarray, np.ndarray, list[int]]:
    rnd = random.Random(7)  # noqa: S311 (data sintetis, bukan kriptografi)
    masukan = _masukan(sesi, hari)
    minat_bank = ["teknologi", "riset", "kepemimpinan", "kesehatan", "bisnis", "seni", "pendidikan", "lingkungan"]
    x: list[list[float]] = []
    y: list[int] = []
    grup: list[int] = []
    for _ in range(n):
        profil = ProfilKelayakan(
            jenjang=rnd.choice(["S1", "S1", "S2"]),
            semester=rnd.randint(1, 10),
            ipk=round(rnd.uniform(2.6, 3.95), 2),
            jenis_kampus=rnd.choice(["negeri", "swasta"]),
            kota_domisili=rnd.choice(["Malang", "Surabaya", "Jakarta"]),
            kewarganegaraan="Indonesia",
        )
        hasil: list[HasilRekomendasi] = susun(profil, rnd.sample(minat_bank, 3), "Teknik Informatika", masukan, hari)
        if len(hasil) < 2:
            continue
        for h in hasil:
            # preferensi buatan: lebih suka yang memenuhi, mirip, dan tenggat tidak terlalu mepet; ditambah derau
            nilai = 2.0 * h.skor_kelayakan + 2.5 * h.skor_kemiripan + rnd.gauss(0, 0.25)
            nilai += 0.3 if h.tenggat and (h.tenggat - hari).days > 10 else 0
            y.append(3 if nilai > 2.6 else 2 if nilai > 2.0 else 1 if nilai > 1.5 else 0)
            x.append(fitur_dari(h, hari))
        grup.append(len(hasil))
    return np.array(x), np.array(y), grup


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dari-interaksi", action="store_true")
    ap.add_argument("--demo-sintetis", action="store_true")
    ap.add_argument("--simulasi", action="store_true", help="dengan --dari-interaksi: hanya pengguna simulasi")
    a = ap.parse_args()
    if a.dari_interaksi == a.demo_sintetis:
        raise SystemExit("Pilih tepat satu: --dari-interaksi atau --demo-sintetis")
    settings = get_settings()
    if not settings.database_url:
        raise SystemExit("DATABASE_URL belum diisi")
    hari = date.today()
    with Session(create_engine(settings.database_url)) as sesi:
        if a.dari_interaksi:
            x, y, grup = _kumpulkan(sesi, hari, a.simulasi)
            if len(grup) < MIN_PENGGUNA or len(y) < MIN_PASANGAN:
                raise SystemExit(
                    f"Data interaksi belum cukup ({len(grup)} pengguna, {len(y)} pasangan; butuh "
                    f"{MIN_PENGGUNA} pengguna dan {MIN_PASANGAN} pasangan). Model tidak dilatih."
                )
            versi = f"lgbm-simulasi-{len(grup)}pengguna-{hari:%Y%m%d}" if a.simulasi else f"lgbm-interaksi-{hari:%Y%m%d}"
        else:
            x, y, grup = _sintetis(sesi, hari)
            versi = f"lgbm-demo-sintetis-{hari:%Y%m%d}"
    if len(grup) == 0:
        raise SystemExit("Tidak ada beasiswa terbit untuk dijadikan data latih.")
    model = latih(x, y, grup, versi)
    simpan(model, settings.model_peringkat_path)
    print(
        f"Model {versi} dilatih dari {len(grup)} kelompok dan {len(y)} pasangan; disimpan di {settings.model_peringkat_path}."
    )


if __name__ == "__main__":
    main()
