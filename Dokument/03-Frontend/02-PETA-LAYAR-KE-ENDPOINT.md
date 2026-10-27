# Peta Layar ke Endpoint

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | DP-SM-001 bagian 5 (tabel layar), `02-Backend/02-API-CONTRACT.md` |

Fase menunjukkan urutan pembangunan irisan vertikal. Layar bertanda (baru) belum ada di Figma versi 1 dan menunggu desainer.

| Layar | Web | Mobile | Endpoint | Tabel | Fase |
| --- | --- | --- | --- | --- | --- |
| Login | Ya | Ya | POST /auth/login | pengguna | F6 |
| Registrasi (baru) | Ya | Ya | POST /auth/register | pengguna | F6 |
| Jelajah Beasiswa | Ya | Ya | GET /beasiswa | beasiswa, sumber | F6 (pertama) |
| Detail Beasiswa | Ya | Tahap lanjut | GET /beasiswa/{id}, POST /beasiswa/{id}/interaksi | beasiswa, persyaratan, berkas_wajib, interaksi | F6 |
| Profil Saya | Ya | Tahap lanjut | GET /me, PUT /me/profil | pengguna | F6 |
| Dokumen Saya | Ya | Tahap lanjut | /me/dokumen, PUT /me/dokumen/{id}/hasil-baca | dokumen_pengguna | F6 |
| Rekomendasi | Ya | Ya | GET /rekomendasi, POST /rekomendasi/hitung-ulang | rekomendasi, persyaratan | F6 |
| Dashboard atau Beranda | Ya | Ya | GET /rekomendasi, GET /me/kalender, GET /me/checklist | rekomendasi, beasiswa, checklist_pengguna | F6 |
| Beasiswa Tersimpan (baru) | Ya | Tahap lanjut | GET /me/tersimpan | interaksi | F8 |
| Kalender dan Checklist | Ya | Ya | GET /me/kalender, GET /me/checklist, PUT /me/checklist/{id}, /me/tugas | beasiswa, berkas_wajib, checklist_pengguna, tugas_pribadi | F8 |
| Chatbot AI | Ya | Tahap lanjut | POST /chat, GET /chat/riwayat | percakapan, beasiswa | F7 |
| Notifikasi | Ya | Ya | GET /notifikasi, PUT /notifikasi/{id}/baca | notifikasi | F8 |
| Pengaturan dan Akun | Ya | Tahap lanjut | PUT /me/preferensi-notifikasi, POST /auth/ganti-kata-sandi, GET /me/ekspor, DELETE /me | pengguna, notifikasi | F8 |
| Admin: antrean validasi (baru) | Ya | Tidak | GET /admin/antrean-validasi, PUT /admin/beasiswa/{id}, terbitkan, tolak | beasiswa | F9 |
| Admin: kelola sumber (baru) | Ya | Tidak | /admin/sumber | sumber | F9 |
| Admin: laporan sistem (baru) | Ya | Tidak | GET /admin/laporan | beasiswa, sumber | F9 |

## Keadaan layar yang wajib ditangani

| Keadaan | Perilaku |
| --- | --- |
| Memuat | Kerangka atau indikator, bukan layar kosong |
| Kosong | Pesan yang menjelaskan langkah berikutnya (mis. lengkapi profil untuk melihat rekomendasi) |
| Galat jaringan | Pesan dan tombol coba lagi |
| Token kedaluwarsa | Segarkan otomatis sekali; bila gagal, kembali ke login |
| Layanan AI tidak tersedia | Pesan jelas; jalur manual untuk profil; chatbot menunjukkan status |
