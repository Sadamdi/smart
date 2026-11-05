"""Lapis pertama mesin rekomendasi: memeriksa tiap syarat beasiswa terhadap profil.

Fungsi di sini murni (tanpa basis data) supaya mudah diuji. Teks hasil tidak pernah menyatakan pasti diterima.
Syarat yang tidak dapat dikejar (domisili, jenis kampus, jenjang, usia, kewarganegaraan, penghasilan) yang gagal
langsung membuat kategori belum memenuhi. Syarat yang dapat dikejar dinilai dengan toleransi.
"""

from dataclasses import dataclass, field
from datetime import date

from app.rekomendasi.konfigurasi import TOLERANSI, Toleransi

MEMENUHI = "memenuhi"
HAMPIR = "hampir_memenuhi"
BELUM = "belum_memenuhi"

OK = "terpenuhi"
TOLERAN = "dalam_toleransi"
GAGAL = "gagal"
TIDAK_DIKETAHUI = "tidak_diketahui"


@dataclass
class ProfilKelayakan:
    jenjang: str | None = None
    semester: int | None = None
    ipk: float | None = None
    jenis_kampus: str | None = None
    kota_domisili: str | None = None
    daerah_asal: list[str] = field(default_factory=list)  # kota dan provinsi asal (profil lanjutan)
    tanggal_lahir: date | None = None
    penghasilan_orang_tua: int | None = None
    skor_bahasa: dict | None = None
    kewarganegaraan: str | None = None
    berkas_diunggah: set[str] = field(default_factory=set)


@dataclass
class HasilSyarat:
    jenis: str
    status: str
    nilai: float  # 1 terpenuhi, 0 gagal, di antaranya untuk toleransi
    alasan: str | None = None
    kekurangan: str | None = None


def usia(tanggal_lahir: date, hari_ini: date) -> int:
    sebelum = (hari_ini.month, hari_ini.day) < (tanggal_lahir.month, tanggal_lahir.day)
    return hari_ini.year - tanggal_lahir.year - int(sebelum)


def _angka(batas: dict | None, kunci: str = "nilai") -> float | None:
    try:
        return float((batas or {})[kunci])
    except (KeyError, TypeError, ValueError):
        return None


def _daftar(batas: dict | None) -> list[str]:
    nilai = (batas or {}).get("nilai")
    if nilai is None:
        return []
    if isinstance(nilai, str):
        return [nilai]
    return [str(x) for x in nilai]


def _tidak_diketahui(jenis: str, label: str) -> HasilSyarat:
    return HasilSyarat(jenis, TIDAK_DIKETAHUI, 0.5, kekurangan=f"Lengkapi {label} di profil agar syarat ini dapat diperiksa")


def _ipk(jenis: str, batas: dict | None, profil: ProfilKelayakan, tol: Toleransi) -> HasilSyarat | None:
    minimum = _angka(batas)
    if minimum is None:
        return None
    if profil.ipk is None:
        return _tidak_diketahui(jenis, "IPK")
    if profil.ipk >= minimum:
        return HasilSyarat(jenis, OK, 1.0, f"IPK {profil.ipk:.2f} memenuhi syarat minimum {minimum:.2f}")
    selisih = round(minimum - profil.ipk, 2)
    if selisih <= tol.ipk:
        return HasilSyarat(
            jenis,
            TOLERAN,
            1 - selisih / (tol.ipk * 2),
            kekurangan=f"IPK kurang {selisih:.2f} dari syarat {minimum:.2f}",
        )
    return HasilSyarat(jenis, GAGAL, 0.0, kekurangan=f"IPK {profil.ipk:.2f} di bawah syarat {minimum:.2f}")


def _semester(jenis: str, batas: dict | None, profil: ProfilKelayakan, tol: Toleransi) -> HasilSyarat | None:
    batas_sem = _angka(batas)
    if batas_sem is None:
        return None
    if profil.semester is None:
        return _tidak_diketahui(jenis, "semester")
    if jenis == "semester_minimum":
        if profil.semester >= batas_sem:
            return HasilSyarat(jenis, OK, 1.0, f"Semester {profil.semester} memenuhi batas minimum {int(batas_sem)}")
        if int(batas_sem - profil.semester) <= tol.semester:
            return HasilSyarat(jenis, TOLERAN, 0.5, kekurangan=f"Dapat mendaftar mulai semester {int(batas_sem)}")
        return HasilSyarat(jenis, GAGAL, 0.0, kekurangan=f"Syarat semester minimum {int(batas_sem)}")
    if profil.semester <= batas_sem:
        return HasilSyarat(jenis, OK, 1.0, f"Semester {profil.semester} dalam batas maksimum {int(batas_sem)}")
    return HasilSyarat(jenis, GAGAL, 0.0, kekurangan=f"Melewati batas semester maksimum {int(batas_sem)}")


def _pilihan(
    jenis: str, batas: dict | None, nilai: str | None, label: str, teks_ok: str, huruf_kecil: bool = True
) -> HasilSyarat | None:
    diminta = _daftar(batas)
    if not diminta:
        return None
    if not nilai:
        return _tidak_diketahui(jenis, label)
    cocok = (
        any(d.lower() in nilai.lower() or nilai.lower() in d.lower() for d in diminta)
        if jenis == "domisili"
        else (nilai.lower() in [d.lower() for d in diminta] if huruf_kecil else nilai in diminta)
    )
    if cocok:
        return HasilSyarat(jenis, OK, 1.0, teks_ok.format(nilai=nilai))
    return HasilSyarat(jenis, GAGAL, 0.0, kekurangan=f"Untuk {label} {', '.join(diminta)}")


def _bahasa(jenis: str, batas: dict | None, profil: ProfilKelayakan, tol: Toleransi) -> HasilSyarat | None:
    minimum = _angka(batas)
    nama = str((batas or {}).get("jenis", "bahasa")).lower()
    if minimum is None:
        return None
    skor = (profil.skor_bahasa or {}).get(nama)
    if skor is None:
        return HasilSyarat(jenis, TOLERAN, 0.5, kekurangan=f"Perlu sertifikat {nama.upper()} dengan skor {minimum:g}")
    skor = float(skor)
    if skor >= minimum:
        return HasilSyarat(jenis, OK, 1.0, f"Skor {nama.upper()} {skor:g} memenuhi syarat {minimum:g}")
    if (minimum - skor) / minimum <= tol.skor_bahasa_persen:
        return HasilSyarat(jenis, TOLERAN, 0.6, kekurangan=f"Perlu skor {nama.upper()} {minimum:g}, skor saat ini {skor:g}")
    return HasilSyarat(jenis, GAGAL, 0.0, kekurangan=f"Skor {nama.upper()} {skor:g} jauh di bawah {minimum:g}")


def periksa_syarat(
    jenis: str, batas: dict | None, profil: ProfilKelayakan, hari_ini: date, tol: Toleransi = TOLERANSI
) -> HasilSyarat | None:
    """None untuk syarat yang hanya informasi (jenis lainnya) atau tanpa batas terukur."""
    if jenis == "ipk_minimum":
        return _ipk(jenis, batas, profil, tol)
    if jenis in ("semester_minimum", "semester_maksimum"):
        return _semester(jenis, batas, profil, tol)
    if jenis == "jenjang":
        return _pilihan(jenis, batas, profil.jenjang, "jenjang", "Jenjang {nilai} sesuai", huruf_kecil=False)
    if jenis == "jenis_kampus":
        return _pilihan(jenis, batas, profil.jenis_kampus, "kampus", "Kampus {nilai} sesuai")
    if jenis == "domisili":
        wilayah = ", ".join(x for x in [profil.kota_domisili, *profil.daerah_asal] if x) or None
        return _pilihan(jenis, batas, wilayah, "domisili", "Domisili atau daerah asal sesuai")
    if jenis == "kewarganegaraan":
        return _pilihan(jenis, batas, profil.kewarganegaraan, "warga negara", "Kewarganegaraan sesuai")
    if jenis == "usia_maksimum":
        maks = _angka(batas)
        if maks is None:
            return None
        if profil.tanggal_lahir is None:
            return _tidak_diketahui(jenis, "tanggal lahir")
        u = usia(profil.tanggal_lahir, hari_ini)
        if u <= maks:
            return HasilSyarat(jenis, OK, 1.0, f"Usia {u} tahun dalam batas {int(maks)} tahun")
        return HasilSyarat(jenis, GAGAL, 0.0, kekurangan=f"Batas usia {int(maks)} tahun")
    if jenis == "penghasilan_maksimum":
        maks = _angka(batas)
        if maks is None:
            return None
        if profil.penghasilan_orang_tua is None:
            return _tidak_diketahui(jenis, "penghasilan orang tua")
        if profil.penghasilan_orang_tua <= maks:
            return HasilSyarat(jenis, OK, 1.0, "Penghasilan orang tua dalam batas")
        return HasilSyarat(jenis, GAGAL, 0.0, kekurangan="Penghasilan orang tua melebihi batas")
    if jenis == "sertifikat_bahasa":
        return _bahasa(jenis, batas, profil, tol)
    if jenis == "berkas_pendukung":
        nama = str((batas or {}).get("nama", "")).strip()
        if not nama:
            return None
        if nama.lower() in {b.lower() for b in profil.berkas_diunggah}:
            return HasilSyarat(jenis, OK, 1.0, f"Berkas {nama} sudah tersedia")
        return HasilSyarat(jenis, TOLERAN, 0.7, kekurangan=f"Siapkan berkas {nama}")
    return None


@dataclass
class HasilKelayakan:
    kategori: str
    skor: float
    alasan: list[str]
    catatan_kekurangan: list[str]


def nilai_kelayakan(
    syarat: list[tuple[str, dict | None]], profil: ProfilKelayakan, hari_ini: date, tol: Toleransi = TOLERANSI
) -> HasilKelayakan:
    hasil = [h for j, b in syarat if (h := periksa_syarat(j, b, profil, hari_ini, tol)) is not None]
    if not hasil:
        return HasilKelayakan(MEMENUHI, 1.0, ["Belum ada syarat terukur yang tercatat; periksa tautan resmi"], [])
    alasan = [h.alasan for h in hasil if h.status == OK and h.alasan]
    kurang = [h.kekurangan for h in hasil if h.status in (TOLERAN, TIDAK_DIKETAHUI) and h.kekurangan]
    skor = sum(h.nilai for h in hasil) / len(hasil)
    gagal = [h for h in hasil if h.status == GAGAL]
    if gagal:
        return HasilKelayakan(BELUM, skor, alasan, [h.kekurangan for h in gagal if h.kekurangan] + kurang)
    if all(h.status == OK for h in hasil):
        return HasilKelayakan(MEMENUHI, skor, alasan, [])
    return HasilKelayakan(HAMPIR, skor, alasan, kurang)
