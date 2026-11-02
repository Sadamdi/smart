# F2: autentikasi, profil, dan daftar beasiswa

| Atribut | Nilai |
| --- | --- |
| **Versi** | v0.3.0 |
| **Tanggal** | 2026-11-02 |
| **Status** | In Progress |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F2, WBS 4.2, FR-SM-03, FR-SM-05 |
| **Tipe** | Feature |
| **Module** | backend |
| **Branch** | `adam/auth-profil-beasiswa` |

## 1. Tujuan

Menyediakan akun mahasiswa dan daftar beasiswa yang dapat dipanggil web.

## 2. Ringkasan

- Yang berubah: register, login, refresh, logout, ganti kata sandi; profil, preferensi, ekspor, hapus akun; daftar (kursor) dan detail beasiswa; batas laju login per email; pencabutan token lewat `versi_token` (migrasi 0002).
- Dampak: 12 endpoint baru di `/api/v1`.
- Perubahan yang merusak: tidak.

## 3. Rencana

- [x] Lapisan rute, servis, repositori
- [x] 41 uji lulus, termasuk uji integrasi pada Supabase dengan rollback
- [ ] OpenAPI dibandingkan dengan kontrak API
