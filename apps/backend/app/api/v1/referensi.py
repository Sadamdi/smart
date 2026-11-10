from fastapi import APIRouter

from app.rekomendasi import wilayah
from app.schemas.common import Amplop
from app.schemas.pengguna import ReferensiWilayahOut

router = APIRouter(prefix="/referensi", tags=["referensi"])


@router.get(
    "/wilayah",
    summary="Daftar negara dan provinsi Indonesia untuk pilihan domisili",
    response_model=Amplop[ReferensiWilayahOut],
)
def daftar_wilayah() -> Amplop[ReferensiWilayahOut]:
    """Tanpa autentikasi (data tetap). Kota diisi bebas oleh pengguna; provinsi hanya berlaku bila negara Indonesia."""
    return Amplop(data=ReferensiWilayahOut(**wilayah.referensi()))
