"""Merapikan beasiswa terbit hasil validasi AI dengan aturan yang dapat diulang (tanpa memanggil AI).

Aturan:
1. Duplikat (nama sangat mirip atau yang satu awalan yang lain): disisakan satu (yang bertenggat atau tertua), sisanya ditolak.
2. Program tahun lampau tanpa tenggat (tahun terbesar pada nama kurang dari tahun ini) menjadi kedaluwarsa.
3. Bukan beasiswa (pelatihan, sertifikasi, sesi informasi) ditolak.
4. Nama terlalu pendek (satu atau dua kata) diberi awalan penyelenggara supaya jelas.
5. Penyelenggara yang diwarisi dari laman sumber UIN Malang pada tautan luar dikosongkan (tidak diketahui).

Pemakaian (dari apps/backend): uv run python -m scripts.rapikan_terbit [--terapkan]
Tanpa --terapkan hanya menampilkan rencana.
"""

import re
import sys
from datetime import date
from difflib import SequenceMatcher
from urllib.parse import urlparse

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Beasiswa

BUKAN_BEASISWA = ("certification", "sertifikasi", "information session", "sesi informasi")
PEMBEDA = {
    "graduate",
    "under",
    "undergraduate",
    "research",
    "garuda",
    "doctoral",
    "master",
    "masters",
    "short",
    "courses",
    "doktor",
    "magister",
    "sarjana",
}
NAMA_UMUM = {"graduate", "under graduate", "undergraduate", "research", "grants", "beasiswa"}


def _kunci(nama: str) -> str:
    return re.sub(r"[^a-z0-9 ]", "", nama.lower()).strip()


def _mirip(a: str, b: str) -> bool:
    if (set(a.split()) ^ set(b.split())) & PEMBEDA:
        return False  # jalur atau jenjang berbeda adalah program yang berbeda
    if min(len(a), len(b)) >= 18 and (a.startswith(b) or b.startswith(a)):
        return True
    return SequenceMatcher(None, a, b).ratio() >= 0.93


def main() -> None:
    terapkan = "--terapkan" in sys.argv
    hari = date.today()
    with Session(create_engine(get_settings().database_url)) as sesi:
        baris = list(sesi.scalars(select(Beasiswa).where(Beasiswa.status == "terbit").order_by(Beasiswa.dibuat_pada)))
        rencana: list[tuple[str, Beasiswa, str]] = []
        sudah: set = set()
        # 3 dan 2 lebih dulu supaya tidak ikut dihitung sebagai duplikat
        for b in baris:
            k = _kunci(b.nama)
            pelatihan_saja = "pelatihan" in k and "beasiswa" not in k and "scholarship" not in k and "full" not in k
            if pelatihan_saja or any(x in k for x in BUKAN_BEASISWA):
                rencana.append(("tolak", b, "Bukan beasiswa (pelatihan, sertifikasi, atau sesi informasi)"))
                sudah.add(b.id)
                continue
            tahun = [int(t) for t in re.findall(r"\b(20\d\d)\b", b.nama)]
            if b.tenggat is None and tahun and max(tahun) < hari.year:
                rencana.append(("kedaluwarsa", b, f"Program tahun {max(tahun)} sudah lampau"))
                sudah.add(b.id)
        sisa = [b for b in baris if b.id not in sudah]
        sisa.sort(key=lambda b: (b.tenggat is None, b.dibuat_pada))  # yang bertenggat didahulukan
        simpan: list[Beasiswa] = []
        for b in sisa:
            kb = _kunci(b.nama)
            pasangan = next((s for s in simpan if _mirip(kb, _kunci(s.nama))), None)
            if pasangan is not None:
                rencana.append(("tolak", b, f"Duplikat dari: {pasangan.nama[:60]}"))
            else:
                simpan.append(b)
        for b in simpan:
            pny = b.penyelenggara or ""
            umum = len(b.nama.split()) <= 1 or _kunci(b.nama) in NAMA_UMUM
            if umum and pny and len(pny) <= 40 and _kunci(pny) not in _kunci(b.nama) and _kunci(b.nama) not in _kunci(pny):
                rencana.append(("nama", b, f"{b.penyelenggara}: {b.nama}"))
            host = urlparse(b.tautan_resmi).netloc
            if b.penyelenggara == "Kemahasiswaan UIN Malang" and "uin-malang" not in host:
                rencana.append(("penyelenggara", b, ""))
        for aksi, b, ket in rencana:
            print(f"{aksi:13} {b.nama[:60]!r:64} {ket[:70]}".encode("ascii", "replace").decode())
        print(f"{len(rencana)} perubahan direncanakan dari {len(baris)} beasiswa terbit.")
        if not terapkan:
            return
        for aksi, b, ket in rencana:
            if aksi == "tolak":
                b.status, b.alasan_ditandai = "ditolak", ket
            elif aksi == "kedaluwarsa":
                b.status, b.alasan_ditandai = "kedaluwarsa", None
            elif aksi == "nama":
                b.nama = ket[:300]
            elif aksi == "penyelenggara":
                b.penyelenggara = None
        sesi.commit()
        print("diterapkan.")


if __name__ == "__main__":
    main()
