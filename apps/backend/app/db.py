from collections.abc import Iterator
from functools import lru_cache

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings
from app.core.errors import UpstreamUnavailable


@lru_cache
def _pabrik_sesi() -> sessionmaker[Session]:
    url = get_settings().database_url
    if not url:
        raise UpstreamUnavailable("DATABASE_URL belum diisi")
    mesin = create_engine(url, pool_pre_ping=True, pool_size=3, max_overflow=2, pool_recycle=300)
    return sessionmaker(mesin, expire_on_commit=False)


def get_session() -> Iterator[Session]:
    with _pabrik_sesi()() as sesi:
        yield sesi
