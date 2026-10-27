from fastapi import APIRouter
from sqlalchemy import create_engine, text

from app.core.config import get_settings
from app.core.errors import UpstreamUnavailable

router = APIRouter(tags=["infrastruktur"])


@router.get("/health", summary="Pemeriksaan hidup")
def hidup() -> dict:
    return {"success": True, "data": {"status": "hidup"}}


@router.get("/health/siap", summary="Pemeriksaan siap (basis data terhubung)")
def siap() -> dict:
    settings = get_settings()
    if not settings.database_url:
        raise UpstreamUnavailable("DATABASE_URL belum diisi")
    engine = create_engine(settings.database_url, connect_args={"connect_timeout": 5}, pool_pre_ping=True)
    try:
        with engine.connect() as koneksi:
            koneksi.execute(text("select 1"))
    except Exception as exc:  # noqa: BLE001 - kegagalan koneksi apa pun berarti belum siap
        raise UpstreamUnavailable("Basis data belum dapat dihubungi") from exc
    finally:
        engine.dispose()
    return {"success": True, "data": {"status": "siap"}}
