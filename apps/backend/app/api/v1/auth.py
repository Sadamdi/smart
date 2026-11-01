from typing import Annotated

from fastapi import APIRouter, Depends

from app.api.deps import get_pengguna_repo, pengguna_saat_ini
from app.core.config import Settings, get_settings
from app.core.ratelimit import pembatas_login
from app.models import Pengguna
from app.repositories.pengguna import PenggunaRepo
from app.schemas.common import Amplop, Kosong
from app.schemas.pengguna import DaftarIn, GantiSandiIn, MasukIn, PenggunaOut, SegarkanIn, TokenOut
from app.services import auth as layanan

router = APIRouter(prefix="/auth", tags=["autentikasi"])

RepoDep = Annotated[PenggunaRepo, Depends(get_pengguna_repo)]
SettingsDep = Annotated[Settings, Depends(get_settings)]
SaatIni = Annotated[Pengguna, Depends(pengguna_saat_ini)]


class HasilDaftar(TokenOut):
    pengguna: PenggunaOut


@router.post(
    "/register", status_code=201, summary="Daftar akun mahasiswa", response_model=Amplop[HasilDaftar]
)
def daftar(data: DaftarIn, repo: RepoDep, settings: SettingsDep) -> Amplop[HasilDaftar]:
    pengguna, token = layanan.daftar(repo, data, settings)
    return Amplop(data=HasilDaftar(**token.model_dump(), pengguna=PenggunaOut.model_validate(pengguna)))


@router.post("/login", summary="Masuk dan menerima token", response_model=Amplop[TokenOut])
def masuk(data: MasukIn, repo: RepoDep, settings: SettingsDep) -> Amplop[TokenOut]:
    return Amplop(data=layanan.masuk(repo, data, settings, pembatas_login))


@router.post("/refresh", summary="Tukar token penyegar dengan token baru", response_model=Amplop[TokenOut])
def segarkan(data: SegarkanIn, repo: RepoDep, settings: SettingsDep) -> Amplop[TokenOut]:
    return Amplop(data=layanan.segarkan(repo, data.token_penyegar, settings))


@router.post("/logout", summary="Keluar: semua token pengguna ini dicabut", response_model=Amplop[Kosong])
def keluar(pengguna: SaatIni, repo: RepoDep) -> Amplop[Kosong]:
    layanan.keluar(repo, pengguna)
    return Amplop(data=Kosong())


@router.post(
    "/ganti-kata-sandi",
    summary="Ganti kata sandi; token lama dicabut dan token baru dikembalikan",
    response_model=Amplop[TokenOut],
)
def ganti_kata_sandi(
    data: GantiSandiIn, pengguna: SaatIni, repo: RepoDep, settings: SettingsDep
) -> Amplop[TokenOut]:
    return Amplop(data=layanan.ganti_kata_sandi(repo, pengguna, data, settings))
