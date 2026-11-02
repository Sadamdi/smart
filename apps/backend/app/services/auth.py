import uuid

from app.core.config import Settings
from app.core.errors import Conflict, Forbidden, NotFound, Unauthorized
from app.core.ratelimit import PembatasPercobaan
from app.core.security import AKSES, PENYEGAR, baca_token, buat_token, cek_sandi, hash_sandi
from app.models import Pengguna
from app.repositories.pengguna import PenggunaRepo
from app.schemas.pengguna import DaftarIn, GantiSandiIn, MasukIn, TokenOut


def _token(pengguna: Pengguna, settings: Settings) -> TokenOut:
    versi = pengguna.versi_token or 0
    return TokenOut(
        token_akses=buat_token(pengguna.id, versi, AKSES, settings),
        token_penyegar=buat_token(pengguna.id, versi, PENYEGAR, settings),
        kedaluwarsa_detik=settings.jwt_access_menit * 60,
    )


def daftar(repo: PenggunaRepo, data: DaftarIn, settings: Settings) -> tuple[Pengguna, TokenOut]:
    email = data.email.lower()
    if repo.by_email(email) is not None:
        raise Conflict("Email sudah terdaftar")
    # Peran selalu mahasiswa. Akun admin dibuat lewat prosedur terpisah, bukan dari masukan pengguna.
    pengguna = Pengguna(
        id=uuid.uuid4(),
        email=email,
        kata_sandi=hash_sandi(data.kata_sandi),
        nama=data.nama,
        peran="mahasiswa",
        versi_token=0,
        preferensi_notifikasi={"email": True, "push": True},
    )
    pengguna = repo.tambah(pengguna)
    return pengguna, _token(pengguna, settings)


def masuk(repo: PenggunaRepo, data: MasukIn, settings: Settings, pembatas: PembatasPercobaan) -> TokenOut:
    email = data.email.lower()
    pembatas.periksa(email)
    pengguna = repo.by_email(email)
    # cek_sandi selalu menghitung hash (juga bila email tidak ada) agar waktu respons tidak membocorkan akun.
    benar = cek_sandi(pengguna.kata_sandi if pengguna else None, data.kata_sandi)
    if pengguna is None or not benar:
        pembatas.catat_gagal(email)
        raise Unauthorized("Email atau kata sandi salah")
    pembatas.reset(email)
    return _token(pengguna, settings)


def pengguna_dari_token(repo: PenggunaRepo, token: str, jenis: str, settings: Settings) -> Pengguna:
    pengguna_id, versi = baca_token(token, jenis, settings)
    pengguna = repo.by_id(pengguna_id)
    if pengguna is None or (pengguna.versi_token or 0) != versi:
        raise Unauthorized("Token tidak berlaku lagi")
    return pengguna


def segarkan(repo: PenggunaRepo, token_penyegar: str, settings: Settings) -> TokenOut:
    return _token(pengguna_dari_token(repo, token_penyegar, PENYEGAR, settings), settings)


def keluar(repo: PenggunaRepo, pengguna: Pengguna) -> None:
    """Menaikkan versi token: semua token akses dan penyegar milik pengguna ini tidak berlaku lagi."""
    repo.naikkan_versi(pengguna)


def ganti_kata_sandi(repo: PenggunaRepo, pengguna: Pengguna, data: GantiSandiIn, settings: Settings) -> TokenOut:
    if not cek_sandi(pengguna.kata_sandi, data.kata_sandi_lama):
        raise Forbidden("Kata sandi lama salah")
    pengguna.kata_sandi = hash_sandi(data.kata_sandi_baru)
    pengguna = repo.naikkan_versi(pengguna)
    return _token(pengguna, settings)


def hapus_akun(repo: PenggunaRepo, pengguna: Pengguna) -> None:
    if repo.by_id(pengguna.id) is None:
        raise NotFound("Akun tidak ditemukan")
    repo.hapus(pengguna)
