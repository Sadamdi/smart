import pytest

from smart_ml import skor_gabungan


def test_skor_gabungan_memakai_bobot_0_6_dan_0_4():
    assert skor_gabungan(1.0, 0.0) == pytest.approx(0.6)
    assert skor_gabungan(0.0, 1.0) == pytest.approx(0.4)
    assert skor_gabungan(0.5, 0.5) == pytest.approx(0.5)
