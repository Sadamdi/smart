"""Ringkasan kelayakan untuk kartu beasiswa: skor kelayakan (persen) dan jumlah syarat terpenuhi.

Skor kelayakan adalah ukuran seberapa banyak syarat terukur yang sudah dipenuhi profil, bukan peluang diterima.
Beasiswa tanpa syarat terukur (tidak ada syarat tercatat, atau hanya jenjang) tidak diberi angka agar tidak menyesatkan.
"""

_CATATAN_BUKAN_SYARAT = ("Syarat belum tercatat", "Hanya jenjang yang tercatat")


def luar_negeri(negara: str | None) -> bool:
    """Beasiswa luar negeri bila negaranya tercatat dan bukan Indonesia. Tanpa negara dianggap dalam negeri."""
    n = (negara or "").strip().lower()
    return bool(n) and "indonesia" not in n


def sesuai_wilayah(negara: str | None, wilayah: str | None) -> bool:
    if wilayah == "luar":
        return luar_negeri(negara)
    if wilayah == "dalam":
        return not luar_negeri(negara)
    return True


def metrik(skor_kelayakan, alasan: list[str] | None, catatan: list[str] | None) -> dict:
    """Mengembalikan skor_kelayakan (0 sampai 100 atau None), syarat_terpenuhi, dan syarat_total."""
    alasan = alasan or []
    catatan = catatan or []
    if any(c.startswith(_CATATAN_BUKAN_SYARAT) for c in catatan):
        return {"skor_kelayakan": None, "syarat_terpenuhi": 0, "syarat_total": 0}
    kurang = [c for c in catatan if c]
    total = len(alasan) + len(kurang)
    if total == 0 or skor_kelayakan is None:
        return {"skor_kelayakan": None, "syarat_terpenuhi": 0, "syarat_total": 0}
    return {
        "skor_kelayakan": max(0, min(100, round(float(skor_kelayakan) * 100))),
        "syarat_terpenuhi": len(alasan),
        "syarat_total": total,
    }


def peluang_untuk(pengguna, beasiswa, kategori: str | None, skor_kelayakan, alasan, catatan) -> dict:
    """Estimasi peluang untuk satu beasiswa dan pengguna. Kosong (None) bila belum ada syarat terukur."""
    from app.rekomendasi.peluang import alasan_peluang, estimasi_peluang, kekuatan_profil, persaingan_dasar

    m = metrik(skor_kelayakan, alasan, catatan)
    luar = luar_negeri(beasiswa.negara)
    kuat = kekuatan_profil(
        float(pengguna.ipk) if pengguna.ipk is not None else None,
        pengguna.profil_lanjutan,
        pengguna.skor_bahasa,
    )
    nilai = estimasi_peluang(
        kategori=kategori,
        ada_syarat_terukur=m["syarat_total"] > 0,
        nama=beasiswa.nama,
        penyelenggara=beasiswa.penyelenggara,
        luar_negeri=luar,
        kekuatan=kuat,
    )
    hasil = {**m, "luar_negeri": luar, "estimasi_peluang": nilai}
    if nilai is not None:
        hasil["_alasan_peluang"] = alasan_peluang(
            kategori, persaingan_dasar(beasiswa.nama, beasiswa.penyelenggara, luar), kuat
        )
    return hasil
