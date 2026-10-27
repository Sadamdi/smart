"""Galat domain dan pemetaannya ke respons HTTP baku: {success: false, error: {code, message}}."""

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException


class DomainError(Exception):
    status_code = 500
    code = "INTERNAL"

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class Unauthorized(DomainError):
    status_code = 401
    code = "UNAUTHORIZED"


class Forbidden(DomainError):
    status_code = 403
    code = "FORBIDDEN"


class NotFound(DomainError):
    status_code = 404
    code = "NOT_FOUND"


class Conflict(DomainError):
    status_code = 409
    code = "CONFLICT"


class ValidationFailed(DomainError):
    status_code = 422
    code = "VALIDATION"


class RateLimited(DomainError):
    status_code = 429
    code = "RATE_LIMITED"


class UpstreamUnavailable(DomainError):
    status_code = 503
    code = "UPSTREAM_UNAVAILABLE"


def _body(code: str, message: str) -> dict:
    return {"success": False, "error": {"code": code, "message": message}}


def pasang_penangan_galat(app: FastAPI) -> None:
    @app.exception_handler(DomainError)
    async def _domain(_: Request, exc: DomainError) -> JSONResponse:
        return JSONResponse(status_code=exc.status_code, content=_body(exc.code, exc.message))

    @app.exception_handler(RequestValidationError)
    async def _validasi(_: Request, exc: RequestValidationError) -> JSONResponse:
        bagian = [f"{'.'.join(str(x) for x in e['loc'][1:])}: {e['msg']}" for e in exc.errors()]
        return JSONResponse(
            status_code=422, content=_body("VALIDATION", "; ".join(bagian) or "masukan tidak valid")
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        kode = {
            401: "UNAUTHORIZED",
            403: "FORBIDDEN",
            404: "NOT_FOUND",
            409: "CONFLICT",
            429: "RATE_LIMITED",
        }.get(exc.status_code, "INTERNAL")
        return JSONResponse(status_code=exc.status_code, content=_body(kode, str(exc.detail)))
