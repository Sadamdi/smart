"""Enkripsi data pengguna saat disimpan di server, meniru pola Kelilink (`trailCrypto.ts`): AES-256-GCM.

Berkas dokumen dan teks hasil ekstraksinya dienkripsi di disk; server mendekripsi hanya saat dibutuhkan (menampilkan berkas
kepada pemiliknya atau menyusun konteks untuk chatbot). Kunci berasal dari `KUNCI_ENKRIPSI` (32 byte, base64), atau
diturunkan dari `JWT_SECRET` lewat HKDF-SHA256 agar tidak ada data yang tersimpan polos. Setiap berkas memakai nonce acak
12 byte dan data terautentikasi (AAD) berupa konteks, sehingga berkas yang dipindah antarpengguna gagal dibuka.
Berkas lama (Fernet atau polos) tetap terbaca. Di perjalanan, data dilindungi TLS (HTTPS).

Format: b"SM1" + nonce(12) + ciphertext+tag.
"""

import base64

from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF

from app.core.config import Settings

AWAL = b"SM1"
_NONCE = 12


def _kunci(settings: Settings) -> bytes:
    if settings.kunci_enkripsi:
        mentah = base64.urlsafe_b64decode(settings.kunci_enkripsi.encode() + b"=" * (-len(settings.kunci_enkripsi) % 4))
        if len(mentah) != 32:
            raise ValueError("KUNCI_ENKRIPSI harus 32 byte (base64)")
        return mentah
    return HKDF(algorithm=hashes.SHA256(), length=32, salt=None, info=b"smart-data-pengguna/v1").derive(
        settings.jwt_secret.encode()
    )


def enkripsi(settings: Settings, data: bytes, konteks: bytes = b"") -> bytes:
    import os

    nonce = os.urandom(_NONCE)
    return AWAL + nonce + AESGCM(_kunci(settings)).encrypt(nonce, data, konteks)


def dekripsi(settings: Settings, data: bytes, konteks: bytes = b"") -> bytes:
    """Mendekripsi; format lama (Fernet) dan berkas polos dikembalikan apa adanya agar tetap terbaca."""
    if data.startswith(AWAL):
        return AESGCM(_kunci(settings)).decrypt(data[3 : 3 + _NONCE], data[3 + _NONCE :], konteks)
    if data.startswith(b"gAAAA"):
        try:
            return Fernet(base64.urlsafe_b64encode(_kunci(settings))).decrypt(data)
        except InvalidToken:
            return data
    return data


def terenkripsi(data: bytes) -> bool:
    return data.startswith(AWAL) or data.startswith(b"gAAAA")
