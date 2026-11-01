"""Repositori palsu di memori untuk menguji layanan dan rute tanpa basis data."""

import uuid
from datetime import date

from app.core.errors import Conflict
from app.models import Beasiswa, BerkasWajib, Pengguna, Persyaratan
from app.repositories.beasiswa import (
    DetailBeasiswa,
    FilterBeasiswa,
    HalamanBeasiswa,
    baca_kursor,
    kodekan_kursor,
)


class PenggunaRepoPalsu:
    def __init__(self) -> None:
        self.data: dict[uuid.UUID, Pengguna] = {}

    def by_email(self, email: str):
        return next((p for p in self.data.values() if p.email.lower() == email.lower()), None)

    def by_id(self, pengguna_id: uuid.UUID):
        return self.data.get(pengguna_id)

    def tambah(self, pengguna: Pengguna):
        if self.by_email(pengguna.email):
            raise Conflict("Email sudah terdaftar")
        self.data[pengguna.id] = pengguna
        return pengguna

    def simpan(self, pengguna: Pengguna):
        self.data[pengguna.id] = pengguna
        return pengguna

    def naikkan_versi(self, pengguna: Pengguna):
        pengguna.versi_token = (pengguna.versi_token or 0) + 1
        return self.simpan(pengguna)

    def hapus(self, pengguna: Pengguna) -> None:
        self.data.pop(pengguna.id, None)


def buat_beasiswa(
    nama: str,
    tenggat: date | None,
    status: str = "terbit",
    jenjang=None,
    negara="Indonesia",
    penyelenggara="Penyelenggara",
) -> Beasiswa:
    return Beasiswa(
        id=uuid.uuid4(),
        sumber_id=uuid.uuid4(),
        nama=nama,
        penyelenggara=penyelenggara,
        negara=negara,
        jenjang=jenjang or ["S1"],
        tenggat=tenggat,
        tautan_resmi="https://contoh.example/" + nama.replace(" ", "-"),
        status=status,
    )


class BeasiswaRepoPalsu:
    def __init__(self, daftar: list[Beasiswa]) -> None:
        self.semua = daftar
        self.syarat: dict[uuid.UUID, list[Persyaratan]] = {}
        self.berkas: dict[uuid.UUID, list[BerkasWajib]] = {}

    def _terlihat(self, hari_ini: date):
        return sorted(
            (b for b in self.semua if b.status == "terbit" and b.tenggat and b.tenggat >= hari_ini),
            key=lambda b: (b.tenggat, str(b.id)),
        )

    def daftar(self, filter_: FilterBeasiswa, kursor, batas: int, hari_ini: date) -> HalamanBeasiswa:
        baris = self._terlihat(hari_ini)
        if filter_.q:
            baris = [
                b
                for b in baris
                if filter_.q.lower() in b.nama.lower() or filter_.q.lower() in (b.penyelenggara or "").lower()
            ]
        if filter_.jenjang:
            baris = [b for b in baris if filter_.jenjang in (b.jenjang or [])]
        if filter_.negara:
            baris = [b for b in baris if b.negara == filter_.negara]
        if kursor:
            tgl, ident = baca_kursor(kursor)
            baris = [b for b in baris if (b.tenggat, str(b.id)) > (tgl, str(ident))]
        berikut = None
        if len(baris) > batas:
            baris = baris[:batas]
            berikut = kodekan_kursor(baris[-1].tenggat, baris[-1].id)
        return HalamanBeasiswa(item=baris, kursor_berikut=berikut)

    def detail(self, beasiswa_id: uuid.UUID, hari_ini: date):
        b = next((x for x in self._terlihat(hari_ini) if x.id == beasiswa_id), None)
        if b is None:
            return None
        return DetailBeasiswa(
            beasiswa=b, persyaratan=self.syarat.get(b.id, []), berkas_wajib=self.berkas.get(b.id, [])
        )
