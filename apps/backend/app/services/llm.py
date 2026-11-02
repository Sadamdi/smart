"""Klien layanan AI (endpoint OpenAI-compatible). Dipakai hanya untuk membaca dokumen dan menjawab chatbot.

Tidak pernah dipakai untuk menentukan peringkat rekomendasi. Bila konfigurasi kosong atau layanan gagal, melempar
UpstreamUnavailable dengan pesan jelas agar pemanggil turun ke jalur manual.
"""

import httpx

from app.core.config import Settings
from app.core.errors import UpstreamUnavailable


def tersedia(settings: Settings) -> bool:
    return bool(settings.ai_base_url and settings.ai_api_key and settings.ai_model)


def tanya(settings: Settings, sistem: str, pesan: str, timeout: float = 30.0) -> str:
    if not tersedia(settings):
        raise UpstreamUnavailable("Layanan AI belum dikonfigurasi")
    try:
        r = httpx.post(
            settings.ai_base_url.rstrip("/") + "/chat/completions",
            headers={"Authorization": f"Bearer {settings.ai_api_key}"},
            json={
                "model": settings.ai_model,
                "messages": [{"role": "system", "content": sistem}, {"role": "user", "content": pesan}],
                "temperature": 0.2,
            },
            timeout=timeout,
        )
        r.raise_for_status()
        return r.json()["choices"][0]["message"]["content"].strip()
    except (httpx.HTTPError, KeyError, IndexError, ValueError) as exc:
        raise UpstreamUnavailable("Layanan AI sedang tidak tersedia, coba lagi nanti") from exc
