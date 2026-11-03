"""Uji pemeringkat LightGBM: kategori tidak berubah, ada penjelasan SHAP, model hilang berarti jatuh ke skor gabungan."""

import uuid
from datetime import date, timedelta

import numpy as np

from app.rekomendasi.kelayakan import HAMPIR, MEMENUHI
from app.rekomendasi.mesin import HasilRekomendasi
from app.rekomendasi.peringkat import (
    FITUR,
    fitur_dari,
    kontribusi_shap,
    latih,
    muat,
    precision_at_k,
    simpan,
    urut_ulang,
)

HARI = date(2026, 11, 4)


def _h(kategori, kel, mirip, hari=30):
    return HasilRekomendasi(
        uuid.uuid4(), kategori, kel * 0.6 + mirip * 0.4, kel, mirip, ["alasan"], [], HARI + timedelta(days=hari)
    )


def _model():
    rnd = np.random.default_rng(1)
    x = rnd.random((200, len(FITUR)))
    y = (x[:, 1] * 3).astype(int)  # model belajar bahwa kemiripan tinggi lebih relevan
    return latih(x, y, [10] * 20, "uji")


def test_urut_ulang_tidak_melintasi_kategori_dan_menambah_penjelasan(tmp_path):
    model = _model()
    daftar = [_h(HAMPIR, 0.5, 0.9), _h(MEMENUHI, 0.9, 0.1), _h(MEMENUHI, 0.8, 0.9), _h(HAMPIR, 0.6, 0.1)]
    hasil = urut_ulang(daftar, model, HARI)
    assert [h.kategori for h in hasil] == [MEMENUHI, MEMENUHI, HAMPIR, HAMPIR]
    assert hasil[0].skor_kemiripan == 0.9  # di dalam kategori, kemiripan tinggi naik
    assert any(a.startswith("Urutan dipengaruhi oleh") for a in hasil[0].alasan)


def test_shap_menjumlah_ke_prediksi():
    model = _model()
    f = fitur_dari(_h(MEMENUHI, 0.7, 0.8), HARI)
    k = model.booster.predict(np.array([f]), pred_contrib=True)[0]
    assert abs(sum(k) - model.booster.predict(np.array([f]))[0]) < 1e-6  # sifat SHAP: kontribusi + bias = prediksi
    assert set(kontribusi_shap(model, f)) == set(FITUR)


def test_simpan_muat_dan_model_hilang(tmp_path):
    lokasi = str(tmp_path / "m" / "peringkat.lgb")
    assert muat(lokasi) is None
    simpan(_model(), lokasi)
    m = muat(lokasi)
    assert m is not None and m.versi == "uji"


def test_precision_at_5():
    urutan = ["a", "b", "c", "d", "e", "f"]
    assert precision_at_k(urutan, {"a", "c", "z"}, 5) == 0.4
    assert precision_at_k([], {"a"}) == 0.0
