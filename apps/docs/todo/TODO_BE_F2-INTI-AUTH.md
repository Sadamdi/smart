# F2. Basis data, backend inti, dan autentikasi

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F2, WBS 4.2, FR-SM-05 |
| **Module** | backend |
| **Priority** | P0 |
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `apps/docs/features/01-auth/1. registrasi-login.md` |

## Progress Summary

- Total tugas: 6
- Selesai: 0
- Sisa: 6

## Tugas

### T1. Migrasi skema
Kartu Kaneo: 4.2 `[BE] Basis data dan fitur login`
- [ ] Putuskan O-03, O-04, O-05 (tabel tambahan dan kolom profil opsional)
- [ ] Alembic: 11 tabel sesuai `02-SKEMA-DATABASE.md`, ekstensi `vector`, indeks
- [ ] Migrasi naik dan turun teruji di basis data uji
Penerimaan: skema di basis data sama dengan dokumen.

### T2. Fondasi backend
- [ ] `core`: konfigurasi, keamanan (hash, JWT), galat domain dan pemetaannya, logging
- [ ] Format respons dan kode galat baku
- [ ] Lapisan rute, servis, repositori dengan contoh modul
Penerimaan: galat domain menjadi 401, 403, 404, 409, 422.

### T3. Auth
- [ ] register, login, refresh, logout, ganti kata sandi
- [ ] Batas laju login
Penerimaan: jalur gagal diuji (kata sandi salah, token kedaluwarsa).

### T4. Profil dan akun
- [ ] `GET /me`, `PUT /me/profil`, `PUT /me/preferensi-notifikasi`, `GET /me/ekspor`, `DELETE /me`
- [ ] Validasi: IPK 0 sampai 4, semester 1 sampai 14, jenjang valid
Penerimaan: pengguna A tidak dapat membaca atau mengubah pengguna B.

### T5. Beasiswa (baca)
- [ ] `GET /beasiswa` (filter, paginasi kursor), `GET /beasiswa/{id}`
- [ ] Hanya `terbit` dan tenggat belum lewat bagi mahasiswa
- [ ] Seed data uji (`seed` aman diulang)
Penerimaan: irisan vertikal pertama dapat dipanggil web.

### T6. OpenAPI dan dokumen
- [ ] OpenAPI dibangkitkan dan cocok dengan `02-API-CONTRACT.md`
- [ ] Feature doc auth, profil, beasiswa; indeks diperbarui
Penerimaan: gerbang di `.cursor/rules/task-completion-gate.mdc`.

## Pertanyaan terbuka

O-03, O-04, O-05.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
