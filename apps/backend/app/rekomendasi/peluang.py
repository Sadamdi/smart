"""Estimasi peluang diterima (persen), dihitung dari tiga hal yang bisa dijelaskan:

1. dasar persaingan: rasio penerimaan program itu bila dipublikasikan (statistik.py), bila tidak, tingkat persaingan
   program sejenis (sangat ketat, ketat, sedang, longgar) yang dikalibrasi dari data program yang terdokumentasi,
2. kecocokan syarat (kategori kelayakan: memenuhi, hampir, belum),
3. kekuatan profil (IPK, prestasi, organisasi, sertifikat, pengalaman, skor bahasa).

Ini PERKIRAAN, bukan jaminan, dan dihitung dengan algoritma sendiri tanpa AI. Rasio penerimaan adalah rata-rata semua
pelamar yang memenuhi syarat, jadi pelamar berprofil rata-rata (kekuatan 0,5) mendapat sekitar rasio itu, yang lebih
kuat mendapat lebih tinggi. Sistem tidak pernah menyatakan seseorang pasti diterima: nilai dibatasi 1 sampai 90 persen.
Beasiswa tanpa syarat terukur tidak diberi estimasi.

Kalibrasi tingkat persaingan (rasio diterima per pendaftar, dari data di data/statistik_seleksi.json):
- sangat ketat, sekitar 2 persen: Gates Cambridge 1,4, Chevening 1,5, Tanoto TELADAN 1,9 sampai 4,1, Djarum 2,8.
- ketat, sekitar 15 persen: Fulbright 8, IISMA 15 sampai 22, Bidikmisi 15, LPDP 19 sampai 29.
- sedang, sekitar 30 persen, dan longgar, sekitar 50 persen: belum ada data terdokumentasi; ini perkiraan untuk program
  dalam negeri berbasis kampus, daerah, atau bantuan biaya, dan ditandai berkeandalan rendah di Detail.
"""

BOBOT_TINGKAT = {"sekolah": 0.2, "kota": 0.35, "provinsi": 0.5, "nasional": 0.8, "internasional": 1.0}

TINGKAT = {"sangat_ketat": 0.02, "ketat": 0.15, "sedang": 0.30, "longgar": 0.50}
LABEL_TINGKAT = {
    "sangat_ketat": "sangat ketat (program sejenis menerima sekitar 2 persen pelamar)",
    "ketat": "ketat (program sejenis menerima sekitar 15 persen pelamar)",
    "sedang": "sedang (perkiraan, belum ada data seleksi program sejenis)",
    "longgar": "longgar (perkiraan, program berbasis bantuan biaya atau kuota besar)",
}

_SANGAT_KETAT = (
    "gates", "rhodes", "chevening", "tanoto", "teladan", "djarum", "schwarzman", "clarendon", "knight-hennessy",
    "marshall scholarship", "presidential",
)  # fmt: skip
_KETAT = (
    "lpdp", "iisma", "fulbright", "aminef", "daad", "mext", "monbukagakusho", "gks", "korean government",
    "global korea", "erasmus", "commonwealth", "australia awards", "turkiye", "türkiye", "turkey", "csc",
    "china government", "stipendium hungaricum", "unggulan", "full scholarship", "fully funded", "fully-funded", "penuh",
)  # fmt: skip
_LONGGAR = (
    "kip kuliah", "bidikmisi", "bantuan", "peningkatan prestasi", "ppa", "pemerintah daerah", "pemda", "kampus",
)  # fmt: skip

# Konstanta lama dipertahankan agar mudah dibandingkan di uji.
DASAR_KETAT = TINGKAT["ketat"]
DASAR_LONGGAR = TINGKAT["longgar"]

SYARAT_CUKUP = 3  # jumlah syarat tercatat (termasuk jenjang) yang dianggap cukup lengkap
FAKTOR_DATA_TIPIS = 0.8
FAKTOR_KATEGORI = {"memenuhi": 1.0, "hampir_memenuhi": 0.55, "belum_memenuhi": 0.15}


def tingkat_persaingan(nama: str, penyelenggara: str | None, luar_negeri: bool) -> str:
    """Tingkat persaingan program bila tidak ada rasio terdokumentasi. Program luar negeri tak dikenal dianggap ketat."""
    teks = f"{nama} {penyelenggara or ''}".lower()
    if any(k in teks for k in _SANGAT_KETAT):
        return "sangat_ketat"
    if any(k in teks for k in _KETAT):
        return "ketat"
    if any(k in teks for k in _LONGGAR) and not luar_negeri:
        return "longgar"
    return "ketat" if luar_negeri else "sedang"


def persaingan_dasar(nama: str, penyelenggara: str | None, luar_negeri: bool) -> float:
    """Peluang dasar seorang pelamar berprofil rata-rata yang memenuhi syarat, sebelum faktor profil."""
    return TINGKAT[tingkat_persaingan(nama, penyelenggara, luar_negeri)]


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
    jumlah_syarat: int = 3,
) -> int | None:
    """Persen 1 sampai 90, atau None bila beasiswa belum punya syarat terukur (tidak ada dasar untuk menghitung)."""
    if kategori is None or not ada_syarat_terukur:
        return None
    # Rasio penerimaan yang terdokumentasi (bila ada) menggantikan tingkat persaingan program sejenis.
    dasar = dasar_statistik if dasar_statistik is not None else persaingan_dasar(nama, penyelenggara, luar_negeri)
    faktor_profil = 0.6 + 0.8 * max(0.0, min(1.0, kekuatan))  # 0,6 untuk profil kosong sampai 1,4 untuk profil kuat
    nilai = dasar * FAKTOR_KATEGORI.get(kategori, 0.15) * faktor_profil * 100
    if jumlah_syarat < SYARAT_CUKUP:
        nilai *= FAKTOR_DATA_TIPIS  # syarat tercatat sedikit: yang belum tercatat bisa saja tidak terpenuhi
    return int(round(max(1.0, min(90.0, nilai))))


def alasan_peluang(
    kategori: str | None, tingkat: str | None, kekuatan: float, dari_statistik: bool, data_tipis: bool = False
) -> list[str]:
    """Kalimat singkat yang menjelaskan dari mana angka estimasi berasal, untuk halaman Detail."""
    kalimat = [
        {
            "memenuhi": "Syarat yang tercatat sudah kamu penuhi.",
            "hampir_memenuhi": "Sebagian syarat belum terpenuhi, sehingga peluang diturunkan.",
            "belum_memenuhi": "Ada syarat yang belum terpenuhi, sehingga peluang diturunkan banyak.",
        }.get(kategori or "", "")
    ]
    if dari_statistik:
        kalimat.append("Persaingan memakai rasio penerimaan yang dipublikasikan (lihat sumber data).")
    elif tingkat:
        kalimat.append(f"Persaingan program ini diperkirakan {LABEL_TINGKAT[tingkat]}.")
    if data_tipis:
        kalimat.append("Syarat yang tercatat masih sedikit, jadi estimasi diredam. Cek laman resmi untuk syarat lengkap.")
    kalimat.append(
        "Profilmu kuat (IPK, prestasi, organisasi, atau sertifikat banyak)."
        if kekuatan >= 0.65
        else "Profilmu cukup; menambah prestasi, organisasi, dan sertifikat menaikkan estimasi."
        if kekuatan >= 0.35
        else "Profilmu masih sedikit terisi; lengkapi prestasi, organisasi, dan sertifikat agar estimasi lebih tepat."
    )
    return [k for k in kalimat if k]
