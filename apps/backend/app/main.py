from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import admin, aktivitas, auth, beasiswa, chat, dokumen, health, me, rekomendasi
from app.core.config import get_settings
from app.core.errors import pasang_penangan_galat

API_PREFIX = "/api/v1"


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
    app.include_router(beasiswa.router, prefix=API_PREFIX)
    app.include_router(rekomendasi.router, prefix=API_PREFIX)
    app.include_router(dokumen.router, prefix=API_PREFIX)
    app.include_router(aktivitas.router, prefix=API_PREFIX)
    app.include_router(chat.router, prefix=API_PREFIX)
    app.include_router(admin.router, prefix=API_PREFIX)
    return app


app = buat_app()
