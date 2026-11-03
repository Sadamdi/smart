"""Lapisan ketiga: pemeringkatan belajar-mesin (LightGBM LambdaRank) dengan penjelasan SHAP.

Model hanya mengurutkan ulang beasiswa di dalam kategori kelayakan yang sama; kategori (memenuhi, hampir memenuhi, belum
memenuhi) tetap ditentukan aturan dan tidak pernah diubah model. Penjelasan memakai nilai SHAP bawaan LightGBM (TreeSHAP,
pred_contrib), sehingga tidak butuh pustaka tambahan. Bila berkas model tidak ada, sistem memakai skor gabungan 0,6 dan 0,4.

Model hanya sebaik data latihnya: lihat scripts/latih_peringkat.py (data interaksi nyata atau model demo sintetis yang
diberi label jelas pada versi_model).
"""

import json
from dataclasses import dataclass
from datetime import date
from pathlib import Path

import lightgbm as lgb
import numpy as np

from app.rekomendasi.kelayakan import BELUM, HAMPIR, MEMENUHI
from app.rekomendasi.mesin import URUTAN_KATEGORI, HasilRekomendasi

FITUR = [
    "skor_kelayakan",
    "skor_kemiripan",
    "kategori",
    "hari_ke_tenggat",
    "jumlah_alasan",
    "jumlah_kekurangan",
]
NAMA_FITUR = {
    "skor_kelayakan": "kelayakan terhadap syarat",
    "skor_kemiripan": "kemiripan minat dan program studi",
    "kategori": "kategori kelayakan",
    "hari_ke_tenggat": "jarak ke tenggat",
    "jumlah_alasan": "banyaknya syarat terpenuhi",
    "jumlah_kekurangan": "banyaknya kekurangan",
}
KODE_KATEGORI = {MEMENUHI: 0.0, HAMPIR: 1.0, BELUM: 2.0}
HARI_MAKS = 365.0


def fitur_dari(h: HasilRekomendasi, hari_ini: date) -> list[float]:
    hari = float((h.tenggat - hari_ini).days) if h.tenggat else HARI_MAKS
    return [
        h.skor_kelayakan,
        h.skor_kemiripan,
        KODE_KATEGORI[h.kategori],
        min(max(hari, 0.0), HARI_MAKS),
        float(len(h.alasan)),
        float(len(h.catatan_kekurangan)),
    ]


@dataclass
class ModelPeringkat:
    booster: lgb.Booster
    versi: str


def latih(x: np.ndarray, y: np.ndarray, grup: list[int], versi: str) -> ModelPeringkat:
    """Melatih LambdaRank. Label bertingkat: 0 diabaikan, 1 diklik, 2 disimpan, 3 rencana daftar."""
    set_latih = lgb.Dataset(x, label=y, group=grup, feature_name=FITUR)
    params = {
        "objective": "lambdarank",
        "metric": "ndcg",
        "learning_rate": 0.1,
        "num_leaves": 7,
        "min_data_in_leaf": 5,
        "verbosity": -1,
        "seed": 7,
    }
    return ModelPeringkat(lgb.train(params, set_latih, num_boost_round=60), versi)


def simpan(model: ModelPeringkat, lokasi: str) -> None:
    p = Path(lokasi)
    p.parent.mkdir(parents=True, exist_ok=True)
    model.booster.save_model(str(p))
    p.with_suffix(".json").write_text(json.dumps({"versi": model.versi, "fitur": FITUR}), encoding="utf-8")


def muat(lokasi: str) -> ModelPeringkat | None:
    p = Path(lokasi)
    if not p.is_file():
        return None
    meta = {}
    if p.with_suffix(".json").is_file():
        meta = json.loads(p.with_suffix(".json").read_text(encoding="utf-8"))
    if meta.get("fitur") not in (None, FITUR):
        return None  # fitur berubah sejak model dilatih: abaikan, pakai skor gabungan
    return ModelPeringkat(lgb.Booster(model_file=str(p)), meta.get("versi", "lgbm"))


def kontribusi_shap(model: ModelPeringkat, fitur: list[float]) -> dict[str, float]:
    """Nilai SHAP per fitur untuk satu beasiswa (positif menaikkan urutan)."""
    k = model.booster.predict(np.array([fitur]), pred_contrib=True)[0]
    return {nama: float(k[i]) for i, nama in enumerate(FITUR)}


def kalimat_penjelasan(kontribusi: dict[str, float], fitur: list[float]) -> str | None:
    """Menerjemahkan SHAP menjadi kalimat awam: faktor yang paling menaikkan urutan, bila berarti."""
    naik = sorted(((v, n) for n, v in kontribusi.items() if v > 0.05), reverse=True)[:2]
    if not naik:
        return None
    return "Urutan dipengaruhi oleh " + " dan ".join(NAMA_FITUR[n] for _, n in naik)


def urut_ulang(hasil: list[HasilRekomendasi], model: ModelPeringkat, hari_ini: date) -> list[HasilRekomendasi]:
    """Mengurutkan ulang di dalam tiap kategori berdasarkan skor model; menambahkan penjelasan SHAP ke alasan."""
    if not hasil:
        return hasil
    x = np.array([fitur_dari(h, hari_ini) for h in hasil])
    skor = model.booster.predict(x)
    pasangan = list(zip(hasil, skor, x.tolist(), strict=True))
    pasangan.sort(key=lambda p: (URUTAN_KATEGORI[p[0].kategori], -float(p[1])))
    keluar: list[HasilRekomendasi] = []
    for h, _, f in pasangan:
        kalimat = kalimat_penjelasan(kontribusi_shap(model, f), f)
        if kalimat and kalimat not in h.alasan:
            h.alasan = [*h.alasan, kalimat]
        keluar.append(h)
    return keluar


def precision_at_k(urutan_id: list[str], relevan: set[str], k: int = 5) -> float:
    """Precision@k terhadap gold set (daftar id beasiswa relevan hasil penilaian manusia)."""
    teratas = urutan_id[:k]
    if not teratas:
        return 0.0
    return sum(1 for i in teratas if i in relevan) / len(teratas)
