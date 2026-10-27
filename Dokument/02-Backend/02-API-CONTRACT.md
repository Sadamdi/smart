# Kontrak API SMART v1

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft (rancangan sebelum kode; OpenAPI hasil generate menjadi sumber kebenaran setelah backend ada) |
| **Author** | Tim SMART |
| **Sumber bisnis** | `01-PRD-BACKEND.md`, `03-Frontend/02-PETA-LAYAR-KE-ENDPOINT.md` |

Awalan semua jalur: `/api/v1`. Peran: P = publik, M = mahasiswa, A = admin. Konvensi respons dan galat ada di `01-PRD-BACKEND.md`.

## Auth dan akun

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| POST | /auth/register | P | Daftar (nama, email, kata sandi, kampus, jenjang) |
| POST | /auth/login | P | Masuk, mengembalikan token akses dan penyegar |
| POST | /auth/refresh | P | Tukar token penyegar |
| POST | /auth/logout | M, A | Cabut token penyegar |
| POST | /auth/ganti-kata-sandi | M, A | Ganti kata sandi |
| GET | /me | M, A | Akun dan profil |
| PUT | /me/profil | M | Ubah profil |
| PUT | /me/preferensi-notifikasi | M | Ubah preferensi email dan push |
| GET | /me/ekspor | M | Ekspor data pengguna |
| DELETE | /me | M | Hapus akun beserta datanya |
| POST | /me/perangkat | M | Daftarkan token push |

## Dokumen

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| POST | /me/dokumen | M | Unggah (multipart; jenis, berkas; maksimal 5 MB) |
| GET | /me/dokumen | M | Daftar dokumen dan status baca |
| GET | /me/dokumen/{id} | M | Detail dan hasil baca |
| PUT | /me/dokumen/{id}/hasil-baca | M | Koreksi hasil baca |
| DELETE | /me/dokumen/{id} | M | Hapus |

## Beasiswa

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| GET | /beasiswa | M, A | Daftar terbit. Filter: `q`, `jenjang`, `negara`, `pembiayaan`, `status`, `urut` (tenggat, nama); paginasi kursor |
| GET | /beasiswa/{id} | M, A | Detail beserta persyaratan, berkas wajib, tautan resmi |

Catatan nama jalur: jalur memakai bahasa Indonesia (`/beasiswa`) mengikuti nama tabel. Bila tim memilih bahasa Inggris, ubah seluruh tabel ini sekaligus dan catat di ADR.

## Rekomendasi

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| GET | /rekomendasi | M | Daftar per kategori. Query: `kategori` (memenuhi, hampir_memenuhi, belum_memenuhi), `filter`, paginasi |
| POST | /rekomendasi/hitung-ulang | M | Paksa hitung ulang (dibatasi lajunya) |

Item rekomendasi: `beasiswa` ringkas, `kategori`, `alasan[]`, `catatan_kekurangan[]`, `tenggat`. Skor numerik tidak ditampilkan sebagai persen.

## Interaksi, checklist, kalender

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| POST | /beasiswa/{id}/interaksi | M | Catat `klik`, `simpan`, atau `rencana_daftar` (dengan `status_rencana`) |
| DELETE | /beasiswa/{id}/interaksi/simpan | M | Batalkan simpan |
| GET | /me/tersimpan | M | Beasiswa tersimpan beserta status rencana |
| GET | /me/checklist | M | Checklist berkas semua beasiswa tersimpan |
| PUT | /me/checklist/{berkas_wajib_id} | M | Centang atau batalkan |
| GET | /me/kalender | M | Tenggat beasiswa tersimpan dan tugas pribadi pada rentang tanggal |
| POST | /me/tugas | M | Tambah tugas pribadi (menunggu O-03) |
| PUT | /me/tugas/{id} | M | Ubah atau selesaikan |
| DELETE | /me/tugas/{id} | M | Hapus |

## Chatbot

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| POST | /chat | M | Kirim pesan (maksimal 2000 karakter), mengembalikan jawaban dan rujukan beasiswa |
| GET | /chat/riwayat | M | Riwayat percakapan |
| DELETE | /chat/riwayat | M | Hapus riwayat |

## Notifikasi

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| GET | /notifikasi | M | Daftar notifikasi, paginasi kursor |
| PUT | /notifikasi/{id}/baca | M | Tandai dibaca |
| PUT | /notifikasi/baca-semua | M | Tandai semua dibaca |

## Admin

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| GET | /admin/antrean-validasi | A | Beasiswa `menunggu_validasi` beserta alasan ditandai |
| PUT | /admin/beasiswa/{id} | A | Perbaiki data |
| POST | /admin/beasiswa/{id}/terbitkan | A | Terbitkan |
| POST | /admin/beasiswa/{id}/tolak | A | Tolak dengan alasan |
| POST | /admin/beasiswa | A | Input manual (sumber `input_manual`) |
| GET | /admin/sumber | A | Daftar sumber dan status terakhir |
| POST | /admin/sumber | A | Tambah sumber |
| PUT | /admin/sumber/{id} | A | Ubah, aktif atau nonaktif, jadwal |
| POST | /admin/sumber/{id}/jalankan | A | Pemicu pemantauan sekarang |
| GET | /admin/laporan | A | Ringkasan sistem: jumlah beasiswa per status, hasil putaran pemantau, pengguna aktif |

## Infrastruktur

| Metode | Jalur | Peran | Fungsi |
| --- | --- | --- | --- |
| GET | /health | P | Hidup |
| GET | /health/siap | P | Siap (basis data terhubung) |

## Contoh bentuk

Masuk:

```json
POST /api/v1/auth/login
{ "email": "mahasiswa@example.com", "kata_sandi": "<kata sandi>" }

200
{ "success": true, "data": { "token_akses": "<jwt>", "token_penyegar": "<token>", "kedaluwarsa_detik": 900 } }
```

Galat validasi:

```json
422
{ "success": false, "error": { "code": "VALIDATION", "message": "ipk harus antara 0 dan 4" } }
```

Contoh memakai domain `example.com`; jangan menulis akun atau kata sandi sungguhan di dokumen.

## Swagger dan OpenAPI

Backend sudah menyajikan Swagger UI di `/docs` dan OpenAPI di `/api/v1/openapi.json` (baru berisi endpoint `/health`). Web membuat tipe dari OpenAPI dengan `npm run gen:api` (backend harus jalan di port 8000). Setiap endpoint baru wajib punya `summary`, contoh masukan, dan skema respons agar tampil lengkap di Swagger.

## Perubahan kontrak

Perubahan jalur, masukan, atau keluaran: ubah berkas ini di komit yang sama dengan kode, regenerate OpenAPI, lalu cari semua dokumen hidup yang menyebut perilaku lama (`grep` di `Dokument/` dan `apps/docs/`). Pemetaan layar ke endpoint ada di `03-Frontend/02-PETA-LAYAR-KE-ENDPOINT.md`.
