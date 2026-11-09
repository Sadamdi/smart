"""Uji end-to-end terhadap API yang sedang berjalan (lokal atau online lewat proksi web). Menulis laporan JSON.

Kredensial dibaca dari lingkungan, tidak pernah disimpan di repo:
    SMART_E2E_BASE   mis. https://smart-web-three.vercel.app/backend/api/v1
    SMART_E2E_EMAIL  dan SMART_E2E_SANDI   akun mahasiswa uji
    SMART_E2E_ADMIN_EMAIL dan SMART_E2E_ADMIN_SANDI   (opsional) akun admin uji
Pemakaian (dari apps/backend): uv run python -m scripts.uji_e2e laporan.json
"""

import json
import os
import sys
import time
from datetime import date, timedelta

import httpx

BASE = os.environ.get("SMART_E2E_BASE", "http://127.0.0.1:8000/api/v1").rstrip("/")
NOL = "00000000-0000-0000-0000-000000000000"
HASIL: list[dict] = []


def cek(kode: str, nama: str, fungsi):
    mulai = time.perf_counter()
    ket = None
    try:
        ket = fungsi()
        status, catatan = "lulus", ket if isinstance(ket, str) else ""
    except AssertionError as exc:
        status, catatan = "gagal", str(exc)[:300]
    except Exception as exc:  # noqa: BLE001
        status, catatan = "galat", f"{type(exc).__name__}: {str(exc)[:250]}"
    ms = round((time.perf_counter() - mulai) * 1000)
    HASIL.append({"kode": kode, "nama": nama, "status": status, "ms": ms, "catatan": catatan})
    print(f"[{status.upper():6}] {kode} {nama} ({ms} ms) {catatan}", flush=True)
    return ket


def _ass(kondisi: bool, pesan: str = "kondisi tidak terpenuhi") -> str:
    assert kondisi, pesan
    return "ok"


def _lst(d) -> list:
    if isinstance(d, list):
        return d
    return d.get("item") or d.get("daftar") or []


def _login(c: httpx.Client, e: str, s: str) -> str:
    r = c.post("/auth/login", json={"email": e, "kata_sandi": s})
    assert r.status_code == 200, f"login {r.status_code}: {r.text[:120]}"
    d = r.json()["data"]
    for k in ("token_akses", "access_token", "akses"):
        if k in d:
            return d[k]
    raise AssertionError(f"kunci token tidak dikenal: {list(d)}")


def data(r: httpx.Response, kode: int = 200):
    assert r.status_code == kode, f"status {r.status_code}: {r.text[:150]}"
    j = r.json()
    assert j.get("success") is True, f"envelope: {str(j)[:150]}"
    return j["data"]


def main() -> None:
    email, sandi = os.environ.get("SMART_E2E_EMAIL"), os.environ.get("SMART_E2E_SANDI")
    if not (email and sandi):
        raise SystemExit("Isi SMART_E2E_EMAIL dan SMART_E2E_SANDI")
    c = httpx.Client(base_url=BASE, timeout=90, follow_redirects=False)
    tok: dict = {}

    def auth():
        return {"Authorization": f"Bearer {tok['akses']}"}

    def masuk():
        tok["akses"] = _login(c, email, sandi)
        return "token diterima"

    cek("S-01", "Health", lambda: _ass(data(c.get("/health")) is not None))
    cek("S-02", "Health siap (basis data)", lambda: str(data(c.get("/health/siap"))))
    cek("A-01", "Login benar", masuk)
    bad = {"email": email, "kata_sandi": "salah-sekali"}
    cek("A-02", "Login sandi salah ditolak 401", lambda: _ass(c.post("/auth/login", json=bad).status_code == 401))
    cek("A-03", "Tanpa token ditolak 401", lambda: _ass(c.get("/me").status_code == 401))
    palsu = {"Authorization": "Bearer x.y.z"}
    cek("A-04", "Token palsu ditolak 401", lambda: _ass(c.get("/me", headers=palsu).status_code == 401))
    cek(
        "A-05",
        "Mahasiswa ke admin ditolak 403",
        lambda: _ass(c.get("/admin/antrean-validasi", headers=auth()).status_code == 403),
    )
    me = cek("P-01", "Baca profil", lambda: data(c.get("/me", headers=auth()))) or {}
    cek(
        "P-02", "Profil lengkap terisi", lambda: _ass(bool(me.get("jenjang") and me.get("ipk") is not None), "profil kosong")
    )
    cek(
        "P-03",
        "Simpan profil tanpa mengubah isi",
        lambda: _ass(data(c.put("/me/profil", headers=auth(), json={"jenjang": me.get("jenjang")})) is not None),
    )
    cek(
        "P-04",
        "Validasi: IPK 5 ditolak 422",
        lambda: _ass(c.put("/me/profil", headers=auth(), json={"ipk": 5}).status_code == 422),
    )
    cek(
        "P-05",
        "Validasi: jenjang ngawur ditolak 422",
        lambda: _ass(c.put("/me/profil", headers=auth(), json={"jenjang": "S9"}).status_code == 422),
    )
    cek(
        "R-01", "Hitung ulang rekomendasi", lambda: str(len(_lst(data(c.post("/rekomendasi/hitung-ulang", headers=auth())))))
    )
    rek = cek("R-02", "Daftar rekomendasi", lambda: data(c.get("/rekomendasi", headers=auth())))
    items = _lst(rek or [])
    cek("R-03", "Rekomendasi tidak kosong", lambda: _ass(len(items) > 0, "kosong"))
    cek(
        "R-04",
        "Tiap rekomendasi punya kategori serta alasan atau catatan kekurangan",
        lambda: _ass(
            all(i.get("kategori") and (i.get("alasan") or i.get("catatan_kekurangan")) for i in items),
            "ada tanpa alasan atau catatan",
        ),
    )
    cek("R-05", "Tidak ada klaim pasti diterima", lambda: _ass("pasti diterima" not in json.dumps(items).lower()))
    cek("R-06", "Ringkasan rekomendasi", lambda: str(data(c.get("/rekomendasi/ringkasan", headers=auth()))))

    hal = cek("B-01", "Daftar beasiswa terbit", lambda: data(c.get("/beasiswa", headers=auth(), params={"batas": 20}))) or {}
    bs = _lst(hal)
    cek("B-02", "Daftar beasiswa tidak kosong", lambda: _ass(len(bs) > 0, "kosong"))
    kursor = hal.get("kursor_berikut") if isinstance(hal, dict) else None
    cek(
        "B-03",
        "Paginasi kursor halaman 2",
        lambda: _ass(
            kursor is None or len(_lst(data(c.get("/beasiswa", headers=auth(), params={"batas": 20, "kursor": kursor})))) > 0
        ),
    )
    cek(
        "B-04",
        "Cari q=beasiswa",
        lambda: _ass(data(c.get("/beasiswa", headers=auth(), params={"q": "beasiswa"})) is not None),
    )
    cek("B-05", "Detail beasiswa", lambda: _ass(data(c.get(f"/beasiswa/{bs[0]['id']}", headers=auth())) is not None))
    cek("B-06", "Id tidak ada 404", lambda: _ass(c.get(f"/beasiswa/{NOL}", headers=auth()).status_code == 404))
    cek(
        "B-07",
        "Kursor rusak ditolak",
        lambda: _ass(c.get("/beasiswa", headers=auth(), params={"kursor": "ngawur"}).status_code in (400, 422)),
    )

    bid = bs[0]["id"]
    cek(
        "T-01",
        "Simpan beasiswa",
        lambda: _ass(data(c.post(f"/beasiswa/{bid}/interaksi", headers=auth(), json={"aksi": "simpan"}), 201) is not None),
    )
    cek("T-02", "Muncul di tersimpan", lambda: _ass(bid in json.dumps(data(c.get("/me/tersimpan", headers=auth())))))
    dari, sampai = date.today().isoformat(), (date.today() + timedelta(days=365)).isoformat()
    cek(
        "T-03",
        "Kalender",
        lambda: _ass(data(c.get("/me/kalender", headers=auth(), params={"dari": dari, "sampai": sampai})) is not None),
    )
    cek(
        "T-04",
        "Hapus simpan",
        lambda: _ass(c.delete(f"/beasiswa/{bid}/interaksi/simpan", headers=auth()).status_code in (200, 204)),
    )
    tg = (
        cek(
            "T-05",
            "Buat tugas pribadi",
            lambda: data(c.post("/me/tugas", headers=auth(), json={"judul": "Tugas uji E2E", "tanggal": dari}), 201),
        )
        or {}
    )
    cek(
        "T-06",
        "Hapus tugas pribadi",
        lambda: _ass(c.delete(f"/me/tugas/{tg.get('id', NOL)}", headers=auth()).status_code in (200, 204)),
    )
    cek("N-01", "Notifikasi", lambda: _ass(data(c.get("/notifikasi", headers=auth())) is not None))
    cek("D-01", "Daftar dokumen", lambda: _ass(data(c.get("/me/dokumen", headers=auth())) is not None))
    cek("D-02", "Ekspor data pribadi", lambda: _ass(bool(data(c.get("/me/ekspor", headers=auth())))))
    exe = {"berkas": ("x.exe", b"MZ", "application/octet-stream")}
    cek(
        "D-03",
        "Berkas bukan dokumen ditolak",
        lambda: _ass(c.post("/me/dokumen", headers=auth(), data={"jenis": "cv"}, files=exe).status_code in (400, 415, 422)),
    )

    def chat():
        d = data(c.post("/chat", headers=auth(), json={"pesan": "Beasiswa apa yang cocok untuk saya? Jawab singkat."}))
        teks = json.dumps(d).lower()
        assert len(teks) > 40, "jawaban kosong"
        assert "pasti diterima" not in teks, "klaim pasti diterima"
        return "jawaban AI diterima"

    cek("C-01", "Chat AI menjawab dan tidak menjamin diterima", chat)
    cek(
        "C-02",
        "Chat pesan kosong ditolak",
        lambda: _ass(c.post("/chat", headers=auth(), json={"pesan": ""}).status_code == 422),
    )

    ae, asd = os.environ.get("SMART_E2E_ADMIN_EMAIL"), os.environ.get("SMART_E2E_ADMIN_SANDI")
    if ae and asd:
        adm: dict = {}

        def masuk_admin():
            adm["h"] = {"Authorization": f"Bearer {_login(c, ae, asd)}"}
            return "ok"

        cek("M-01", "Login admin", masuk_admin)
        h = adm.get("h", {})
        cek("M-02", "Admin: laporan", lambda: str(data(c.get("/admin/laporan", headers=h)))[:200])
        cek(
            "M-03",
            "Admin: antrean validasi",
            lambda: f"{len(_lst(data(c.get('/admin/antrean-validasi', headers=h))))} menunggu",
        )
        cek("M-04", "Admin: daftar sumber", lambda: f"{len(_lst(data(c.get('/admin/sumber', headers=h))))} sumber")
        cek("M-05", "Admin: pengaturan auto-validasi", lambda: str(data(c.get("/admin/pengaturan", headers=h))))

    ringkas = {s: sum(1 for x in HASIL if x["status"] == s) for s in ("lulus", "gagal", "galat")}
    ms = sorted(x["ms"] for x in HASIL)
    print(ringkas, flush=True)
    if len(sys.argv) > 1:
        isi = {
            "base": BASE,
            "tanggal": date.today().isoformat(),
            "ringkas": ringkas,
            "p50_ms": ms[len(ms) // 2],
            "hasil": HASIL,
        }
        with open(sys.argv[1], "w", encoding="utf-8") as f:
            json.dump(isi, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
