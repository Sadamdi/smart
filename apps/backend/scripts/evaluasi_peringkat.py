"""Mengevaluasi pemeringkat LightGBM terhadap urutan skor gabungan pada pengguna yang TIDAK dipakai melatih.

Data: interaksi pengguna simulasi (lihat scripts/simulasi_pengguna.py). Pengguna dibagi acak 80 persen untuk melatih dan 20 persen
untuk menguji. Relevan = beasiswa yang disimpan atau direncanakan (label 2 atau 3). Hasil adalah ukuran pada data simulasi dan
BUKAN bukti kualitas pada mahasiswa nyata.

Pemakaian (dari apps/backend): uv run python -m scripts.evaluasi_peringkat [laporan.json]
"""

import json
import random
import sys
from datetime import date

import numpy as np
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.rekomendasi.peringkat import latih
from scripts.latih_peringkat import _kumpulkan

K = 5
LIPATAN = 5


def _p_at_k(label: np.ndarray, urutan: np.ndarray) -> float:
    atas = label[urutan][:K]
    return float((atas >= 2).sum()) / K


def _ndcg_at_k(label: np.ndarray, urutan: np.ndarray) -> float:
    def dcg(lbl: np.ndarray) -> float:
        lbl = lbl[:K]
        return float(sum((2**v - 1) / np.log2(i + 2) for i, v in enumerate(lbl)))

    ideal = dcg(np.sort(label)[::-1])
    return dcg(label[urutan]) / ideal if ideal > 0 else 0.0


def main() -> None:
    with Session(create_engine(get_settings().database_url)) as sesi:
        x, y, grup = _kumpulkan(sesi, date.today(), hanya_simulasi=True)
    batas = np.cumsum([0, *grup])
    idx = list(range(len(grup)))
    random.Random(3).shuffle(idx)  # noqa: S311
    lipatan = [idx[i::LIPATAN] for i in range(LIPATAN)]

    def kumpul(ids: list[int]) -> tuple[np.ndarray, np.ndarray, list[int]]:
        xs = np.vstack([x[batas[i] : batas[i + 1]] for i in ids])
        ys = np.concatenate([y[batas[i] : batas[i + 1]] for i in ids])
        return xs, ys, [grup[i] for i in ids]

    hasil = {"p5_dasar": [], "p5_lgbm": [], "ndcg5_dasar": [], "ndcg5_lgbm": []}
    for k_uji in range(LIPATAN):
        latih_idx = [i for j, f in enumerate(lipatan) if j != k_uji for i in f]
        xl, yl, gl = kumpul(latih_idx)
        model = latih(xl, yl, gl, "evaluasi")
        for i in lipatan[k_uji]:
            xi, yi = x[batas[i] : batas[i + 1]], y[batas[i] : batas[i + 1]]
            if (yi >= 2).sum() == 0:
                continue  # tanpa butir relevan, ukuran tidak bermakna
            dasar = np.arange(len(yi))  # urutan asli = kategori lalu skor gabungan
            skor = model.booster.predict(xi)
            lgbm = np.lexsort((-skor, xi[:, 2]))  # seperti produksi: urut ulang di dalam kategori
            hasil["p5_dasar"].append(_p_at_k(yi, dasar))
            hasil["p5_lgbm"].append(_p_at_k(yi, lgbm))
            hasil["ndcg5_dasar"].append(_ndcg_at_k(yi, dasar))
            hasil["ndcg5_lgbm"].append(_ndcg_at_k(yi, lgbm))
    ringkas = {
        "lipatan": LIPATAN,
        "pengguna_total": len(grup),
        "pengguna_uji_dipakai": len(hasil["p5_dasar"]),
        **{k: round(float(np.mean(v)), 3) if v else None for k, v in hasil.items()},
    }
    print(json.dumps(ringkas, indent=1))
    if len(sys.argv) > 1:
        with open(sys.argv[1], "w", encoding="utf-8") as f:
            json.dump(ringkas, f, indent=1)


if __name__ == "__main__":
    main()
