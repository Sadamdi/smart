import logging
import uuid
from collections.abc import Iterator
from datetime import date
from typing import Annotated, Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.api.deps import get_beasiswa_repo, pengguna_saat_ini
from app.db import get_session
from app.models import Pengguna
from app.rekomendasi.kelayakan import ProfilKelayakan
from app.repositories.beasiswa import BeasiswaRepo, FilterBeasiswa
from app.schemas.beasiswa import BeasiswaDetail, BeasiswaKartu, BeasiswaRingkas, BerkasWajibOut, PersyaratanOut
from app.schemas.common import Amplop, Meta
from app.services import beasiswa as layanan
from app.services import rekomendasi as layanan_rek
from app.services.kartu import luar_negeri, peluang_untuk, sesuai_wilayah
from app.services.rekomendasi import profil_dari

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/beasiswa", tags=["beasiswa"])

RepoDep = Annotated[BeasiswaRepo, Depends(get_beasiswa_repo)]


def sesi_opsional() -> Iterator[Session | None]:
    """Sesi basis data untuk skor kartu. Skor hanya pelengkap: tanpa sesi, daftar tetap tampil tanpa skor."""
    try:
        gen = get_session()
        sesi = next(gen)
    except Exception:  # noqa: BLE001 - pengaturan basis data tidak ada atau tidak terjangkau
        logger.warning("Sesi basis data untuk skor kartu tidak tersedia", exc_info=True)
        yield None
        return
    try:
        yield sesi
    finally:
        gen.close()


SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]


def profil_kelayakan(sesi: Annotated[Session, Depends(get_session)], pengguna: SaatIni) -> ProfilKelayakan:
    return profil_dari(sesi, pengguna)


ProfilDep = Annotated[ProfilKelayakan, Depends(profil_kelayakan)]


@router.get(
    "",
    summary="Daftar beasiswa terbit yang tenggatnya belum lewat",
    response_model=Amplop[list[BeasiswaKartu]],
)
def daftar(
    sesi: Annotated[Session | None, Depends(sesi_opsional)],
    pengguna: SaatIni,
    repo: RepoDep,
    q: Annotated[str | None, Query(max_length=100, description="Cari pada nama atau penyelenggara")] = None,
    jenjang: Annotated[str | None, Query(pattern="^(D3|D4|S1|S2|S3)$")] = None,
    negara: Annotated[str | None, Query(max_length=80)] = None,
    wilayah: Annotated[Literal["dalam", "luar"] | None, Query(description="dalam atau luar negeri")] = None,
    kursor: Annotated[str | None, Query(max_length=200)] = None,
    batas: Annotated[int, Query(ge=1, le=50)] = 20,
) -> Amplop[list[BeasiswaRingkas]]:
    halaman = layanan.daftar(repo, FilterBeasiswa(q=q, jenjang=jenjang, negara=negara), kursor, batas, date.today())
    item = [b for b in halaman.item if sesuai_wilayah(b.negara, wilayah)]
    nilai: dict = {}
    try:
        if sesi is not None:
            nilai = layanan_rek.peta(sesi, pengguna, [b.id for b in item], date.today())
            sesi.commit()
    except SQLAlchemyError:
        # Skor kartu hanya pelengkap: kegagalan menghitungnya tidak boleh menggagalkan daftar beasiswa.
        logger.warning("Skor kelayakan kartu tidak dapat dihitung", exc_info=True)
        sesi.rollback()
    data = []
    for b in item:
        r = nilai.get(b.id)
        ekstra: dict = {}
        if r is not None:
            ekstra = {
                "kategori": r.kategori,
                **peluang_untuk(pengguna, b, r.kategori, r.skor_kelayakan, r.alasan, r.catatan_kekurangan),
            }
            for k in ("_alasan_peluang", "_statistik", "_dasar_peluang", "_tingkat"):
                ekstra.pop(k, None)
        else:
            ekstra = {"luar_negeri": luar_negeri(b.negara)}
        data.append(BeasiswaKartu(**BeasiswaRingkas.model_validate(b).model_dump(), **ekstra))
    return Amplop(data=data, meta=Meta(kursor_berikut=halaman.kursor_berikut))


@router.get("/sinkron", summary="Paket data beasiswa untuk mode luring")
def sinkron(sesi: Annotated[Session, Depends(get_session)], _: SaatIni) -> Amplop[list[dict]]:
    return Amplop(data=layanan_rek.sinkron(sesi, date.today()))


@router.get(
    "/{beasiswa_id}",
    summary="Detail beasiswa beserta persyaratan dan berkas wajib",
    response_model=Amplop[BeasiswaDetail],
)
def detail(beasiswa_id: uuid.UUID, pengguna: SaatIni, repo: RepoDep, profil: ProfilDep) -> Amplop[BeasiswaDetail]:
    hasil = layanan.detail(repo, beasiswa_id, date.today())
    ringkas = BeasiswaRingkas.model_validate(hasil.beasiswa).model_dump()
    nilai = layanan.nilai_untuk(hasil.persyaratan, profil, date.today(), hasil.beasiswa.jenjang)
    ekstra_detail = peluang_untuk(
        pengguna,
        hasil.beasiswa,
        nilai.kelayakan.kategori,
        nilai.kelayakan.skor,
        nilai.kelayakan.alasan,
        nilai.kelayakan.catatan_kekurangan,
    )
    alasan_p = ekstra_detail.pop("_alasan_peluang", [])
    statistik_d = ekstra_detail.pop("_statistik", [])
    dasar_d = ekstra_detail.pop("_dasar_peluang", None)
    tingkat_d = ekstra_detail.pop("_tingkat", None)
    return Amplop(
        data=BeasiswaDetail(
            **ringkas,
            manfaat=hasil.beasiswa.manfaat,
            tanggal_diperiksa=hasil.beasiswa.tanggal_diperiksa,
            persyaratan=[
                PersyaratanOut(
                    jenis=s.jenis,
                    nilai_batas=s.nilai_batas,
                    dapat_dikejar=s.dapat_dikejar,
                    status=nilai.status_syarat.get(i),
                    catatan=nilai.catatan_syarat.get(i),
                )
                for i, s in enumerate(hasil.persyaratan)
            ],
            berkas_wajib=[BerkasWajibOut.model_validate(b) for b in hasil.berkas_wajib],
            kategori=nilai.kelayakan.kategori,
            **ekstra_detail,
            alasan_peluang=alasan_p,
            dasar_peluang=dasar_d,
            statistik_seleksi=statistik_d,
            tingkat_persaingan=tingkat_d,
            alasan=nilai.kelayakan.alasan,
            catatan_kekurangan=nilai.kelayakan.catatan_kekurangan,
        )
    )
