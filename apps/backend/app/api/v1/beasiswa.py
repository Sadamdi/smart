import uuid
from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.api.deps import get_beasiswa_repo, pengguna_saat_ini
from app.models import Pengguna
from app.repositories.beasiswa import BeasiswaRepo, FilterBeasiswa
from app.schemas.beasiswa import BeasiswaDetail, BeasiswaRingkas, BerkasWajibOut, PersyaratanOut
from app.schemas.common import Amplop, Meta
from app.services import beasiswa as layanan

router = APIRouter(prefix="/beasiswa", tags=["beasiswa"])

RepoDep = Annotated[BeasiswaRepo, Depends(get_beasiswa_repo)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]


@router.get(
    "",
    summary="Daftar beasiswa terbit yang tenggatnya belum lewat",
    response_model=Amplop[list[BeasiswaRingkas]],
)
def daftar(
    _: SaatIni,
    repo: RepoDep,
    q: Annotated[str | None, Query(max_length=100, description="Cari pada nama atau penyelenggara")] = None,
    jenjang: Annotated[str | None, Query(pattern="^(D3|D4|S1|S2|S3)$")] = None,
    negara: Annotated[str | None, Query(max_length=80)] = None,
    kursor: Annotated[str | None, Query(max_length=200)] = None,
    batas: Annotated[int, Query(ge=1, le=50)] = 20,
) -> Amplop[list[BeasiswaRingkas]]:
    halaman = layanan.daftar(
        repo, FilterBeasiswa(q=q, jenjang=jenjang, negara=negara), kursor, batas, date.today()
    )
    return Amplop(
        data=[BeasiswaRingkas.model_validate(b) for b in halaman.item],
        meta=Meta(kursor_berikut=halaman.kursor_berikut),
    )


@router.get(
    "/{beasiswa_id}",
    summary="Detail beasiswa beserta persyaratan dan berkas wajib",
    response_model=Amplop[BeasiswaDetail],
)
def detail(beasiswa_id: uuid.UUID, _: SaatIni, repo: RepoDep) -> Amplop[BeasiswaDetail]:
    hasil = layanan.detail(repo, beasiswa_id, date.today())
    ringkas = BeasiswaRingkas.model_validate(hasil.beasiswa).model_dump()
    return Amplop(
        data=BeasiswaDetail(
            **ringkas,
            manfaat=hasil.beasiswa.manfaat,
            tanggal_diperiksa=hasil.beasiswa.tanggal_diperiksa,
            persyaratan=[PersyaratanOut.model_validate(s) for s in hasil.persyaratan],
            berkas_wajib=[BerkasWajibOut.model_validate(b) for b in hasil.berkas_wajib],
        )
    )
