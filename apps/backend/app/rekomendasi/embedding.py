"""Lapis kedua: kemiripan teks profil dan beasiswa.

Server penempatan hanya 1 GB RAM, sehingga model embedding semantik tidak dipakai (diputuskan 16 November 2026). Pengemas
bawaan memakai hashing token dengan perluasan kata kunci per bidang (`BIDANG`), supaya minat seperti "kecerdasan buatan"
dan nama beasiswa seperti "Digital Talent" bertemu pada kata yang sama. Deterministik dan tanpa unduhan model.
"""

import hashlib
import math
import re
from typing import Protocol

DIMENSI = 384
_STOP = {"dan", "yang", "untuk", "dengan", "atau", "dari", "the", "and"}


# Gugus kata satu bidang: bila ada pemicunya di teks, kata gugus ikut ditambahkan (profil dan beasiswa).
BIDANG: dict[str, tuple[tuple[str, ...], str]] = {
    "teknologi": (
        (
            "teknologi",
            "informatika",
            "komputer",
            "software",
            "digital",
            "data",
            "kecerdasan",
            "machine",
            "learning",
            "siber",
            "informasi",
            "programming",
            "startup",
            "teknik",
        ),
        "teknologi informatika komputer digital data sains rekayasa stem",
    ),
    "kesehatan": (
        (
            "kesehatan",
            "kedokteran",
            "farmasi",
            "keperawatan",
            "gizi",
            "medis",
            "obat",
            "psikologi",
            "konseling",
            "kebidanan",
        ),
        "kesehatan kedokteran medis farmasi gizi keperawatan stem",
    ),
    "ekonomi": (
        ("ekonomi", "bisnis", "akuntansi", "manajemen", "keuangan", "kewirausahaan", "perbankan", "syariah", "dagang"),
        "ekonomi bisnis keuangan manajemen akuntansi perbankan syariah wirausaha",
    ),
    "pendidikan": (
        ("pendidikan", "guru", "keguruan", "pengajar", "pedagogi", "sekolah", "mengajar"),
        "pendidikan guru keguruan mengajar sekolah literasi",
    ),
    "sosial": (
        (
            "hukum",
            "sosial",
            "politik",
            "kebijakan",
            "publik",
            "komunikasi",
            "jurnalistik",
            "media",
            "pemerintahan",
            "antropologi",
        ),
        "sosial hukum politik kebijakan publik komunikasi media pemerintahan",
    ),
    "sains": (
        ("biologi", "kimia", "fisika", "matematika", "sains", "riset", "penelitian", "lingkungan", "konservasi", "energi"),
        "sains riset penelitian ilmiah biologi kimia fisika matematika lingkungan energi",
    ),
    "pertanian": (
        ("pertanian", "pangan", "agroteknologi", "perikanan", "peternakan", "kehutanan", "agribisnis", "kelautan"),
        "pertanian pangan agro perikanan peternakan kehutanan kelautan",
    ),
    "rekayasa": (
        ("sipil", "arsitektur", "mesin", "elektro", "infrastruktur", "industri", "kota", "konstruksi", "pertambangan"),
        "teknik rekayasa infrastruktur sipil arsitektur mesin elektro industri stem",
    ),
    "seni": (
        ("seni", "desain", "budaya", "bahasa", "sastra", "penerjemahan", "musik", "film", "kreatif"),
        "seni desain budaya bahasa sastra kreatif humaniora",
    ),
    "agama": (
        ("dakwah", "agama", "islam", "quran", "tahfidz", "pesantren", "syariah", "santri"),
        "agama islam dakwah quran pesantren keislaman",
    ),
}


def perluas(teks: str) -> str:
    """Menambahkan kata gugus bidang pada teks bila ada pemicu bidang itu."""
    rendah = teks.lower()
    token = set(re.findall(r"[a-z0-9]+", rendah))
    tambahan = [kata for pemicu, kata in BIDANG.values() if token.intersection(pemicu)]
    return f"{teks} {' '.join(tambahan)}" if tambahan else teks


class Pengemas(Protocol):
    def kemas(self, teks: str) -> list[float]: ...


class PengemasHash:
    def kemas(self, teks: str) -> list[float]:
        vek = [0.0] * DIMENSI
        for token in re.findall(r"[a-z0-9]+", perluas(teks).lower()):
            if token in _STOP or len(token) < 3:
                continue
            h = int(hashlib.sha1(token.encode()).hexdigest(), 16)  # noqa: S324 - bukan untuk keamanan
            vek[h % DIMENSI] += 1.0
        norma = math.sqrt(sum(x * x for x in vek))
        return [x / norma for x in vek] if norma else vek


def kemiripan(a: list[float], b: list[float]) -> float:
    """Cosine untuk vektor ternormalisasi non-negatif; hasil antara 0 dan 1."""
    return max(0.0, min(1.0, sum(x * y for x, y in zip(a, b, strict=True))))


KATA_KONDISI = {
    "disabilitas": "disabilitas difabel berkebutuhan khusus",
    "ekonomi_kurang_mampu": "kurang mampu tidak mampu ekonomi bantuan",
    "yatim_piatu": "yatim piatu",
    "daerah_3t": "daerah terpencil 3T tertinggal",
    "penghafal_quran": "hafiz penghafal quran tahfidz",
    "anak_tenaga_kesehatan": "tenaga kesehatan",
}


def teks_profil(
    minat: list[str] | None,
    program_studi: str | None,
    jenjang: str | None,
    kondisi_khusus: list[str] | None = None,
    catatan: str | None = None,
) -> str:
    kondisi = [KATA_KONDISI.get(k, k) for k in (kondisi_khusus or [])]
    return " ".join([*(minat or []), program_studi or "", jenjang or "", *kondisi, catatan or ""]).strip()


def teks_beasiswa(nama: str, penyelenggara: str | None, manfaat: str | None) -> str:
    return " ".join(x for x in (nama, penyelenggara, manfaat) if x)
