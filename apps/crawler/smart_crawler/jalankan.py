"""Menjalankan pemantau UIN Malang: periksa robots.txt, ambil laman, ekstrak, simpan.

Pemakaian (dari apps/crawler, dengan DATABASE_URL pengembangan):
    uv run python -m smart_crawler.jalankan
"""

from urllib.parse import urljoin

import httpx

from smart_crawler.robots import USER_AGENT, boleh_diambil
from smart_crawler.simpan import simpan, url_db_dari_env
from smart_crawler.uinmalang import URL_SUMBER, ekstrak


def main() -> None:
    kepala = {"User-Agent": USER_AGENT}
    with httpx.Client(headers=kepala, timeout=30, follow_redirects=True) as c:
        robots = c.get(urljoin(URL_SUMBER, "/robots.txt")).text
        if not boleh_diambil(robots, URL_SUMBER):
            raise SystemExit("robots.txt melarang pengambilan laman ini")
        html = c.get(URL_SUMBER + "/").text
    baris = ekstrak(html)
    print(f"Terbaca {len(baris)} program")
    print(simpan(url_db_dari_env(), baris))


if __name__ == "__main__":
    main()
