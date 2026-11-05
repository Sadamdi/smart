"""Menambahkan beasiswa dari daftar kurasi tim (nama dan tautan resmi penyelenggara) sebagai beasiswa menunggu validasi.

Tenggat dan syarat tidak diisi di sini: validasi AI membacanya dari laman resmi dan hanya menerbitkan bila tenggat tertulis jelas.
Aman diulang. Pemakaian (dari apps/backend): uv run python -m scripts.impor_kurasi
"""

from datetime import UTC, date, datetime, timedelta

from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Beasiswa, Persyaratan, Sumber
from app.services import laman
from app.services.admin import HARI_MINIMAL_TERBIT
from app.services.pemantau_ai import _sidik, tenggat_terverifikasi

URL_SUMBER = "kurasi://tim-smart"
# (nama, penyelenggara, negara, jenjang, tautan resmi)
# Entri dengan tenggat dan kutipan: tenggat dipakai hanya bila kutipan benar-benar ada di laman resmi saat ini.
KURASI = [
    (
        "Chinese Government Scholarship (CSC) 2027/2028",
        "Pemerintah Tiongkok (Kedutaan Besar RRT di Indonesia)",
        "Tiongkok",
        ["S1", "S2", "S3"],
        "https://id.china-embassy.gov.cn/eng/sgdt/202610/t20261027_12047753.htm",
        "2027-02-14",
        "before February 14, 2027",
    ),
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
        for entri in KURASI:
            nama, penyelenggara, negara, jenjang, tautan = entri[:5]
            tenggat, kutipan = (entri[5], entri[6]) if len(entri) == 7 else (None, None)
            sidik = _sidik(nama, tautan)
            if sesi.scalar(select(Beasiswa.id).where(Beasiswa.sumber_id == s.id, Beasiswa.sidik_isi == sidik)):
                continue
            status, alasan, tgl = "menunggu_validasi", "Kurasi tim, menunggu validasi", None
            if tenggat:
                try:
                    tgl = tenggat_terverifikasi(tenggat, kutipan, laman.ambil_teks(tautan, maks=60000))
                except laman.LamanGagal:
                    tgl = None
                if tgl and tgl >= date.today() + timedelta(days=HARI_MINIMAL_TERBIT):
                    status, alasan = "terbit", None
            b = Beasiswa(
                sumber_id=s.id,
                nama=nama,
                penyelenggara=penyelenggara,
                negara=negara,
                jenjang=jenjang,
                tautan_resmi=tautan,
                tenggat=tgl,
                status=status,
                alasan_ditandai=alasan,
                sidik_isi=sidik,
                tanggal_diperiksa=datetime.now(UTC),
            )
            sesi.add(b)
            sesi.flush()
            if jenjang:
                sesi.add(Persyaratan(beasiswa_id=b.id, jenis="jenjang", nilai_batas={"nilai": jenjang}, dapat_dikejar=False))
            baru += 1
        sesi.commit()
    print(f"{baru} beasiswa kurasi baru.")


if __name__ == "__main__":
    main()
