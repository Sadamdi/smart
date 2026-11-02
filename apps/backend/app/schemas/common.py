from pydantic import BaseModel


class Meta(BaseModel):
    kursor_berikut: str | None = None


class Amplop[T](BaseModel):
    """Respons sukses baku: { success: true, data, meta? }. Galat: bentuk di app/core/errors.py."""

    success: bool = True
    data: T
    meta: Meta | None = None


class Kosong(BaseModel):
    pesan: str = "ok"
