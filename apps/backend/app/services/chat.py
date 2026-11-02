"""Chatbot beasiswa. Jawaban hanya boleh bersumber dari data di basis data (profil dan beasiswa terbit)."""

import re
import uuid
from datetime import UTC, date, datetime, timedelta

from sqlalchemy import delete, func, or_, select
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.core.errors import RateLimited, ValidationFailed
from app.models import Beasiswa, Pengguna, Percakapan
from app.services import llm
from app.services import rekomendasi as layanan_rekomendasi

PESAN_MAKS = 2000
KONTEKS_MAKS = 5

SISTEM = (
    "Kamu asisten beasiswa SMART. Jawab dalam bahasa Indonesia yang ringkas dan sopan. "
    "Gunakan HANYA data pada bagian DATA di bawah. Jika data tidak memuat jawabannya, katakan datanya belum ada "
    "dan sarankan memeriksa tautan resmi beasiswa. Jangan pernah menyatakan pengguna pasti diterima atau ditolak, "
    "dan jangan menyebut persen peluang. Jangan mengarang tenggat, syarat, atau nominal."
)


def _kata_kunci(pesan: str) -> list[str]:
    return [k for k in re.findall(r"[a-zA-Z0-9]{4,}", pesan.lower())][:6]


def cari_beasiswa(sesi: Session, pesan: str, hari_ini: date) -> list[Beasiswa]:
    kunci = _kata_kunci(pesan)
    stmt = select(Beasiswa).where(Beasiswa.status == "terbit", Beasiswa.tenggat.is_not(None), Beasiswa.tenggat >= hari_ini)
    if kunci:
        stmt = stmt.where(or_(*[Beasiswa.nama.ilike(f"%{k}%") | Beasiswa.penyelenggara.ilike(f"%{k}%") for k in kunci]))
    return list(sesi.scalars(stmt.order_by(Beasiswa.tenggat).limit(KONTEKS_MAKS)))


def susun_data(sesi: Session, p: Pengguna, pesan: str, hari_ini: date) -> tuple[str, list[uuid.UUID]]:
    baris = [
        f"Profil: jenjang={p.jenjang}, semester={p.semester}, ipk={p.ipk}, program_studi={p.program_studi}, minat={p.minat}"
    ]
    rujukan: list[uuid.UUID] = []
    rekom = layanan_rekomendasi.daftar(sesi, p, hari_ini, None)[:KONTEKS_MAKS]
    for r, b in rekom:
        baris.append(
            f"Rekomendasi: {b.nama} oleh {b.penyelenggara}, kategori {r.kategori}, tenggat {b.tenggat}, "
            f"kekurangan {r.catatan_kekurangan or 'tidak ada'}"
        )
        rujukan.append(b.id)
    for b in cari_beasiswa(sesi, pesan, hari_ini):
        baris.append(
            f"Beasiswa: {b.nama} oleh {b.penyelenggara}, tenggat {b.tenggat}, manfaat {b.manfaat}, tautan {b.tautan_resmi}"
        )
        if b.id not in rujukan:
            rujukan.append(b.id)
    return "\n".join(baris), rujukan


def kirim(sesi: Session, p: Pengguna, pesan: str, settings: Settings, hari_ini: date) -> Percakapan:
    pesan = pesan.strip()
    if not pesan or len(pesan) > PESAN_MAKS:
        raise ValidationFailed(f"Pesan wajib diisi dan maksimal {PESAN_MAKS} karakter")
    awal = datetime.now(UTC).replace(hour=0, minute=0, second=0, microsecond=0)
    hari_ini_dipakai = sesi.scalar(
        select(func.count())
        .select_from(Percakapan)
        .where(
            Percakapan.pengguna_id == p.id,
            Percakapan.waktu >= awal,
            Percakapan.waktu < awal + timedelta(days=1),
        )
    )
    if (hari_ini_dipakai or 0) >= settings.ai_batas_harian:
        raise RateLimited("Batas pesan harian tercapai, coba lagi besok")
    data, rujukan = susun_data(sesi, p, pesan, hari_ini)
    jawaban = llm.tanya(settings, SISTEM, f"DATA:\n{data}\n\nPERTANYAAN:\n{pesan}")
    c = Percakapan(pengguna_id=p.id, pesan=pesan, jawaban=jawaban, rujukan_beasiswa_id=rujukan)
    sesi.add(c)
    sesi.flush()
    return c


def riwayat(sesi: Session, p: Pengguna, batas: int = 50) -> list[Percakapan]:
    baris = list(
        sesi.scalars(select(Percakapan).where(Percakapan.pengguna_id == p.id).order_by(Percakapan.waktu.desc()).limit(batas))
    )
    return list(reversed(baris))


def hapus_riwayat(sesi: Session, p: Pengguna) -> None:
    sesi.execute(delete(Percakapan).where(Percakapan.pengguna_id == p.id))
