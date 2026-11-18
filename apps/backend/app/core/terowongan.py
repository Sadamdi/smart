"""Terowongan terenkripsi tingkat aplikasi, di atas TLS (porting dari `secureTunnel.ts` dan `secureChannel.ts` Kelilink).

Aplikasi hanya menyimpan kunci PUBLIK X25519 server. Tiap sesi membuat pasangan kunci sementara lalu mengirim
setengah publiknya; kedua sisi menurunkan kunci AES-256-GCM yang sama dari rahasia bersama dengan HKDF-SHA256.
Setiap panggilan dari aplikasi menjadi satu `POST /api/v1/secure` berisi amplop: di dalamnya ada metode, jalur, header
(termasuk token), dan isi permintaan sebenarnya. Pihak yang mengintip koneksi atau log proksi hanya melihat satu
alamat dan jawaban 200. Middleware membuka amplop, menjalankan permintaan dalam aplikasi seperti biasa, lalu
mengembalikan jawabannya tersegel.

Amplop permintaan : {"v":1,"kid":..,"k":<kunci publik klien b64url>,"n":<nonce>,"c":<cipher+tag>}
Isi permintaan    : {"t":<ms>,"m":METODE,"u":"/api/v1/..","h":{..},"b":"teks" | "bx":"base64 biner"}
Isi jawaban       : {"s":status,"h":{..},"b":"teks" | "bx":"base64 biner"}
"""

import base64
import json
import os
import time
from collections import OrderedDict
from dataclasses import dataclass
from urllib.parse import urlsplit

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey, X25519PublicKey
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat

from app.core.config import Settings, get_settings

VERSI = 1
JALUR = "/api/v1/secure"
_NONCE = 12
BATAS_AMPLOP = 16 * 1024 * 1024
KEMIRINGAN_MS = 5 * 60 * 1000
METODE_BOLEH = {"GET", "POST", "PUT", "PATCH", "DELETE"}
# Satu-satunya header yang boleh dibawa di dalam amplop.
HEADER_DALAM = {"authorization", "content-type", "idempotency-key", "accept-language", "x-install-id"}
# Header koneksi asli yang dibutuhkan kode di bawahnya (IP klien, protokol).
HEADER_LUAR = {"host", "x-forwarded-for", "x-forwarded-proto", "x-real-ip", "user-agent"}
HEADER_JAWABAN = {"content-type", "retry-after", "content-disposition", "cache-control"}


def b64u_enc(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def b64u_dec(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def aad_permintaan(kid: str, k: str) -> bytes:
    return f"sm2|tun|{kid}|{k}".encode()


def aad_jawaban(nonce: str) -> bytes:
    return f"sm2|tun|res|{nonce}".encode()


@dataclass
class KunciServer:
    kid: str
    privat: X25519PrivateKey
    publik_mentah: bytes


def muat_kunci(kid: str, privat_b64: str) -> KunciServer:
    mentah = base64.b64decode(privat_b64 + "=" * (-len(privat_b64) % 4))
    if len(mentah) != 32:
        raise ValueError(f"Kunci terowongan {kid} harus 32 byte")
    p = X25519PrivateKey.from_private_bytes(mentah)
    return KunciServer(kid, p, p.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw))


def buat_pasangan() -> tuple[str, str]:
    """Pasangan kunci baru: (privat_b64, publik_b64), mentah 32 byte."""
    p = X25519PrivateKey.generate()
    from cryptography.hazmat.primitives.serialization import NoEncryption, PrivateFormat

    privat = p.private_bytes(Encoding.Raw, PrivateFormat.Raw, NoEncryption())
    return base64.b64encode(privat).decode(), base64.b64encode(
        p.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw)
    ).decode()


@dataclass
class KunciSesi:
    badan: bytes
    jawaban: bytes


def turunkan(server: KunciServer, publik_klien: bytes) -> KunciSesi:
    if len(publik_klien) != 32:
        raise ValueError("panjang kunci klien salah")
    bersama = server.privat.exchange(X25519PublicKey.from_public_bytes(publik_klien))
    if not any(bersama):
        raise ValueError("rahasia bersama tidak sah")
    garam = publik_klien + server.publik_mentah

    def kunci(info: str) -> bytes:
        return HKDF(algorithm=hashes.SHA256(), length=32, salt=garam, info=f"smart/v1/{info}".encode()).derive(bersama)

    return KunciSesi(kunci("body"), kunci("response"))


def segel(kunci: bytes, polos: bytes, aad: bytes) -> dict:
    nonce = os.urandom(_NONCE)
    return {"n": b64u_enc(nonce), "c": b64u_enc(AESGCM(kunci).encrypt(nonce, polos, aad))}


def buka(kunci: bytes, n: str, c: str, aad: bytes) -> bytes:
    nonce, data = b64u_dec(n), b64u_dec(c)
    if len(nonce) != _NONCE or len(data) < 16:
        raise ValueError("amplop rusak")
    return AESGCM(kunci).decrypt(nonce, data, aad)


class _CacheSesi:
    """LRU kecil agar satu ECDH melayani seluruh permintaan satu sesi aplikasi."""

    def __init__(self, maks: int = 2000, umur_ms: int = 30 * 60 * 1000):
        self._d: OrderedDict[str, tuple[KunciSesi, int]] = OrderedDict()
        self.maks, self.umur = maks, umur_ms

    def ambil(self, kunci: str, sekarang: int) -> KunciSesi | None:
        h = self._d.get(kunci)
        if h is None:
            return None
        if sekarang - h[1] > self.umur:
            del self._d[kunci]
            return None
        self._d.move_to_end(kunci)
        return h[0]

    def simpan(self, kunci: str, nilai: KunciSesi, sekarang: int) -> None:
        self._d[kunci] = (nilai, sekarang)
        while len(self._d) > self.maks:
            self._d.popitem(last=False)


def _galat(status: int, kode: str, pesan: str, rincian: dict | None = None) -> bytes:
    e: dict = {"code": kode, "message": pesan}
    if rincian:
        e["details"] = rincian
    return json.dumps({"success": False, "error": e}).encode()


class TerowonganMiddleware:
    """Middleware ASGI. Permintaan selain `POST /api/v1/secure` lewat tanpa diubah (mode `optional`)."""

    def __init__(self, app, settings_fn=get_settings, sekarang_ms=None):
        self.app = app
        self._settings_fn = settings_fn
        self._now = sekarang_ms or (lambda: int(time.time() * 1000))
        self._sesi = _CacheSesi()
        self._nonce: dict[str, int] = {}
        self._kunci_cache: tuple[tuple, dict[str, KunciServer]] | None = None

    def _kunci(self, s: Settings) -> dict[str, KunciServer]:
        ciri = (s.terowongan_kunci_privat, s.terowongan_kid, s.terowongan_kunci_lama)
        if self._kunci_cache and self._kunci_cache[0] == ciri:
            return self._kunci_cache[1]
        d: dict[str, KunciServer] = {}
        if s.terowongan_kunci_privat:
            d[s.terowongan_kid] = muat_kunci(s.terowongan_kid, s.terowongan_kunci_privat)
        for butir in [x.strip() for x in s.terowongan_kunci_lama.split(",") if x.strip()]:
            kid, _, priv = butir.partition(":")
            if kid and priv:
                d[kid] = muat_kunci(kid, priv)
        self._kunci_cache = (ciri, d)
        return d

    def _ingat(self, nonce: str, sekarang: int) -> bool:
        if len(self._nonce) >= 20_000:
            for k in [k for k, v in self._nonce.items() if v < sekarang]:
                del self._nonce[k]
            if len(self._nonce) >= 20_000:
                self._nonce.pop(next(iter(self._nonce)))
        if self._nonce.get(nonce, 0) >= sekarang:
            return False
        self._nonce[nonce] = sekarang + 2 * KEMIRINGAN_MS
        return True

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            return await self.app(scope, receive, send)
        s = self._settings_fn()
        kunci = self._kunci(s)
        mode = "off" if not kunci else s.terowongan_mode
        if scope["method"] != "POST" or scope["path"] != JALUR:
            if mode == "required" and scope["path"].startswith("/api/v1/") and scope["method"] != "OPTIONS":
                if scope["path"] not in ("/api/v1/health", "/api/v1/app/versi"):
                    return await self._kirim_polos(
                        send,
                        426,
                        _galat(
                            426, "SECURE_CHANNEL_REQUIRED", "Perbarui aplikasi SMART ke versi terbaru untuk melanjutkan."
                        ),
                    )
            return await self.app(scope, receive, send)
        if mode == "off":
            return await self._kirim_polos(
                send, 400, _galat(400, "SECURE_CHANNEL_UNAVAILABLE", "Kanal aman belum aktif di server.")
            )

        # ---- baca amplop ----
        potongan, total = [], 0
        while True:
            m = await receive()
            if m["type"] == "http.disconnect":
                return
            potongan.append(m.get("body", b""))
            total += len(potongan[-1])
            if total > BATAS_AMPLOP:
                return await self._kirim_polos(send, 413, _galat(413, "PAYLOAD_TOO_LARGE", "Isi permintaan terlalu besar."))
            if not m.get("more_body"):
                break
        try:
            amplop = json.loads(b"".join(potongan))
            ok = (
                isinstance(amplop, dict)
                and amplop.get("v") == VERSI
                and all(isinstance(amplop.get(x), str) for x in ("kid", "k", "n", "c"))
                and len(b64u_dec(amplop["k"])) == 32
            )
        except Exception:
            ok = False
        server = kunci.get(amplop["kid"]) if ok else None
        if not ok or server is None:
            return await self._kirim_polos(
                send, 400, _galat(400, "SECURE_CHANNEL_INVALID", "Permintaan terenkripsi tidak valid.")
            )

        sekarang = self._now()
        try:
            id_sesi = f"{server.kid}:{amplop['k']}"
            ks = self._sesi.ambil(id_sesi, sekarang)
            if ks is None:
                ks = turunkan(server, b64u_dec(amplop["k"]))
                self._sesi.simpan(id_sesi, ks, sekarang)
            dalam = json.loads(buka(ks.badan, amplop["n"], amplop["c"], aad_permintaan(server.kid, amplop["k"])))
            assert isinstance(dalam, dict)
        except Exception:
            return await self._kirim_polos(
                send, 400, _galat(400, "SECURE_CHANNEL_INVALID", "Permintaan terenkripsi tidak bisa dibuka.")
            )

        metode = str(dalam.get("m", "")).upper()
        url = dalam.get("u") if isinstance(dalam.get("u"), str) else ""
        try:
            dikirim = float(dalam.get("t"))
        except (TypeError, ValueError):
            dikirim = float("nan")
        if not abs(sekarang - dikirim) <= KEMIRINGAN_MS:
            return await self._kirim_polos(
                send,
                400,
                _galat(
                    400, "SECURE_CHANNEL_STALE", "Jam perangkat tidak cocok dengan server.", {"serverTime": sekarang // 1000}
                ),
            )
        if (
            metode not in METODE_BOLEH
            or not url.startswith("/api/v1/")
            or url.startswith(JALUR)
            or ".." in url
            or len(url) > 4096
        ):
            return await self._kirim_polos(
                send, 400, _galat(400, "SECURE_CHANNEL_INVALID", "Permintaan terenkripsi tidak valid.")
            )
        if not self._ingat(amplop["n"], sekarang):
            return await self._kirim_polos(
                send, 400, _galat(400, "SECURE_CHANNEL_REPLAY", "Permintaan ini sudah pernah diproses.")
            )

        # ---- ubah menjadi permintaan dalam ----
        header: list[tuple[bytes, bytes]] = [
            (k, v) for k, v in scope["headers"] if k.decode("latin-1").lower() in HEADER_LUAR
        ]
        for nama, nilai in (dalam.get("h") or {}).items():
            n = str(nama).lower()
            if n in HEADER_DALAM and isinstance(nilai, str):
                header.append((n.encode("latin-1"), nilai.encode("latin-1", "ignore")))
        if dalam.get("bx"):
            isi = base64.b64decode(dalam["bx"])
        elif isinstance(dalam.get("b"), str) and metode != "GET":
            isi = dalam["b"].encode("utf8")
        else:
            isi = b""
        header.append((b"content-length", str(len(isi)).encode()))
        u = urlsplit(url)
        lingkup = dict(scope)
        lingkup.update(
            method=metode,
            path=u.path,
            raw_path=u.path.encode(),
            query_string=u.query.encode(),
            headers=header,
            state={},
        )
        terkirim = False

        async def terima():
            nonlocal terkirim
            if terkirim:
                return {"type": "http.disconnect"}
            terkirim = True
            return {"type": "http.request", "body": isi, "more_body": False}

        hasil: dict = {"status": 500, "header": {}, "badan": bytearray()}

        async def tangkap(m):
            if m["type"] == "http.response.start":
                hasil["status"] = m["status"]
                for k, v in m.get("headers", []):
                    n = k.decode("latin-1").lower()
                    if n in HEADER_JAWABAN:
                        hasil["header"][n] = v.decode("latin-1")
            elif m["type"] == "http.response.body":
                hasil["badan"] += m.get("body", b"")

        try:
            await self.app(lingkup, terima, tangkap)
        except Exception:
            hasil = {
                "status": 500,
                "header": {"content-type": "application/json"},
                "badan": bytearray(_galat(500, "INTERNAL", "Terjadi kesalahan pada server.")),
            }
        jenis = hasil["header"].get("content-type", "")
        polos: dict = {"s": hasil["status"], "h": hasil["header"]}
        if jenis.startswith(("application/json", "text/")):
            polos["b"] = bytes(hasil["badan"]).decode("utf8", "replace")
        else:
            polos["bx"] = base64.b64encode(bytes(hasil["badan"])).decode()
        tersegel = segel(ks.jawaban, json.dumps(polos).encode(), aad_jawaban(amplop["n"]))
        await self._kirim_polos(send, 200, json.dumps({"v": VERSI, **tersegel}).encode())

    @staticmethod
    async def _kirim_polos(send, status: int, badan: bytes):
        await send(
            {
                "type": "http.response.start",
                "status": status,
                "headers": [
                    (b"content-type", b"application/json"),
                    (b"cache-control", b"no-store"),
                    (b"content-length", str(len(badan)).encode()),
                ],
            }
        )
        await send({"type": "http.response.body", "body": badan})
