from contextlib import asynccontextmanager
from datetime import date

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import admin, aktivitas, auth, beasiswa, chat, dokumen, health, me, referensi, rekomendasi
from app.core.config import get_settings
from app.core.errors import pasang_penangan_galat

API_PREFIX = "/api/v1"


def _tugas_validasi() -> None:
    from app.db import sesi_baru
    from app.services import pemantau_ai

    with sesi_baru() as sesi:
        if pemantau_ai.auto_validasi_aktif(sesi):
            pemantau_ai.validasi_antrean(sesi, get_settings(), date.today(), batas=5)


def _tugas_pantau() -> None:
    from app.db import sesi_baru
    from app.services import pemantau_ai

    with sesi_baru() as sesi:
        pemantau_ai.pantau_semua(sesi, get_settings(), date.today())


@asynccontextmanager
async def _siklus(_: FastAPI):
    penjadwal = None
    if get_settings().penjadwal_aktif:
        from apscheduler.schedulers.background import BackgroundScheduler

        penjadwal = BackgroundScheduler(timezone="Asia/Jakarta")
        penjadwal.add_job(_tugas_validasi, "interval", minutes=10, max_instances=1, coalesce=True)
        penjadwal.add_job(_tugas_pantau, "cron", hour=5, minute=30, max_instances=1)
        penjadwal.start()
    yield
    if penjadwal is not None:
        penjadwal.shutdown(wait=False)


def buat_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="SMART API",
        version="0.1.0",
        description=(
            "API SMART (Scholarship Monitoring and Recommendation Tool). "
            "Kontrak rancangan: Dokument/02-Backend/02-API-CONTRACT.md."
        ),
        docs_url="/docs",
        redoc_url=None,
        openapi_url=f"{API_PREFIX}/openapi.json",
        lifespan=_siklus,
    )
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    pasang_penangan_galat(app)
    app.include_router(health.router, prefix=API_PREFIX)
    app.include_router(auth.router, prefix=API_PREFIX)
    app.include_router(me.router, prefix=API_PREFIX)
    app.include_router(referensi.router, prefix=API_PREFIX)
    app.include_router(beasiswa.router, prefix=API_PREFIX)
    app.include_router(rekomendasi.router, prefix=API_PREFIX)
    app.include_router(dokumen.router, prefix=API_PREFIX)
    app.include_router(aktivitas.router, prefix=API_PREFIX)
    app.include_router(chat.router, prefix=API_PREFIX)
    app.include_router(admin.router, prefix=API_PREFIX)
    return app


app = buat_app()
