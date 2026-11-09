"""Interaksi, beasiswa tersimpan, checklist berkas, kalender, tugas pribadi, dan notifikasi tenggat (FR-SM-08 sampai 11)."""

import uuid
from datetime import date, timedelta

from sqlalchemy import delete, select, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.orm import Session

from app.core.errors import NotFound, ValidationFailed
from app.models import (
    Beasiswa,
    BerkasWajib,
    ChecklistPengguna,
    Interaksi,
    Notifikasi,
    Pengguna,
    TugasPribadi,
)
from app.repositories.beasiswa import _terlihat, _urut_tenggat

JENDELA_PENGINGAT_HARI = 7


def _beasiswa_terlihat(sesi: Session, beasiswa_id: uuid.UUID, hari_ini: date) -> Beasiswa:
    b = sesi.scalar(select(Beasiswa).where(Beasiswa.id == beasiswa_id, *_terlihat(hari_ini)))
    if b is None:
        raise NotFound("Beasiswa tidak ditemukan")
    return b


def catat_interaksi(
    sesi: Session, p: Pengguna, beasiswa_id: uuid.UUID, aksi: str, status_rencana: str | None, hari_ini: date
) -> Interaksi:
    _beasiswa_terlihat(sesi, beasiswa_id, hari_ini)
    if aksi == "rencana_daftar" and status_rencana is None:
        raise ValidationFailed("status_rencana wajib untuk aksi rencana_daftar")
    if aksi == "simpan":
        ada = sesi.scalar(
            select(Interaksi).where(
                Interaksi.pengguna_id == p.id,
                Interaksi.beasiswa_id == beasiswa_id,
                Interaksi.aksi == "simpan",
            )
        )
        if ada:
            return ada
    i = Interaksi(pengguna_id=p.id, beasiswa_id=beasiswa_id, aksi=aksi, status_rencana=status_rencana)
    sesi.add(i)
    sesi.flush()
    return i


def batal_simpan(sesi: Session, p: Pengguna, beasiswa_id: uuid.UUID) -> None:
    sesi.execute(
        delete(Interaksi).where(
            Interaksi.pengguna_id == p.id, Interaksi.beasiswa_id == beasiswa_id, Interaksi.aksi == "simpan"
        )
    )


def tersimpan(sesi: Session, p: Pengguna, hari_ini: date) -> list[tuple[Beasiswa, str | None]]:
    stmt = (
        select(Beasiswa)
        .join(Interaksi, Interaksi.beasiswa_id == Beasiswa.id)
        .where(
            Interaksi.pengguna_id == p.id,
            Interaksi.aksi == "simpan",
            *_terlihat(hari_ini),
        )
        .order_by(_urut_tenggat(), Beasiswa.id)
    )
    beasiswa = list(sesi.scalars(stmt))
    rencana: dict[uuid.UUID, str | None] = {}
    for i in sesi.scalars(
        select(Interaksi).where(Interaksi.pengguna_id == p.id, Interaksi.aksi == "rencana_daftar").order_by(Interaksi.waktu)
    ):
        rencana[i.beasiswa_id] = i.status_rencana
    return [(b, rencana.get(b.id)) for b in beasiswa]


def checklist(sesi: Session, p: Pengguna, hari_ini: date) -> list[tuple[Beasiswa, list[tuple[BerkasWajib, bool]]]]:
    hasil = []
    for b, _ in tersimpan(sesi, p, hari_ini):
        berkas = list(
            sesi.scalars(select(BerkasWajib).where(BerkasWajib.beasiswa_id == b.id).order_by(BerkasWajib.nama_berkas))
        )
        selesai = {
            c.berkas_wajib_id
            for c in sesi.scalars(
                select(ChecklistPengguna).where(ChecklistPengguna.pengguna_id == p.id, ChecklistPengguna.selesai.is_(True))
            )
        }
        hasil.append((b, [(x, x.id in selesai) for x in berkas]))
    return hasil


def centang(sesi: Session, p: Pengguna, berkas_id: uuid.UUID, selesai: bool, hari_ini: date) -> bool:
    ada = sesi.scalar(
        select(BerkasWajib.id)
        .join(Interaksi, Interaksi.beasiswa_id == BerkasWajib.beasiswa_id)
        .where(BerkasWajib.id == berkas_id, Interaksi.pengguna_id == p.id, Interaksi.aksi == "simpan")
    )
    if ada is None:
        raise NotFound("Berkas tidak ditemukan pada beasiswa tersimpan")
    sesi.execute(
        pg_insert(ChecklistPengguna)
        .values(pengguna_id=p.id, berkas_wajib_id=berkas_id, selesai=selesai)
        .on_conflict_do_update(constraint="uq_checklist_pengguna_pengguna_berkas", set_={"selesai": selesai})
    )
    return selesai


def kalender(sesi: Session, p: Pengguna, dari: date, sampai: date, hari_ini: date) -> list[dict]:
    if sampai < dari:
        raise ValidationFailed("sampai tidak boleh sebelum dari")
    if (sampai - dari).days > 366:
        raise ValidationFailed("rentang maksimal satu tahun")
    acara: list[dict] = []
    for b, _ in tersimpan(sesi, p, hari_ini):
        if b.tenggat is not None and dari <= b.tenggat <= sampai:
            acara.append({"jenis": "tenggat", "tanggal": b.tenggat, "judul": b.nama, "ref_id": b.id, "selesai": False})
    for t in sesi.scalars(
        select(TugasPribadi).where(TugasPribadi.pengguna_id == p.id, TugasPribadi.tanggal.between(dari, sampai))
    ):
        acara.append({"jenis": "tugas", "tanggal": t.tanggal, "judul": t.judul, "ref_id": t.id, "selesai": t.selesai})
    acara.sort(key=lambda a: (a["tanggal"], a["jenis"]))
    return acara


def tambah_tugas(sesi: Session, p: Pengguna, judul: str, tanggal: date) -> TugasPribadi:
    t = TugasPribadi(pengguna_id=p.id, judul=judul, tanggal=tanggal)
    sesi.add(t)
    sesi.flush()
    return t


def _tugas(sesi: Session, p: Pengguna, tugas_id: uuid.UUID) -> TugasPribadi:
    t = sesi.scalar(select(TugasPribadi).where(TugasPribadi.id == tugas_id, TugasPribadi.pengguna_id == p.id))
    if t is None:
        raise NotFound("Tugas tidak ditemukan")
    return t


def ubah_tugas(sesi: Session, p: Pengguna, tugas_id: uuid.UUID, data: dict) -> TugasPribadi:
    t = _tugas(sesi, p, tugas_id)
    for k, v in data.items():
        setattr(t, k, v)
    sesi.flush()
    return t


def hapus_tugas(sesi: Session, p: Pengguna, tugas_id: uuid.UUID) -> None:
    sesi.delete(_tugas(sesi, p, tugas_id))
    sesi.flush()


def buat_pengingat(sesi: Session, p: Pengguna, hari_ini: date) -> int:
    """Satu pengingat per beasiswa tersimpan yang tenggatnya dalam jendela; unik per tanggal acuan sehingga tidak ganda."""
    batas = hari_ini + timedelta(days=JENDELA_PENGINGAT_HARI)
    baru = 0
    for b, _ in tersimpan(sesi, p, hari_ini):
        if b.tenggat is not None and b.tenggat <= batas:
            hasil = sesi.execute(
                pg_insert(Notifikasi)
                .values(pengguna_id=p.id, beasiswa_id=b.id, jenis="tenggat", kanal="push", tanggal_acuan=b.tenggat)
                .on_conflict_do_nothing(constraint="uq_notifikasi_pengingat")
            )
            baru += hasil.rowcount or 0
    return baru


def daftar_notifikasi(sesi: Session, p: Pengguna, hari_ini: date) -> list[tuple[Notifikasi, Beasiswa]]:
    buat_pengingat(sesi, p, hari_ini)
    stmt = (
        select(Notifikasi, Beasiswa)
        .join(Beasiswa, Beasiswa.id == Notifikasi.beasiswa_id)
        .where(Notifikasi.pengguna_id == p.id, Notifikasi.kanal == "push")
        .order_by(Notifikasi.tanggal_acuan, Notifikasi.id)
    )
    return [(n, b) for n, b in sesi.execute(stmt).all()]


def tandai_dibaca(sesi: Session, p: Pengguna, notifikasi_id: uuid.UUID) -> None:
    hasil = sesi.execute(
        update(Notifikasi).where(Notifikasi.id == notifikasi_id, Notifikasi.pengguna_id == p.id).values(dibaca=True)
    )
    if not hasil.rowcount:
        raise NotFound("Notifikasi tidak ditemukan")


def tandai_semua_dibaca(sesi: Session, p: Pengguna) -> None:
    sesi.execute(update(Notifikasi).where(Notifikasi.pengguna_id == p.id).values(dibaca=True))
