# PRD Backend SMART

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | BP-SM-001, `04-KEBUTUHAN-FR-NFR.md` |

## Tujuan

Menyediakan API tunggal untuk web dan mobile: autentikasi, profil, dokumen, beasiswa, rekomendasi, interaksi, checklist, chatbot, notifikasi, dan administrasi.

## Modul

| Modul | Tanggung jawab | Tabel | FR | Fase |
| --- | --- | --- | --- | --- |
| auth | Registrasi, login, penyegaran token, keluar, hapus akun, ekspor data | pengguna | FR-SM-05 | F2 |
| profil | Baca dan ubah profil, preferensi notifikasi | pengguna | FR-SM-05 | F2, F4 |
| dokumen | Unggah, daftar, koreksi hasil baca, hapus; memanggil layanan AI untuk membaca | dokumen_pengguna | FR-SM-05, 06 | F4 |
| beasiswa | Daftar dengan filter dan detail | beasiswa, persyaratan, berkas_wajib, sumber | FR-SM-10 | F2 |
| rekomendasi | Ambil rekomendasi per kategori, hitung ulang | rekomendasi | FR-SM-07 sampai 09 | F5 |
| interaksi | Simpan, rencana daftar, klik; daftar tersimpan | interaksi | FR-SM-12 | F8 |
| checklist | Centang berkas, tugas pribadi, data kalender | checklist_pengguna, tugas_pribadi | FR-SM-12 | F8 |
| chat | Tanya jawab berbasis data, riwayat | percakapan | FR-SM-11 | F7 |
| notifikasi | Daftar, tandai dibaca, preferensi, token push, pengirim terjadwal | notifikasi, perangkat_push | FR-SM-13 | F8 |
| admin | Antrean validasi, perbaiki atau terbitkan atau tolak, kelola sumber, laporan | beasiswa, sumber | FR-SM-04, 14 | F9 |
| health | Pemeriksaan hidup dan siap | (tanpa) | (infrastruktur) | F1 |

## Konvensi API

- Awalan `/api/v1`. Bentuk respons: `{ "success": true, "data": ..., "meta": ... }` atau `{ "success": false, "error": { "code": "...", "message": "..." } }`.
- Kode galat: `VALIDATION`, `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND`, `CONFLICT`, `RATE_LIMITED`, `UPSTREAM_UNAVAILABLE`, `INTERNAL`.
- Daftar memakai paginasi kursor: `?cursor=...&limit=...`, respons membawa `meta.nextCursor`.
- Waktu dalam ISO 8601 UTC; tampilan di klien memakai WIB.
- Autentikasi: header `Authorization: Bearer <token akses>`. Rute admin memeriksa `peran = admin`.
- Setiap masukan divalidasi dengan skema Pydantic. Setiap data milik pengguna diperiksa kepemilikannya di servis.
- Respons tidak mengembalikan `kata_sandi`, jalur penyimpanan berkas, atau data pengguna lain.

## Aturan bisnis yang ditegakkan di backend

1. Mahasiswa hanya melihat beasiswa berstatus `terbit` dengan tenggat belum lewat.
2. Teks rekomendasi tidak memuat klaim pasti diterima atau ditolak dan tidak memuat persen peluang.
3. Payload ke layanan AI tidak memuat `nama` dan `tanggal_lahir`.
4. Chatbot hanya menjawab dari data yang diambil dari basis data; bila tidak ada, menolak sopan.
5. Batas laju: login, unggah dokumen, dan chat.
6. Layanan AI gagal atau kuota habis: unggah tetap tersimpan dengan `status_baca = gagal`, pengguna dapat mengisi profil manual; chat mengembalikan `UPSTREAM_UNAVAILABLE` dengan pesan yang jelas.

## Kriteria selesai per modul

- Rute, servis, repositori, skema, dan uji otomatis ada.
- Endpoint tercatat di `02-API-CONTRACT.md` dan di OpenAPI hasil generate.
- Jalur gagal diuji: tanpa token, token kedaluwarsa, peran tidak berhak, data milik pengguna lain, masukan tidak valid.
- Entri `apps/docs/features/` dan `apps/docs/flows/` diperbarui.

## Di luar lingkup

Pendaftaran beasiswa dari dalam SMART, verifikasi keaslian dokumen, pembayaran, SSO dan SIAK.
