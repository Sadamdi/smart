"""Layanan panel admin: antrean validasi, terbit atau tolak, input manual, sumber, laporan (FR-SM-05 sampai 07)."""

import uuid
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.errors import Conflict, NotFound, ValidationFailed
from app.models import Beasiswa, BerkasWajib, Pengguna, Persyaratan, Sumber

HARI_MINIMAL_TERBIT = 3
SUMBER_MANUAL_URL = "manual://smart"


def antrean(sesi: Session) -> list[tuple[Beasiswa, str]]:
    stmt = (
        select(Beasiswa, Sumber.nama)
        .join(Sumber, Sumber.id == Beasiswa.sumber_id)
        .where(Beasiswa.status == "menunggu_validasi")
        .order_by(Beasiswa.dibuat_pada.desc(), Beasiswa.id)
    )
    return [(b, nama) for b, nama in sesi.execute(stmt).all()]


def _ambil(sesi: Session, beasiswa_id: uuid.UUID) -> Beasiswa:
    b = sesi.get(Beasiswa, beasiswa_id)
    if b is None:
        raise NotFound("Beasiswa tidak ditemukan")
    return b


def detail(sesi: Session, beasiswa_id: uuid.UUID) -> tuple[Beasiswa, list[Persyaratan], list[BerkasWajib]]:
    b = _ambil(sesi, beasiswa_id)
    syarat = list(sesi.scalars(select(Persyaratan).where(Persyaratan.beasiswa_id == b.id)))
    berkas = list(sesi.scalars(select(BerkasWajib).where(BerkasWajib.beasiswa_id == b.id)))
    return b, syarat, berkas


def perbaiki(sesi: Session, beasiswa_id: uuid.UUID, data: dict, syarat: list[dict] | None, berkas: list[str] | None):
    b = _ambil(sesi, beasiswa_id)
    for kolom, nilai in data.items():
        setattr(b, kolom, nilai)
    if syarat is not None:
        for lama in sesi.scalars(select(Persyaratan).where(Persyaratan.beasiswa_id == b.id)):
            sesi.delete(lama)
        for s in syarat:
            sesi.add(
                Persyaratan(
                    beasiswa_id=b.id,
                    jenis=s["jenis"],
                    nilai_batas=s.get("nilai_batas"),
                    dapat_dikejar=s.get("dapat_dikejar", False),
                )
            )
    if berkas is not None:
        for lama in sesi.scalars(select(BerkasWajib).where(BerkasWajib.beasiswa_id == b.id)):
            sesi.delete(lama)
        for nama in berkas:
            sesi.add(BerkasWajib(beasiswa_id=b.id, nama_berkas=nama))
    b.tanggal_diperiksa = datetime.now(UTC)
    sesi.flush()
    return b


def periksa_boleh_terbit(b: Beasiswa, hari_ini: date) -> None:
    if not b.tautan_resmi or not b.tautan_resmi.startswith(("http://", "https://")):
        raise ValidationFailed("Tautan resmi wajib berupa alamat http atau https")
    if b.tenggat is not None and b.tenggat < hari_ini + timedelta(days=HARI_MINIMAL_TERBIT):
        raise ValidationFailed(f"Tenggat paling cepat {HARI_MINIMAL_TERBIT} hari dari hari ini")


def terbitkan(sesi: Session, beasiswa_id: uuid.UUID, hari_ini: date) -> Beasiswa:
    b = _ambil(sesi, beasiswa_id)
    if b.status == "terbit":
        raise Conflict("Beasiswa sudah terbit")
    periksa_boleh_terbit(b, hari_ini)
    b.status = "terbit"
    b.alasan_ditandai = None
    b.tanggal_diperiksa = datetime.now(UTC)
    sesi.flush()
    return b


def tolak(sesi: Session, beasiswa_id: uuid.UUID, alasan: str) -> Beasiswa:
    b = _ambil(sesi, beasiswa_id)
    b.status = "ditolak"
    b.alasan_ditandai = alasan
    sesi.flush()
    return b


def _sumber_manual(sesi: Session) -> Sumber:
    s = sesi.scalar(select(Sumber).where(Sumber.url == SUMBER_MANUAL_URL))
    if s is None:
        s = Sumber(nama="Input manual admin", url=SUMBER_MANUAL_URL, jenis="input_manual", aktif=True)
        sesi.add(s)
        sesi.flush()
    return s


def input_manual(sesi: Session, data: dict, syarat: list[dict], berkas: list[str]) -> Beasiswa:
    s = _sumber_manual(sesi)
    b = Beasiswa(sumber_id=s.id, status="menunggu_validasi", tanggal_diperiksa=datetime.now(UTC), **data)
    sesi.add(b)
    sesi.flush()
    for x in syarat:
        sesi.add(
            Persyaratan(
                beasiswa_id=b.id,
                jenis=x["jenis"],
                nilai_batas=x.get("nilai_batas"),
                dapat_dikejar=x.get("dapat_dikejar", False),
            )
        )
    for nama in berkas:
        sesi.add(BerkasWajib(beasiswa_id=b.id, nama_berkas=nama))
    sesi.flush()
    return b


def daftar_sumber(sesi: Session) -> list[Sumber]:
    return list(sesi.scalars(select(Sumber).order_by(Sumber.nama)))


def tambah_sumber(sesi: Session, data: dict) -> Sumber:
    if sesi.scalar(select(Sumber).where(Sumber.url == data["url"])):
        raise Conflict("Alamat sumber sudah terdaftar")
    s = Sumber(**data)
    sesi.add(s)
    sesi.flush()
    return s


def ubah_sumber(sesi: Session, sumber_id: uuid.UUID, data: dict) -> Sumber:
    s = sesi.get(Sumber, sumber_id)
    if s is None:
        raise NotFound("Sumber tidak ditemukan")
    for kolom, nilai in data.items():
        setattr(s, kolom, nilai)
    sesi.flush()
    return s


def laporan(sesi: Session) -> dict:
    per_status = dict(sesi.execute(select(Beasiswa.status, func.count()).group_by(Beasiswa.status)).all())
    per_sumber = dict(sesi.execute(select(Sumber.status_terakhir, func.count()).group_by(Sumber.status_terakhir)).all())
    pengguna = sesi.scalar(select(func.count()).select_from(Pengguna).where(Pengguna.peran == "mahasiswa")) or 0
    return {
        "beasiswa_per_status": {k: per_status.get(k, 0) for k in ("menunggu_validasi", "terbit", "kedaluwarsa", "ditolak")},
        "sumber_per_status": {k: per_sumber.get(k, 0) for k in ("berhasil", "gagal", "belum_pernah")},
        "jumlah_sumber": sum(per_sumber.values()),
        "jumlah_mahasiswa": pengguna,
        "divalidasi_ai": sesi.scalar(
            select(func.count()).select_from(Beasiswa).where(Beasiswa.divalidasi_ai_pada.is_not(None))
        )
        or 0,
    }
