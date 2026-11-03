"""Menambahkan beasiswa dari daftar kurasi tim (nama dan tautan resmi penyelenggara) sebagai beasiswa menunggu validasi.

Tenggat dan syarat tidak diisi di sini: validasi AI membacanya dari laman resmi dan hanya menerbitkan bila tenggat tertulis jelas.
Aman diulang. Pemakaian (dari apps/backend): uv run python -m scripts.impor_kurasi
"""

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Beasiswa, Sumber
from app.services.pemantau_ai import _sidik

URL_SUMBER = "kurasi://tim-smart"
# (nama, penyelenggara, negara, jenjang, tautan resmi)
KURASI = [
    (
        "ASEAN Undergraduate Scholarship NUS",
        "National University of Singapore",
        "Singapura",
        ["S1"],
        "https://www.nus.edu.sg/oam/scholarships/scholarships-for-freshmen-(international-students)/asean-undergraduate-scholarship",
    ),
    (
        "NUS Scholarships Important Dates",
        "National University of Singapore",
        "Singapura",
        ["S1"],
        "https://nus.edu.sg/oam/scholarships/important-dates-and-application",
    ),
    (
        "KAIST International Undergraduate Admission",
        "KAIST",
        "Korea Selatan",
        ["S1"],
        "https://admission.kaist.ac.kr/intl-undergraduate/",
    ),
    ("Schulich Leader Scholarships", "Schulich Foundation", "Kanada", ["S1"], "https://www.schulichleaders.com/"),
    (
        "Beasiswa Bakti BCA",
        "Bank Central Asia",
        "Indonesia",
        ["S1"],
        "https://www.bca.co.id/id/tentang-bca/bakti-bca/beasiswa-bakti-bca",
    ),
    ("Stipendium Hungaricum", "Pemerintah Hungaria", "Hungaria", ["S1", "S2", "S3"], "https://stipendiumhungaricum.hu/"),
    ("Chevening Scholarships", "Pemerintah Inggris", "Inggris", ["S2"], "https://www.chevening.org/scholarships/"),
    (
        "Beasiswa Unggulan Kemendikdasmen",
        "Kemendikdasmen",
        "Indonesia",
        ["S1", "S2", "S3"],
        "https://beasiswaunggulan.kemendikdasmen.go.id/",
    ),
    ("KIP Kuliah", "Kemdiktisaintek", "Indonesia", ["D3", "D4", "S1"], "https://kip-kuliah.kemdiktisaintek.go.id/"),
]


def main() -> None:
    url = get_settings().database_url
    if not url:
        raise SystemExit("DATABASE_URL belum diisi")
    baru = 0
    with Session(create_engine(url)) as sesi:
        s = sesi.scalar(select(Sumber).where(Sumber.url == URL_SUMBER))
        if s is None:
            s = Sumber(nama="Daftar kurasi tim SMART (tautan resmi)", url=URL_SUMBER, jenis="tautan_keluar", aktif=True)
            sesi.add(s)
            sesi.flush()
        for nama, penyelenggara, negara, jenjang, tautan in KURASI:
            sidik = _sidik(nama, tautan)
            if sesi.scalar(select(Beasiswa.id).where(Beasiswa.sumber_id == s.id, Beasiswa.sidik_isi == sidik)):
                continue
            sesi.add(
                Beasiswa(
                    sumber_id=s.id,
                    nama=nama,
                    penyelenggara=penyelenggara,
                    negara=negara,
                    jenjang=jenjang,
                    tautan_resmi=tautan,
                    status="menunggu_validasi",
                    alasan_ditandai="Kurasi tim, menunggu validasi",
                    sidik_isi=sidik,
                )
            )
            baru += 1
        sesi.commit()
    print(f"{baru} beasiswa kurasi baru.")


if __name__ == "__main__":
    main()
