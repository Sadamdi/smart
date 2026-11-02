"""Pembatas percobaan login per kunci (email). Disimpan di memori proses (satu pekerja).

Kunci memakai email, bukan alamat IP: di belakang proxy (Vercel dan tunnel) semua permintaan
tampak berasal dari alamat yang sama.
"""

import time
from collections import defaultdict, deque

from app.core.errors import RateLimited


class PembatasPercobaan:
    def __init__(self, maks: int = 5, jendela_detik: int = 900) -> None:
        self.maks = maks
        self.jendela = jendela_detik
        self._gagal: dict[str, deque[float]] = defaultdict(deque)

    def _bersihkan(self, kunci: str, sekarang: float) -> deque[float]:
        antrean = self._gagal[kunci]
        while antrean and sekarang - antrean[0] > self.jendela:
            antrean.popleft()
        return antrean

    def periksa(self, kunci: str) -> None:
        if len(self._bersihkan(kunci, time.monotonic())) >= self.maks:
            raise RateLimited("Terlalu banyak percobaan masuk. Coba lagi beberapa menit lagi.")

    def catat_gagal(self, kunci: str) -> None:
        self._bersihkan(kunci, time.monotonic()).append(time.monotonic())

    def reset(self, kunci: str) -> None:
        self._gagal.pop(kunci, None)


pembatas_login = PembatasPercobaan()
