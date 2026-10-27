from fastapi.testclient import TestClient

from app.core.config import Settings
from app.main import app

client = TestClient(app)


def test_hidup():
    r = client.get("/api/v1/health")
    assert r.status_code == 200
    assert r.json() == {"success": True, "data": {"status": "hidup"}}


def test_siap_tanpa_database_url_mengembalikan_503(monkeypatch):
    monkeypatch.setattr("app.api.v1.health.get_settings", lambda: Settings(_env_file=None))
    r = client.get("/api/v1/health/siap")
    assert r.status_code == 503
    assert r.json()["error"]["code"] == "UPSTREAM_UNAVAILABLE"


def test_rute_tidak_ada_memakai_format_galat_baku():
    r = client.get("/api/v1/tidak-ada")
    assert r.status_code == 404
    body = r.json()
    assert body["success"] is False
    assert body["error"]["code"] == "NOT_FOUND"


def test_openapi_tersedia():
    r = client.get("/api/v1/openapi.json")
    assert r.status_code == 200
    assert "/api/v1/health" in r.json()["paths"]
