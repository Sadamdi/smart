"""Ekstraktor tabel pada laman informasi beasiswa Kemahasiswaan UIN Malang (sumber pantau_otomatis).

Laman berupa satu halaman statis dengan tiga tabel; tabel pertama (timeline) memuat program beasiswa.
Tenggat tidak tersedia (kolom pelaksanaan berisi bulan bebas), sehingga hasilnya tidak pernah langsung terbit.
"""

import hashlib
import re
from dataclasses import dataclass, field

from bs4 import BeautifulSoup

URL_SUMBER = "https://kemahasiswaan.uin-malang.ac.id/informasi-beasiswa"
KOLOM_WAJIB = ("program beasiswa", "kriteria pelamar", "pelaksanaan")
_JENJANG = (
    ("D3", r"\bd-?3\b|diploma"),
    ("D4", r"\bd-?4\b"),
    ("S1", r"\bs-?1\b|sarjana(?! ?s2)|mahasiswa baru"),
    ("S2", r"\bs-?2\b|magister|pascasarjana"),
    ("S3", r"\bs-?3\b|doktor"),
)


@dataclass
class BarisBeasiswa:
    nama: str
    kriteria: str
    pelaksanaan: str
    tautan: str | None
    jenjang: list[str] = field(default_factory=list)


def _teks(sel) -> str:
    return re.sub(r"\s+", " ", sel.get_text(" ", strip=True).replace("\xa0", " ")).strip()


def _tautan_pertama(sel) -> str | None:
    a = sel.find("a", href=True)
    return a["href"].strip() if a else None


def tebak_jenjang(teks: str) -> list[str]:
    t = teks.lower()
    return [kode for kode, pola in _JENJANG if re.search(pola, t)]


def ekstrak(html: str) -> list[BarisBeasiswa]:
    """Mengambil baris dari tabel yang kepalanya memuat kolom wajib. Baris tanpa nama dilewati."""
    sup = BeautifulSoup(html, "lxml")
    for tabel in sup.find_all("table"):
        baris = tabel.find_all("tr")
        if not baris:
            continue
        kepala = [_teks(c).lower() for c in baris[0].find_all(["td", "th"])]
        if not all(any(k in h for h in kepala) for k in KOLOM_WAJIB):
            continue
        idx = {k: next(i for i, h in enumerate(kepala) if k in h) for k in KOLOM_WAJIB}
        tautan_idx = next((i for i, h in enumerate(kepala) if "informasi" in h), None)
        hasil = []
        for tr in baris[1:]:
            sel = tr.find_all(["td", "th"])
            if len(sel) < len(kepala):
                continue
            nama = _teks(sel[idx["program beasiswa"]])
            if not nama:
                continue
            kriteria = _teks(sel[idx["kriteria pelamar"]])
            hasil.append(
                BarisBeasiswa(
                    nama=nama,
                    kriteria=kriteria,
                    pelaksanaan=_teks(sel[idx["pelaksanaan"]]),
                    tautan=_tautan_pertama(sel[tautan_idx]) if tautan_idx is not None else None,
                    jenjang=tebak_jenjang(f"{nama} {kriteria}"),
                )
            )
        return hasil
    return []


def sidik(b: BarisBeasiswa) -> str:
    """Sidik isi untuk deduplikasi: nama dan kriteria yang dinormalkan."""
    dasar = re.sub(r"\W+", " ", f"{b.nama}|{b.kriteria}".lower()).strip()
    return hashlib.sha256(dasar.encode()).hexdigest()[:32]
