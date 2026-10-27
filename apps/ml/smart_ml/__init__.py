"""Mesin rekomendasi SMART. Aturan dan rumus: Dokument/01-Arsitektur/03-ATURAN-KELAYAKAN-DAN-MODEL.md."""

BOBOT_KELAYAKAN = 0.6
BOBOT_KEMIRIPAN = 0.4


def skor_gabungan(skor_kelayakan: float, skor_kemiripan: float) -> float:
    """Skor = 0,6 x kelayakan + 0,4 x kemiripan. Hanya untuk mengurutkan, bukan peluang diterima."""
    return BOBOT_KELAYAKAN * skor_kelayakan + BOBOT_KEMIRIPAN * skor_kemiripan
