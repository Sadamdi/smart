"""Estimasi peluang diterima (persen), dihitung dari tiga hal yang bisa dijelaskan:

1. kecocokan syarat (kategori kelayakan: memenuhi, hampir, belum),
2. kekuatan profil (IPK, prestasi, organisasi, sertifikat, pengalaman, skor bahasa),
3. tingkat persaingan umum beasiswa (program bergengsi dan penuh biaya lebih ketat, program lokal lebih longgar).

Ini PERKIRAAN, bukan jaminan. SMART belum punya data hasil seleksi nyata, jadi angka ini adalah heuristik yang
transparan dan dapat ditinjau, bukan model yang dilatih dari hasil penerimaan. Sistem tidak pernah menyatakan
seseorang pasti diterima: nilai dibatasi 2 sampai 90 persen. Beasiswa tanpa syarat terukur tidak diberi estimasi.
"""

BOBOT_TINGKAT = {"sekolah": 0.2, "kota": 0.35, "provinsi": 0.5, "nasional": 0.8, "internasional": 1.0}

# Kata kunci persaingan ketat: program bergengsi dengan pesaing sangat banyak.
_KETAT = (
    "lpdp", "chevening", "fulbright", "australia awards", "mext", "monbukagakusho", "daad", "erasmus", "gates",
    "rhodes", "gks", "korean government", "knb", "turkiye", "türkiye", "turkey", "commonwealth", "stipendium hungaricum",
    "full scholarship", "fully funded", "fully-funded", "penuh",
)  # fmt: skip
# Kata kunci program yang umumnya lebih longgar: bantuan biaya, kuota besar, atau berbasis kampus dan daerah.
_LONGGAR = (
    "kip kuliah", "bidikmisi", "bantuan", "peningkatan prestasi", "ppa",
    "pemerintah daerah", "pemda", "yayasan", "kampus",
)  # fmt: skip

DASAR_KETAT = 0.18
DASAR_LONGGAR = 0.5
DASAR_DALAM = 0.35
DASAR_LUAR = 0.2

FAKTOR_KATEGORI = {"memenuhi": 1.0, "hampir_memenuhi": 0.55, "belum_memenuhi": 0.15}


def persaingan_dasar(nama: str, penyelenggara: str | None, luar_negeri: bool) -> float:
    """Peluang dasar seorang pelamar yang memenuhi syarat, sebelum memperhitungkan kekuatan profil."""
    teks = f"{nama} {penyelenggara or ''}".lower()
    if any(k in teks for k in _KETAT):
        return DASAR_KETAT
    if any(k in teks for k in _LONGGAR) and not luar_negeri:
        return DASAR_LONGGAR
    return DASAR_LUAR if luar_negeri else DASAR_DALAM


def _banyak(nilai: object, maks: int) -> float:
    n = len(nilai) if isinstance(nilai, list | tuple) else 0
    return min(n, maks) / maks


def kekuatan_profil(
    ipk: float | None,
    profil_lanjutan: dict | None,
    skor_bahasa: dict | None,
) -> float:
    """Kekuatan profil 0 sampai 1. Tiap bagian punya bobot tetap; bagian yang kosong menyumbang nol, kecuali IPK
    yang kosong dihitung sedang (0,4) supaya profil yang belum lengkap tidak langsung dianggap lemah."""
    pl = profil_lanjutan or {}
    nilai_ipk = 0.4 if ipk is None else max(0.0, min(1.0, (float(ipk) - 2.75) / 1.25))
    prestasi = pl.get("prestasi") or []
    skor_prestasi = min(
        1.0,
        sum(BOBOT_TINGKAT.get(str(p.get("tingkat") or ""), 0.15) for p in prestasi if isinstance(p, dict)),
    )
    return round(
        0.30 * nilai_ipk
        + 0.25 * skor_prestasi
        + 0.15 * _banyak(pl.get("organisasi"), 3)
        + 0.10 * _banyak(pl.get("sertifikat"), 3)
        + 0.10 * _banyak(pl.get("pengalaman"), 2)
        + 0.10 * (1.0 if skor_bahasa else 0.0),
        3,
    )


def estimasi_peluang(
    *,
    kategori: str | None,
    ada_syarat_terukur: bool,
    nama: str,
    penyelenggara: str | None,
    luar_negeri: bool,
    kekuatan: float,
    dasar_statistik: float | None = None,
) -> int | None:
    """Persen 2 sampai 90, atau None bila beasiswa belum punya syarat terukur (tidak ada dasar untuk menghitung)."""
    if kategori is None or not ada_syarat_terukur:
        return None
    # Rasio penerimaan yang terdokumentasi (bila ada) menggantikan perkiraan persaingan umum.
    dasar = dasar_statistik if dasar_statistik is not None else persaingan_dasar(nama, penyelenggara, luar_negeri)
    faktor_profil = 0.6 + 0.8 * max(0.0, min(1.0, kekuatan))  # 0,6 untuk profil kosong sampai 1,4 untuk profil kuat
    nilai = dasar * FAKTOR_KATEGORI.get(kategori, 0.15) * faktor_profil * 100
    return int(round(max(2.0, min(90.0, nilai))))


def alasan_peluang(kategori: str | None, dasar: float, kekuatan: float) -> list[str]:
    """Kalimat singkat yang menjelaskan dari mana angka estimasi berasal, untuk halaman Detail."""
    kalimat: list[str] = []
    kalimat.append(
        {
            "memenuhi": "Syarat yang tercatat sudah kamu penuhi.",
            "hampir_memenuhi": "Sebagian syarat belum terpenuhi, sehingga peluang diturunkan.",
            "belum_memenuhi": "Ada syarat yang belum terpenuhi, sehingga peluang diturunkan banyak.",
        }.get(kategori or "", "")
    )
    kalimat.append(
        "Persaingan program ini umumnya sangat ketat."
        if dasar <= DASAR_KETAT
        else "Persaingan program ini umumnya lebih longgar."
        if dasar >= DASAR_LONGGAR
        else "Persaingan program ini tergolong sedang."
    )
    kalimat.append(
        "Profilmu kuat (IPK, prestasi, organisasi, atau sertifikat banyak)."
        if kekuatan >= 0.65
        else "Profilmu cukup; menambah prestasi, organisasi, dan sertifikat menaikkan estimasi."
        if kekuatan >= 0.35
        else "Profilmu masih sedikit terisi; lengkapi prestasi, organisasi, dan sertifikat agar estimasi lebih tepat."
    )
    return [k for k in kalimat if k]
