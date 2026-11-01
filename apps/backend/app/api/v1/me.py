from typing import Annotated

from fastapi import APIRouter, Depends

from app.api.deps import get_pengguna_repo, pengguna_saat_ini
from app.models import Pengguna
from app.repositories.pengguna import PenggunaRepo
from app.schemas.common import Amplop, Kosong
from app.schemas.pengguna import PenggunaOut, PreferensiNotifikasiIn, ProfilIn
from app.services import auth as layanan_auth
from app.services import profil as layanan

router = APIRouter(prefix="/me", tags=["akun dan profil"])

RepoDep = Annotated[PenggunaRepo, Depends(get_pengguna_repo)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]


@router.get("", summary="Akun dan profil pengguna yang masuk", response_model=Amplop[PenggunaOut])
def akun(pengguna: SaatIni) -> Amplop[PenggunaOut]:
    return Amplop(data=PenggunaOut.model_validate(pengguna))


@router.put("/profil", summary="Ubah profil (hanya kolom yang dikirim)", response_model=Amplop[PenggunaOut])
def ubah_profil(data: ProfilIn, pengguna: SaatIni, repo: RepoDep) -> Amplop[PenggunaOut]:
    return Amplop(data=PenggunaOut.model_validate(layanan.ubah_profil(repo, pengguna, data)))


@router.put(
    "/preferensi-notifikasi", summary="Ubah preferensi surel dan push", response_model=Amplop[PenggunaOut]
)
def ubah_preferensi(data: PreferensiNotifikasiIn, pengguna: SaatIni, repo: RepoDep) -> Amplop[PenggunaOut]:
    return Amplop(data=PenggunaOut.model_validate(layanan.ubah_preferensi(repo, pengguna, data)))


@router.get("/ekspor", summary="Ekspor data milik pengguna", response_model=Amplop[dict])
def ekspor(pengguna: SaatIni) -> Amplop[dict]:
    return Amplop(data=layanan.ekspor(pengguna))


@router.delete("", summary="Hapus akun beserta datanya", response_model=Amplop[Kosong])
def hapus(pengguna: SaatIni, repo: RepoDep) -> Amplop[Kosong]:
    layanan_auth.hapus_akun(repo, pengguna)
    return Amplop(data=Kosong())
