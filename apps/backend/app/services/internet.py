"""Mengambil teks laman resmi beasiswa (alat internet untuk chatbot server).

Hanya HTTPS ke host publik: alamat yang menunjuk ke jaringan pribadi, loopback, atau metadata awan ditolak (SSRF).
Hasil dipotong dan disimpan sementara agar tidak membebani laman sumber.
"""

import ipaddress
import re
import socket
import time
from urllib.parse import urlparse

import httpx

_CACHE: dict[str, tuple[float, str]] = {}
TTL_DETIK = 600
MAKS_KARAKTER = 3000


def alamat_aman(url: str) -> bool:
    u = urlparse(url)
    if u.scheme != "https" or not u.hostname:
        return False
    try:
        for info in socket.getaddrinfo(u.hostname, u.port or 443, proto=socket.IPPROTO_TCP):
            ip = ipaddress.ip_address(info[4][0])
            if ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved or ip.is_multicast:
                return False
    except (socket.gaierror, ValueError):
        return False
    return True


def bersihkan_html(html: str) -> str:
    teks = re.sub(r"<(script|style|noscript)[^>]*>.*?</\1>", " ", html, flags=re.DOTALL | re.IGNORECASE)
    teks = re.sub(r"<[^>]+>", " ", teks)
    teks = re.sub(r"&nbsp;|&amp;|&quot;|&#\d+;", " ", teks)
    return re.sub(r"\s+", " ", teks).strip()


def ambil_teks(url: str, timeout: float = 6.0) -> str | None:
    """Teks laman (maksimal 3000 karakter) atau None bila tidak aman, gagal, atau bukan HTML/teks."""
    sekarang = time.monotonic()
    ada = _CACHE.get(url)
    if ada and sekarang - ada[0] < TTL_DETIK:
        return ada[1] or None
    if not alamat_aman(url):
        return None
    try:
        r = httpx.get(url, timeout=timeout, follow_redirects=False, headers={"User-Agent": "SMART-Chatbot/1.0"})
        if r.status_code >= 400 or "text" not in r.headers.get("content-type", "text"):
            return None
        teks = bersihkan_html(r.text)[:MAKS_KARAKTER]
    except httpx.HTTPError:
        teks = ""
    _CACHE[url] = (sekarang, teks)
    return teks or None
