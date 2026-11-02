"""Hash kata sandi (Argon2) dan token JWT (akses dan penyegar).

Token membawa `ver` (versi_token pengguna). Saat logout atau ganti kata sandi versi dinaikkan,
sehingga semua token lama ditolak tanpa tabel daftar-cabut tambahan.
"""

import uuid
from datetime import UTC, datetime, timedelta

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError

from app.core.config import Settings
from app.core.errors import Unauthorized

_hasher = PasswordHasher()
# Hash palsu untuk menyamakan waktu respons bila email tidak ditemukan.
_HASH_PALSU = _hasher.hash("kata-sandi-palsu-untuk-menyamakan-waktu")

AKSES = "akses"
PENYEGAR = "penyegar"


def hash_sandi(sandi: str) -> str:
    return _hasher.hash(sandi)


def cek_sandi(hash_tersimpan: str | None, sandi: str) -> bool:
    try:
        return _hasher.verify(hash_tersimpan or _HASH_PALSU, sandi) and hash_tersimpan is not None
    except (VerificationError, InvalidHashError):
        return False


def _wajib_rahasia(settings: Settings) -> str:
    if len(settings.jwt_secret) < 32:
        raise RuntimeError("JWT_SECRET belum diisi atau terlalu pendek (minimal 32 karakter).")
    return settings.jwt_secret


def buat_token(pengguna_id: uuid.UUID, versi: int, jenis: str, settings: Settings, sekarang: datetime | None = None) -> str:
    sekarang = sekarang or datetime.now(UTC)
    umur = timedelta(minutes=settings.jwt_access_menit) if jenis == AKSES else timedelta(days=settings.jwt_refresh_hari)
    isi = {
        "sub": str(pengguna_id),
        "typ": jenis,
        "ver": versi,
        "iat": sekarang,
        "exp": sekarang + umur,
        "jti": uuid.uuid4().hex,
    }
    return jwt.encode(isi, _wajib_rahasia(settings), algorithm="HS256")


def baca_token(token: str, jenis: str, settings: Settings) -> tuple[uuid.UUID, int]:
    """Mengembalikan (pengguna_id, versi) atau melempar Unauthorized."""
    try:
        isi = jwt.decode(token, _wajib_rahasia(settings), algorithms=["HS256"], options={"require": ["exp", "sub", "typ"]})
        if isi.get("typ") != jenis:
            raise Unauthorized("Jenis token tidak sesuai")
        return uuid.UUID(isi["sub"]), int(isi.get("ver", 0))
    except jwt.ExpiredSignatureError as exc:
        raise Unauthorized("Token kedaluwarsa") from exc
    except (jwt.InvalidTokenError, ValueError) as exc:
        raise Unauthorized("Token tidak valid") from exc
