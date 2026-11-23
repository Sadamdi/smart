"""Pembersihan otomatis berkas dan memori yang tidak terpakai, per pengguna.

Aturan (sengaja konservatif; data milik pengguna tidak dibuang diam-diam):

Dokumen
- Hanya dokumen berasal 'chat' (lampiran percakapan) yang boleh dihapus otomatis. Dokumen 'profil' (CV, transkrip,
  sertifikat dari halaman Dokumen) tidak pernah dihapus otomatis karena memberi isi profil dan Memori.
- Lampiran chat yang tidak dipakai lagi [HARI_LAMPIRAN] hari dihapus. Terakhir dipakai = saat dilampirkan ke pertanyaan;
  bila belum pernah, tanggal unggah.
- Bila ruang terpakai melewati [AMBANG_PENUH] (atau saat unggahan terhalang penuh, atau tombol bersihkan ditekan),
  lampiran chat yang berumur lebih dari [HARI_LAMPIRAN_PENUH] hari ikut dihapus, yang paling lama tak dipakai lebih dulu,
  sampai ruang turun di bawah [TARGET_PENUH].

Memori
- Butir yang ditulis sendiri pengguna dan butir otomatis yang aktif tidak pernah dihapus otomatis: yang aktif masuk
  konteks tiap pertanyaan dan dipakai rekomendasi.
- Butir otomatis yang dinonaktifkan dan tidak dipakai [HARI_MEMORI_NONAKTIF] hari dihapus.
- Butir otomatis melebihi [BATAS_OTOMATIS] dihapus mulai dari yang paling lama tak dipakai.
"""

from datetime import UTC, datetime, timedelta
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.models import DokumenPengguna, MemoriPengguna, Pengguna
from app.services import dokumen as layanan_dokumen

HARI_LAMPIRAN = 30
HARI_LAMPIRAN_PENUH = 7
AMBANG_PENUH = 0.8
TARGET_PENUH = 0.7
HARI_MEMORI_NONAKTIF = 30
BATAS_OTOMATIS = 200


def _ukuran(d: DokumenPengguna) -> int:
    if d.lokasi_penyimpanan and Path(d.lokasi_penyimpanan).exists():
        return Path(d.lokasi_penyimpanan).stat().st_size
    return 0


def _terakhir(d: DokumenPengguna) -> datetime:
    return d.terakhir_dipakai or d.tanggal_unggah


def _hapus(sesi: Session, d: DokumenPengguna) -> None:
    if d.lokasi_penyimpanan:
        Path(d.lokasi_penyimpanan).unlink(missing_ok=True)
        Path(d.lokasi_penyimpanan + layanan_dokumen.SUFIKS_TEKS).unlink(missing_ok=True)
    sesi.delete(d)


def ringkasan_penyimpanan(sesi: Session, settings: Settings, p: Pengguna) -> dict:
    semua = list(sesi.scalars(select(DokumenPengguna).where(DokumenPengguna.pengguna_id == p.id)))
    terpakai = sum(_ukuran(d) for d in semua)
    maks = settings.upload_total_maks_byte
    return {
        "terpakai_byte": terpakai,
        "maks_byte": maks,
        "persen": min(100, round(terpakai * 100 / maks)) if maks else 0,
        "dokumen_profil": sum(1 for d in semua if d.asal == "profil"),
        "dokumen_chat": sum(1 for d in semua if d.asal == "chat"),
    }


def bersihkan_dokumen(
    sesi: Session, settings: Settings, p: Pengguna, sekarang: datetime | None = None, paksa_penuh: bool = False
) -> int:
    """Menghapus lampiran chat yang tak terpakai. Mengembalikan jumlah dokumen yang dihapus."""
    sekarang = sekarang or datetime.now(UTC)
    semua = list(sesi.scalars(select(DokumenPengguna).where(DokumenPengguna.pengguna_id == p.id)))
    chat = [d for d in semua if d.asal == "chat"]
    dihapus = 0
    sisa = []
    for d in chat:
        if sekarang - _terakhir(d) > timedelta(days=HARI_LAMPIRAN):
            _hapus(sesi, d)
            dihapus += 1
        else:
            sisa.append(d)
    maks = settings.upload_total_maks_byte
    terpakai = sum(_ukuran(d) for d in semua if d not in chat) + sum(_ukuran(d) for d in sisa)
    if maks and (paksa_penuh or terpakai > maks * AMBANG_PENUH):
        for d in sorted(sisa, key=_terakhir):
            if terpakai <= maks * TARGET_PENUH:
                break
            if sekarang - _terakhir(d) > timedelta(days=HARI_LAMPIRAN_PENUH):
                terpakai -= _ukuran(d)
                _hapus(sesi, d)
                dihapus += 1
    if dihapus:
        sesi.flush()
    return dihapus


def bersihkan_memori(sesi: Session, p: Pengguna, sekarang: datetime | None = None) -> int:
    """Menghapus butir memori otomatis yang tak terpakai (lihat aturan di atas)."""
    sekarang = sekarang or datetime.now(UTC)
    semua = list(sesi.scalars(select(MemoriPengguna).where(MemoriPengguna.pengguna_id == p.id)))
    otomatis = [m for m in semua if m.sumber not in (None, "manual")]

    def terakhir(m: MemoriPengguna) -> datetime:
        return m.terakhir_dipakai or m.dibuat_pada

    hapus = [m for m in otomatis if not m.aktif and sekarang - terakhir(m) > timedelta(days=HARI_MEMORI_NONAKTIF)]
    sisa = [m for m in otomatis if m not in hapus]
    if len(sisa) > BATAS_OTOMATIS:
        hapus += sorted(sisa, key=terakhir)[: len(sisa) - BATAS_OTOMATIS]
    for m in hapus:
        sesi.delete(m)
    if hapus:
        sesi.flush()
    return len(hapus)


def bersihkan_pengguna(
    sesi: Session, settings: Settings, p: Pengguna, sekarang: datetime | None = None, paksa_penuh: bool = False
) -> dict:
    return {
        "dokumen_dihapus": bersihkan_dokumen(sesi, settings, p, sekarang, paksa_penuh),
        "memori_dihapus": bersihkan_memori(sesi, p, sekarang),
    }
