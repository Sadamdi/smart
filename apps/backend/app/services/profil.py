from app.models import Pengguna
from app.repositories.pengguna import PenggunaRepo
from app.schemas.pengguna import PenggunaOut, PreferensiNotifikasiIn, ProfilIn


def ubah_profil(repo: PenggunaRepo, pengguna: Pengguna, data: ProfilIn) -> Pengguna:
    """Mengubah hanya kolom yang dikirim. Vektor profil dihitung ulang oleh mesin rekomendasi (F5)."""
    for kolom, nilai in data.model_dump(exclude_unset=True).items():
        setattr(pengguna, kolom, nilai)
    return repo.simpan(pengguna)


def ubah_preferensi(repo: PenggunaRepo, pengguna: Pengguna, data: PreferensiNotifikasiIn) -> Pengguna:
    pengguna.preferensi_notifikasi = {"email": data.email, "push": data.push}
    return repo.simpan(pengguna)


def ekspor(pengguna: Pengguna) -> dict:
    """Ekspor data milik pengguna (privasi). Tabel lain ditambahkan saat modulnya ada."""
    return {"profil": PenggunaOut.model_validate(pengguna).model_dump(mode="json")}
