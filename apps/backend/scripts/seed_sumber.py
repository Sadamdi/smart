"""Mengisi tabel sumber dengan sembilan laman awal. Aman diulang (upsert berdasarkan url, tidak menghapus apa pun).

Pemakaian (dari apps/backend, dengan DATABASE_URL di .env):
    uv run python -m scripts.seed_sumber
"""

from sqlalchemy import create_engine
from sqlalchemy.dialects.postgresql import insert

from app.core.config import get_settings
from app.models import Sumber

# Sumber yang dapat dibaca AI (halaman publik): SatuBeasiswa, Beasiswa Unggulan, Djarum, BSI. Luarkampus (login) dan LPDP
# (captcha) tidak dilewati; Komdigi dan Scholarpedia hanya rujukan.
# (nama, url, jenis, negara, jadwal cron atau None, aktif). Metode per sumber: Dokument/01-Arsitektur/04-PEMANTAUAN-SUMBER.md
SUMBER_AWAL = [
    (
        "SatuBeasiswa Kemdiktisaintek",
        "https://satubeasiswa.kemdiktisaintek.go.id/beasiswa",
        "pantau_otomatis",
        "Indonesia",
        "30 5 * * *",
        True,
    ),
    ("Luarkampus.id", "https://luarkampus.id/beasiswa", "tautan_keluar", "Indonesia", None, True),
    (
        "Beasiswa Unggulan Kemendikdasmen",
        "https://beasiswaunggulan.kemendikdasmen.go.id",
        "pantau_otomatis",
        "Indonesia",
        "30 5 * * *",
        True,
    ),
    (
        "Informasi beasiswa Kemahasiswaan UIN Malang",
        "https://kemahasiswaan.uin-malang.ac.id/informasi-beasiswa",
        "pantau_otomatis",
        "Indonesia",
        "0 6 * * *",
        True,
    ),
    ("Djarum Beasiswa Plus", "https://djarumbeasiswaplus.org/home", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    (
        "Beasiswa LPDP Terintegrasi",
        "https://beasiswalpdp-terintegrasi.kemenkeu.go.id",
        "tautan_keluar",
        "Indonesia",
        None,
        True,
    ),
    ("BSI Scholarship", "https://bsischolarship.id", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Beasiswa Komdigi", "https://beasiswa.komdigi.go.id", "rujukan", "Indonesia", None, True),
    (
        "Scholarpedia (Kobi Education)",
        "https://scholarpedia.kobieducation.com/scholarship",
        "rujukan",
        "Indonesia",
        None,
        True,
    ),
    # Tambahan 4 November 2026 (sumber tambahan hasil riset bagian 12 dan 13, dan kalender beasiswa):
    (
        "KIP Kuliah Kemdiktisaintek",
        "https://kip-kuliah.kemdiktisaintek.go.id/",
        "pantau_otomatis",
        "Indonesia",
        "30 5 * * *",
        True,
    ),
    ("Tanoto Foundation", "https://www.tanotofoundation.org/id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    (
        "Australia Awards Indonesia",
        "https://australiaawardsindonesia.org/",
        "pantau_otomatis",
        "Australia",
        "30 5 * * *",
        True,
    ),
    ("Turkiye Burslari", "https://turkiyeburslari.gov.tr/", "pantau_otomatis", "Turki", "30 5 * * *", True),
    (
        "INDBeasiswa: kalender beasiswa 2027 (agregator)",
        "https://indbeasiswa.com/daftar-beasiswa-2027/",
        "pantau_otomatis",
        "Indonesia",
        "30 5 * * *",
        True,
    ),
    (
        "INDBeasiswa: beasiswa S1 (agregator)",
        "https://indbeasiswa.com/daftar-beasiswa-s1/",
        "pantau_otomatis",
        "Indonesia",
        "30 5 * * *",
        True,
    ),
    (
        "SatuBeasiswa: peta situs (laman detail)",
        "https://satubeasiswa.kemdiktisaintek.go.id/sitemap.xml",
        "pantau_otomatis",
        "Indonesia",
        "30 5 * * *",
        True,
    ),
    # Tambahan 9 November 2026 (laman publik tanpa login yang dapat dibaca robot):
    ("LPDP Kemenkeu", "https://lpdp.kemenkeu.go.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Pertamina Foundation", "https://pertaminafoundation.org/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    (
        "Generasi Baru Indonesia (Bank Indonesia)",
        "https://www.bi.go.id/id/sdm/genbi/default.aspx",
        "pantau_otomatis",
        "Indonesia",
        "30 5 * * *",
        True,
    ),
    ("Beasiswa Kemenag", "https://beasiswa.kemenag.go.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Yayasan Tunas Muda", "https://www.ytm.or.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Beasiswa.id", "https://www.beasiswa.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Info Beasiswa", "https://www.infobeasiswa.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("INDBeasiswa beranda", "https://indbeasiswa.com/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    # Tambahan 16 November 2026 (penyelenggara resmi, robots.txt mengizinkan):
    (
        "AMINEF Fulbright untuk WNI",
        "https://www.aminef.or.id/grants-for-indonesians/fulbright-programs/",
        "pantau_otomatis",
        "Amerika Serikat",
        "30 5 * * *",
        True,
    ),
    ("Beasiswa UGM", "https://beasiswa.ugm.ac.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Bantuan Biaya Pendidikan ITB", "https://finaid.itb.ac.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Kemahasiswaan ITB", "https://kemahasiswaan.itb.ac.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Kemahasiswaan IPB", "https://kemahasiswaan.ipb.ac.id/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    ("Sampoerna Foundation", "https://www.sampoernafoundation.org/", "pantau_otomatis", "Indonesia", "30 5 * * *", True),
    # Tambahan 23 November 2026: sumber luar negeri dan daerah (semua laman publik, diuji dapat diakses):
    (
        "DAAD Jerman",
        "https://www.daad.de/en/study-and-research-in-germany/scholarships/",
        "pantau_otomatis",
        "Jerman",
        "30 5 * * *",
        True,
    ),
    ("AMINEF Fulbright Indonesia", "https://www.aminef.or.id/", "pantau_otomatis", "Amerika Serikat", "30 5 * * *", True),
    (
        "Study in Japan (MEXT dan JASSO)",
        "https://www.studyinjapan.go.jp/en/planning/scholarships/",
        "pantau_otomatis",
        "Jepang",
        "30 5 * * *",
        True,
    ),
    (
        "Erasmus+ untuk mahasiswa",
        "https://erasmus-plus.ec.europa.eu/opportunities/opportunities-for-individuals/students",
        "pantau_otomatis",
        "Uni Eropa",
        "30 5 * * *",
        True,
    ),
    ("Stipendium Hungaricum", "https://stipendiumhungaricum.hu/", "pantau_otomatis", "Hungaria", "30 5 * * *", True),
    ("Gates Cambridge", "https://gatescambridge.org/", "pantau_otomatis", "Inggris", "30 5 * * *", True),
    (
        "Commonwealth Scholarships UK",
        "https://cscuk.fcdo.gov.uk/scholarships/",
        "pantau_otomatis",
        "Inggris",
        "30 5 * * *",
        True,
    ),
    (
        "Swedish Institute Scholarships",
        "https://si.se/en/apply/scholarships/",
        "pantau_otomatis",
        "Swedia",
        "30 5 * * *",
        True,
    ),
    (
        "Beasiswa Pemprov Kalimantan Timur",
        "https://beasiswa.kaltimprov.go.id/",
        "pantau_otomatis",
        "Indonesia",
        "30 5 * * *",
        True,
    ),
]


def main() -> None:
    url = get_settings().database_url
    if not url:
        raise SystemExit("DATABASE_URL belum diisi.")
    engine = create_engine(url)
    nilai = [{"nama": n, "url": u, "jenis": j, "negara": ng, "jadwal": jd, "aktif": a} for n, u, j, ng, jd, a in SUMBER_AWAL]
    stmt = insert(Sumber).values(nilai)
    stmt = stmt.on_conflict_do_update(
        index_elements=[Sumber.url],
        set_={
            "nama": stmt.excluded.nama,
            "jenis": stmt.excluded.jenis,
            "negara": stmt.excluded.negara,
            "jadwal": stmt.excluded.jadwal,
            "aktif": stmt.excluded.aktif,
        },
    )
    with engine.begin() as koneksi:
        koneksi.execute(stmt)
    print(f"{len(nilai)} sumber diperiksa atau diisi.")


if __name__ == "__main__":
    main()
