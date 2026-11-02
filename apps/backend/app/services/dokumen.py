"""Dokumen pengguna: simpan berkas, ekstrak teks, baca isi (aturan dahulu, AI bila tersedia), koreksi (FR-SM-05, 06)."""

import io
import re
import uuid
import zipfile
from pathlib import Path

from pypdf import PdfReader
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.errors import NotFound, ValidationFailed
from app.models import DokumenPengguna, Pengguna

TIPE_DIIZINKAN = {".pdf", ".docx", ".txt", ".png", ".jpg", ".jpeg"}
TEKS_MAKS = 20000


def ekstrak_teks(nama: str, isi: bytes) -> str:
    ext = Path(nama).suffix.lower()
    try:
        if ext == ".pdf":
            return "\n".join((h.extract_text() or "") for h in PdfReader(io.BytesIO(isi)).pages)[:TEKS_MAKS]
        if ext == ".docx":
            with zipfile.ZipFile(io.BytesIO(isi)) as z:
                xml = z.read("word/document.xml").decode("utf8", "ignore")
            return re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", xml)).strip()[:TEKS_MAKS]
        if ext == ".txt":
            return isi.decode("utf8", "ignore")[:TEKS_MAKS]
    except Exception as exc:  # berkas rusak: biarkan pengguna mengisi manual
        raise ValueError("berkas tidak dapat dibaca") from exc
    return ""


def baca_dengan_aturan(teks: str) -> dict:
    """Pembacaan cadangan tanpa AI: hanya mengambil nilai yang tertulis jelas."""
    hasil: dict = {}
    ipk = re.search(r"(?:IPK|GPA)\D{0,12}([0-4][.,]\d{1,2})", teks, re.IGNORECASE)
    if ipk:
        hasil["ipk"] = float(ipk.group(1).replace(",", "."))
    bahasa: dict[str, float] = {}
    for nama, pola in (("toefl", r"TOEFL\D{0,15}(\d{3})"), ("ielts", r"IELTS\D{0,15}(\d(?:[.,]\d)?)")):
        m = re.search(pola, teks, re.IGNORECASE)
        if m:
            bahasa[nama] = float(m.group(1).replace(",", "."))
    if bahasa:
        hasil["skor_bahasa"] = bahasa
    sem = re.search(r"semester\D{0,5}(\d{1,2})", teks, re.IGNORECASE)
    if sem and 1 <= int(sem.group(1)) <= 14:
        hasil["semester"] = int(sem.group(1))
    organisasi = [
        m.strip()[:120]
        for m in re.findall(r"((?:BEM|HMJ|UKM|Himpunan|Organisasi|Ketua|Wakil Ketua|Sekretaris)[^\n.;]{3,100})", teks)
    ]
    if organisasi:
        hasil["pengalaman_organisasi"] = organisasi[:8]
    return hasil


def simpan(sesi: Session, p: Pengguna, jenis: str, nama: str, isi: bytes, settings: Settings) -> DokumenPengguna:
    ext = Path(nama).suffix.lower()
    if ext not in TIPE_DIIZINKAN:
        raise ValidationFailed("Tipe berkas harus PDF, DOCX, TXT, PNG, atau JPG")
    if len(isi) > settings.upload_maks_byte:
        raise ValidationFailed("Ukuran berkas maksimal 5 MB")
    if not isi:
        raise ValidationFailed("Berkas kosong")
    folder = Path(settings.upload_dir) / str(p.id)
    folder.mkdir(parents=True, exist_ok=True)
    lokasi = folder / f"{uuid.uuid4().hex}{ext}"
    lokasi.write_bytes(isi)
    d = DokumenPengguna(pengguna_id=p.id, jenis=jenis, nama_berkas=Path(nama).name[:200], lokasi_penyimpanan=str(lokasi))
    try:
        teks = ekstrak_teks(nama, isi)
        if teks.strip():
            d.hasil_baca = baca_dengan_aturan(teks) | {"ringkasan_teks": teks[:600]}
            d.status_baca = "selesai"
        else:
            d.status_baca = "gagal"
    except ValueError:
        d.status_baca = "gagal"
    sesi.add(d)
    sesi.flush()
    return d


def daftar(sesi: Session, p: Pengguna) -> list[DokumenPengguna]:
    return list(
        sesi.scalars(
            select(DokumenPengguna)
            .where(DokumenPengguna.pengguna_id == p.id)
            .order_by(DokumenPengguna.tanggal_unggah.desc())
        )
    )


def ambil(sesi: Session, p: Pengguna, dokumen_id: uuid.UUID) -> DokumenPengguna:
    d = sesi.scalar(select(DokumenPengguna).where(DokumenPengguna.id == dokumen_id, DokumenPengguna.pengguna_id == p.id))
    if d is None:
        raise NotFound("Dokumen tidak ditemukan")
    return d


def koreksi(sesi: Session, p: Pengguna, dokumen_id: uuid.UUID, hasil: dict) -> DokumenPengguna:
    d = ambil(sesi, p, dokumen_id)
    d.hasil_baca = hasil
    d.status_baca = "selesai"
    sesi.flush()
    return d


def terapkan_ke_profil(sesi: Session, p: Pengguna, hasil: dict) -> list[str]:
    """Mengisi kolom profil yang masih kosong dari hasil baca; tidak menimpa data yang sudah diisi pengguna."""
    terisi: list[str] = []
    if p.ipk is None and isinstance(hasil.get("ipk"), int | float) and 0 <= hasil["ipk"] <= 4:
        p.ipk = hasil["ipk"]
        terisi.append("ipk")
    if p.semester is None and isinstance(hasil.get("semester"), int) and 1 <= hasil["semester"] <= 14:
        p.semester = hasil["semester"]
        terisi.append("semester")
    if not p.skor_bahasa and isinstance(hasil.get("skor_bahasa"), dict):
        p.skor_bahasa = hasil["skor_bahasa"]
        terisi.append("skor_bahasa")
    sesi.flush()
    return terisi


def hapus(sesi: Session, p: Pengguna, dokumen_id: uuid.UUID) -> None:
    d = ambil(sesi, p, dokumen_id)
    Path(d.lokasi_penyimpanan).unlink(missing_ok=True)
    sesi.delete(d)
    sesi.flush()
