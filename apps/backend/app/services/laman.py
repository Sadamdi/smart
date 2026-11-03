"""Pengambilan laman publik secara aman untuk pemantau dan validasi AI.

Hanya http(s), menolak alamat internal (SSRF), mematuhi robots.txt, membatasi ukuran, dan mengubah HTML menjadi teks
dengan tautan tetap terbaca. Isi laman adalah data tidak tepercaya: tidak pernah dijalankan dan tidak dianggap perintah.
"""

import ipaddress
import re
import socket
from dataclasses import dataclass
from html import unescape
from urllib import robotparser
from urllib.parse import urljoin, urlparse

import httpx

USER_AGENT = "SMARTBot/1.0 (+proyek kuliah UIN Malang; pemantau beasiswa)"
UKURAN_MAKS = 1_500_000
TEKS_MAKS = 14000
LONCAT_MAKS = 3


class LamanGagal(Exception):
    """Laman tidak dapat diambil dengan aman; pesan aman ditampilkan ke admin."""


def periksa_alamat(url: str) -> None:
    u = urlparse(url)
    if u.scheme not in ("http", "https") or not u.hostname:
        raise LamanGagal("Alamat harus berupa http atau https")
    try:
        info = socket.getaddrinfo(u.hostname, u.port or (443 if u.scheme == "https" else 80), proto=socket.IPPROTO_TCP)
    except OSError as exc:
        raise LamanGagal("Domain tidak ditemukan") from exc
    for entri in info:
        if not ipaddress.ip_address(entri[4][0]).is_global:
            raise LamanGagal("Alamat internal tidak diizinkan")


@dataclass
class Jawaban:
    status_code: int
    jenis: str
    text: str


def _unduh(klien: httpx.Client, url: str) -> Jawaban:
    for _ in range(LONCAT_MAKS + 1):
        periksa_alamat(url)
        try:
            with klien.stream("GET", url) as r:
                if r.is_redirect and r.headers.get("location"):
                    url = urljoin(url, r.headers["location"])
                    continue
                isi = bytearray()
                for bagian in r.iter_bytes():
                    isi.extend(bagian)
                    if len(isi) > UKURAN_MAKS:
                        break
                jenis = r.headers.get("content-type", "")
                teks = bytes(isi[:UKURAN_MAKS]).decode(r.encoding or "utf-8", errors="replace")
                return Jawaban(r.status_code, jenis, teks)
        except httpx.HTTPError as exc:
            raise LamanGagal("Laman tidak dapat dibuka") from exc
    raise LamanGagal("Terlalu banyak pengalihan")


def boleh_diambil(klien: httpx.Client, url: str) -> bool:
    u = urlparse(url)
    robots_url = f"{u.scheme}://{u.netloc}/robots.txt"
    try:
        r = _unduh(klien, robots_url)
    except LamanGagal:
        return True  # robots.txt tidak dapat dibaca: perlakukan seperti tidak ada
    if r.status_code in (404, 410):
        return True
    if r.status_code >= 400:
        return False
    parser = robotparser.RobotFileParser()
    parser.parse(r.text.splitlines())
    return parser.can_fetch(USER_AGENT, url)


def html_ke_teks(html: str, dasar: str) -> str:
    h = re.sub(r"(?is)<(script|style|noscript|svg|head)\b.*?</\1>", " ", html)
    h = re.sub(
        r'(?is)<a\b[^>]*?href=["\']([^"\']+)["\'][^>]*>(.*?)</a>',
        lambda m: f" {re.sub(r'<[^>]+>', ' ', m.group(2))} [{urljoin(dasar, unescape(m.group(1)))}] ",
        h,
    )
    h = re.sub(r"(?i)<br\s*/?>|</(p|div|li|tr|h\d)>", "\n", h)
    h = unescape(re.sub(r"<[^>]+>", " ", h))
    h = re.sub(r"[ \t\r\f\v\xa0]+", " ", h)
    h = re.sub(r"\s*\n\s*", "\n", h).strip()
    return h[:TEKS_MAKS]


def ambil_teks(url: str, klien: httpx.Client | None = None) -> str:
    """Mengambil laman, memeriksa robots.txt, dan mengembalikan teksnya."""
    punya = klien is None
    klien = klien or httpx.Client(headers={"User-Agent": USER_AGENT}, timeout=20, follow_redirects=False)
    try:
        if not boleh_diambil(klien, url):
            raise LamanGagal("robots.txt melarang pengambilan laman ini")
        r = _unduh(klien, url)
        if r.status_code >= 400:
            raise LamanGagal(f"Laman mengembalikan status {r.status_code}")
        if "html" not in r.jenis and "text" not in r.jenis:
            raise LamanGagal("Isi laman bukan teks atau HTML")
        return html_ke_teks(r.text, url)
    finally:
        if punya:
            klien.close()
