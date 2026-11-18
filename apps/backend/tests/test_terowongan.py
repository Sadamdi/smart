"""Terowongan terenkripsi: klien palsu meniru aplikasi (X25519, HKDF, AES-256-GCM), termasuk penolakan yang wajib."""

import base64
import json
import os

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey, X25519PublicKey
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
from fastapi import FastAPI, Request
from fastapi.responses import Response
from starlette.testclient import TestClient

from app.core import terowongan as t
from app.core.config import Settings
from tests.conftest import SETTINGS_UJI

PRIV, PUB = t.buat_pasangan()
S_AKTIF = Settings(**{**SETTINGS_UJI.model_dump(), "terowongan_kunci_privat": PRIV})
S_WAJIB = Settings(**{**SETTINGS_UJI.model_dump(), "terowongan_kunci_privat": PRIV, "terowongan_mode": "required"})
WAKTU = {"ms": 1_800_000_000_000}


class Klien:
    """Sisi aplikasi: sama dengan implementasi Dart."""

    def __init__(self, http, publik_server_b64=PUB, kid="k1"):
        self.http, self.kid = http, kid
        self.eph = X25519PrivateKey.generate()
        self.pub = t.b64u_enc(self.eph.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw))
        sp = base64.b64decode(publik_server_b64)
        bersama = self.eph.exchange(X25519PublicKey.from_public_bytes(sp))
        garam = t.b64u_dec(self.pub) + sp

        def k(info):
            return HKDF(algorithm=hashes.SHA256(), length=32, salt=garam, info=f"smart/v1/{info}".encode()).derive(bersama)

        self.k_badan, self.k_jawab = k("body"), k("response")

    def kirim(self, metode, url, header=None, body=None, bx=None, waktu=None, nonce=None, aad=None):
        dalam = {"t": WAKTU["ms"] if waktu is None else waktu, "m": metode, "u": url, "h": header or {}}
        if bx is not None:
            dalam["bx"] = base64.b64encode(bx).decode()
        elif body is not None:
            dalam["b"] = body if isinstance(body, str) else json.dumps(body)
        nonce_b = nonce or os.urandom(12)
        ct = AESGCM(self.k_badan).encrypt(nonce_b, json.dumps(dalam).encode(), aad or t.aad_permintaan(self.kid, self.pub))
        n = t.b64u_enc(nonce_b)
        r = self.http.post(t.JALUR, json={"v": 1, "kid": self.kid, "k": self.pub, "n": n, "c": t.b64u_enc(ct)})
        return r, n

    def buka(self, r, n):
        assert r.status_code == 200, r.text
        d = r.json()
        polos = AESGCM(self.k_jawab).decrypt(t.b64u_dec(d["n"]), t.b64u_dec(d["c"]), t.aad_jawaban(n))
        return json.loads(polos)


def bungkus(inner, settings=S_AKTIF):
    return TestClient(t.TerowonganMiddleware(inner, settings_fn=lambda: settings, sekarang_ms=lambda: WAKTU["ms"]))


def app_kecil():
    a = FastAPI()

    @a.get("/api/v1/halo")
    def halo(request: Request):
        return {"success": True, "data": {"auth": request.headers.get("authorization"), "q": request.query_params.get("x")}}

    @a.post("/api/v1/gema")
    async def gema(request: Request):
        return {
            "success": True,
            "data": {"isi": (await request.body()).decode("latin-1"), "tipe": request.headers.get("content-type")},
        }

    @a.get("/api/v1/biner")
    def biner():
        return Response(bytes(range(256)), media_type="application/pdf")

    @a.get("/api/v1/health")
    def sehat():
        return {"success": True}

    return a


def test_permintaan_dan_jawaban_menembus_terowongan():
    http = bungkus(app_kecil())
    k = Klien(http)
    r, n = k.kirim("GET", "/api/v1/halo?x=7", header={"Authorization": "Bearer abc", "X-Aneh": "dibuang"})
    d = k.buka(r, n)
    assert d["s"] == 200 and json.loads(d["b"])["data"] == {"auth": "Bearer abc", "q": "7"}
    assert "abc" not in r.text and "halo" not in r.text  # luar hanya melihat satu alamat, tanpa isi dan token


def test_isi_json_dan_biner_dua_arah():
    http = bungkus(app_kecil())
    k = Klien(http)
    r, n = k.kirim("POST", "/api/v1/gema", header={"Content-Type": "application/json"}, body={"a": 1})
    assert json.loads(json.loads(k.buka(r, n)["b"])["data"]["isi"]) == {"a": 1}
    mentah = bytes(range(256)) * 20 + b"\r\n--batas--"
    r, n = k.kirim("POST", "/api/v1/gema", header={"Content-Type": "multipart/form-data; boundary=batas"}, bx=mentah)
    dd = json.loads(k.buka(r, n)["b"])["data"]
    assert dd["tipe"].startswith("multipart/form-data") and dd["isi"].encode("latin-1") == mentah
    r, n = k.kirim("GET", "/api/v1/biner")
    d = k.buka(r, n)
    assert base64.b64decode(d["bx"]) == bytes(range(256)) and d["h"]["content-type"] == "application/pdf"


def test_penolakan_wajib():
    http = bungkus(app_kecil())
    k = Klien(http)
    nonce = os.urandom(12)  # ulang (replay) dengan nonce sama
    assert k.kirim("GET", "/api/v1/halo", nonce=nonce)[0].status_code == 200
    r, _ = k.kirim("GET", "/api/v1/halo", nonce=nonce)
    assert r.status_code == 400 and r.json()["error"]["code"] == "SECURE_CHANNEL_REPLAY"
    r, _ = k.kirim("GET", "/api/v1/halo", waktu=WAKTU["ms"] - 20 * 60 * 1000)  # jam meleset: server menyebut waktunya
    e = r.json()["error"]
    assert e["code"] == "SECURE_CHANNEL_STALE" and e["details"]["serverTime"] == WAKTU["ms"] // 1000
    assert k.kirim("GET", "/api/v1/halo", aad=b"lain")[0].status_code == 400  # data terautentikasi salah
    _, publik_lain = t.buat_pasangan()
    assert Klien(http, publik_server_b64=publik_lain).kirim("GET", "/api/v1/halo")[0].status_code == 400
    assert Klien(http, kid="x9").kirim("GET", "/api/v1/halo")[0].status_code == 400
    for url in ("/docs", "/api/v1/secure", "/api/v1/../docs"):
        assert k.kirim("GET", url)[0].status_code == 400, url
    assert k.kirim("TRACE", "/api/v1/halo")[0].status_code == 400
    assert http.post(t.JALUR, content=b"bukan json").status_code == 400
    assert http.post(t.JALUR, json={"v": 1}).status_code == 400


def test_mode_mati_dan_mode_wajib():
    mati = bungkus(app_kecil(), Settings(**{**SETTINGS_UJI.model_dump()}))
    assert mati.post(t.JALUR, json={}).json()["error"]["code"] == "SECURE_CHANNEL_UNAVAILABLE"
    assert mati.get("/api/v1/halo").status_code == 200  # tanpa kunci, tidak ada yang berubah
    wajib = bungkus(app_kecil(), S_WAJIB)
    assert wajib.get("/api/v1/halo").status_code == 426
    assert wajib.get("/api/v1/health").status_code == 200
    k = Klien(wajib)
    r, n = k.kirim("GET", "/api/v1/halo")
    assert k.buka(r, n)["s"] == 200
    assert bungkus(app_kecil(), S_AKTIF).get("/api/v1/halo").status_code == 200  # mode optional meneruskan


def test_aplikasi_sungguhan_lewat_terowongan_sama_dengan_permintaan_biasa(klien):
    from app.main import app as app_asli

    k = Klien(bungkus(app_asli))
    daftar = {"nama": "Nabila", "email": "nabila.t@example.com", "kata_sandi": "kata-sandi-panjang"}
    r, n = k.kirim("POST", "/api/v1/auth/register", header={"Content-Type": "application/json"}, body=daftar)
    d = k.buka(r, n)
    assert d["s"] == 201, d
    login = {"email": daftar["email"], "kata_sandi": daftar["kata_sandi"]}
    r, n = k.kirim("POST", "/api/v1/auth/login", header={"Content-Type": "application/json"}, body=login)
    token = json.loads(k.buka(r, n)["b"])["data"]["token_akses"]
    r, n = k.kirim("GET", "/api/v1/me", header={"Authorization": f"Bearer {token}"})
    lewat = k.buka(r, n)
    biasa = klien.get("/api/v1/me", headers={"Authorization": f"Bearer {token}"})
    assert lewat["s"] == biasa.status_code == 200 and json.loads(lewat["b"]) == biasa.json()
    r, n = k.kirim("GET", "/api/v1/me")
    assert k.buka(r, n)["s"] == 401  # kesalahan juga tersegel dan statusnya benar
