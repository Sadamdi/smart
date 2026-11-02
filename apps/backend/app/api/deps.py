from typing import Annotated

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.errors import Forbidden, Unauthorized
from app.core.security import AKSES
from app.db import get_session
from app.models import Pengguna
from app.repositories.beasiswa import BeasiswaRepo, BeasiswaRepoSql
from app.repositories.pengguna import PenggunaRepo, PenggunaRepoSql
from app.services.auth import pengguna_dari_token

_skema = HTTPBearer(auto_error=False, description="Token akses dari /auth/masuk")


def get_pengguna_repo(sesi: Annotated[Session, Depends(get_session)]) -> PenggunaRepo:
    return PenggunaRepoSql(sesi)


def get_beasiswa_repo(sesi: Annotated[Session, Depends(get_session)]) -> BeasiswaRepo:
    return BeasiswaRepoSql(sesi)


def pengguna_saat_ini(
    kredensial: Annotated[HTTPAuthorizationCredentials | None, Depends(_skema)],
    repo: Annotated[PenggunaRepo, Depends(get_pengguna_repo)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> Pengguna:
    if kredensial is None:
        raise Unauthorized("Token akses diperlukan")
    return pengguna_dari_token(repo, kredensial.credentials, AKSES, settings)


def wajib_admin(pengguna: Annotated[Pengguna, Depends(pengguna_saat_ini)]) -> Pengguna:
    if pengguna.peran != "admin":
        raise Forbidden("Hanya admin yang boleh mengakses")
    return pengguna
