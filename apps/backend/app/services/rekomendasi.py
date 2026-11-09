"""Layanan rekomendasi: menyusun masukan dari basis data, memanggil mesin, menyimpan hasil per pengguna."""

import uuid
from collections import defaultdict
from datetime import date

from sqlalchemy import delete, insert, or_, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Beasiswa, DokumenPengguna, Pengguna, Persyaratan, Rekomendasi
from app.rekomendasi.embedding import PengemasHash, teks_profil
from app.rekomendasi.kelayakan import ProfilKelayakan
from app.rekomendasi.konfigurasi import VERSI_MODEL
from app.rekomendasi.mesin import HasilRekomendasi, MasukanBeasiswa, susun
from app.rekomendasi.peringkat import muat, urut_ulang


def lanjutan(p: Pengguna) -> dict:
    return p.profil_lanjutan or {}


def teks_tambahan(p: Pengguna) -> str:
    """Kata kunci dari profil lanjutan dan catatan untuk lapisan kemiripan."""
    pl = lanjutan(p)
    bagian: list[str] = [p.catatan_tambahan or "", pl.get("fakultas") or "", pl.get("jurusan_sekolah") or ""]
    for kunci in ("organisasi", "prestasi", "sertifikat", "pengalaman"):
        bagian += [str(x.get("nama", "")) for x in pl.get(kunci, []) if isinstance(x, dict)]
    bagian += [str(k) for k in pl.get("keahlian", [])]
    ts = pl.get("target_studi") or {}
    bagian += [str(b) for b in ts.get("bidang", [])] + [str(n) for n in ts.get("negara", [])]
    return " ".join(x for x in bagian if x).strip()


def profil_dari(sesi: Session, p: Pengguna) -> ProfilKelayakan:
    berkas: set[str] = set()
    for d in sesi.scalars(select(DokumenPengguna).where(DokumenPengguna.pengguna_id == p.id)):
        berkas.add(d.jenis)
        berkas.add(d.nama_berkas)
    return ProfilKelayakan(
        jenjang=p.jenjang,
        semester=p.semester,
        ipk=float(p.ipk) if p.ipk is not None else None,
        jenis_kampus=p.jenis_kampus,
        kota_domisili=p.kota_domisili,
        daerah_asal=[x for x in (lanjutan(p).get("kota_asal"), lanjutan(p).get("provinsi_asal")) if x],
        tanggal_lahir=p.tanggal_lahir,
        penghasilan_orang_tua=p.penghasilan_orang_tua,
        skor_bahasa=p.skor_bahasa,
        kewarganegaraan=p.kewarganegaraan,
        berkas_diunggah=berkas,
    )


def _masukan(sesi: Session, hari_ini: date) -> list[MasukanBeasiswa]:
    baris = list(
        sesi.scalars(
            select(Beasiswa).where(
                Beasiswa.status == "terbit", or_(Beasiswa.tenggat.is_(None), Beasiswa.tenggat >= hari_ini)
            )
        )
    )
    syarat: dict[uuid.UUID, list[tuple[str, dict | None]]] = defaultdict(list)
    ids = [b.id for b in baris]
    if ids:
        for s in sesi.scalars(select(Persyaratan).where(Persyaratan.beasiswa_id.in_(ids))):
            syarat[s.beasiswa_id].append((s.jenis, s.nilai_batas))
    return [MasukanBeasiswa(b.id, b.nama, b.penyelenggara, b.manfaat, b.tenggat, syarat.get(b.id, [])) for b in baris]


def hitung(sesi: Session, p: Pengguna, hari_ini: date) -> list[HasilRekomendasi]:
    hasil = susun(
        profil_dari(sesi, p),
        p.minat,
        p.program_studi,
        _masukan(sesi, hari_ini),
        hari_ini,
        kondisi_khusus=p.kondisi_khusus,
        catatan=teks_tambahan(p),
    )
    versi = VERSI_MODEL
    model = muat(get_settings().model_peringkat_path)
    if model is not None:
        hasil = urut_ulang(hasil, model, hari_ini)
        versi = f"{VERSI_MODEL}+{model.versi}"
    sesi.execute(delete(Rekomendasi).where(Rekomendasi.pengguna_id == p.id))
    if hasil:  # satu sisipan massal: sisipan per baris ke basis data jarak jauh membuat hitung ulang puluhan detik
        sesi.execute(
            insert(Rekomendasi),
            [
                {
                    "pengguna_id": p.id,
                    "beasiswa_id": h.beasiswa_id,
                    "skor": h.skor,
                    "skor_kelayakan": h.skor_kelayakan,
                    "skor_kemiripan": h.skor_kemiripan,
                    "kategori": h.kategori,
                    "alasan": h.alasan,
                    "catatan_kekurangan": h.catatan_kekurangan,
                    "versi_model": versi,
                }
                for h in hasil
            ],
        )
    p.vektor_profil = PengemasHash().kemas(
        teks_profil(p.minat, p.program_studi, p.jenjang, p.kondisi_khusus, teks_tambahan(p))
    )
    sesi.flush()
    return hasil


def daftar(
    sesi: Session, p: Pengguna, hari_ini: date, kategori: str | None, paksa: bool = False
) -> list[tuple[Rekomendasi, Beasiswa]]:
    ada = sesi.scalar(select(Rekomendasi.id).where(Rekomendasi.pengguna_id == p.id).limit(1))
    if paksa or ada is None:
        hitung(sesi, p, hari_ini)
    stmt = (
        select(Rekomendasi, Beasiswa)
        .join(Beasiswa, Beasiswa.id == Rekomendasi.beasiswa_id)
        .where(
            Rekomendasi.pengguna_id == p.id,
            Beasiswa.status == "terbit",
            or_(Beasiswa.tenggat.is_(None), Beasiswa.tenggat >= hari_ini),
        )
    )
    if kategori:
        stmt = stmt.where(Rekomendasi.kategori == kategori)
    urutan = {"memenuhi": 0, "hampir_memenuhi": 1, "belum_memenuhi": 2}
    baris = [(r, b) for r, b in sesi.execute(stmt).all()]
    baris.sort(key=lambda x: (urutan[x[0].kategori], -float(x[0].skor), x[1].tenggat or date.max))
    return baris


def ringkasan(sesi: Session, p: Pengguna, hari_ini: date) -> dict[str, int]:
    hasil = {"memenuhi": 0, "hampir_memenuhi": 0, "belum_memenuhi": 0}
    for r, _ in daftar(sesi, p, hari_ini, None):
        hasil[r.kategori] += 1
    return hasil
