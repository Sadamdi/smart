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
- [x] O-03, O-04, O-05 diputuskan (27 Okt): `tugas_pribadi` dan `perangkat_push` ditambahkan, kolom profil opsional dipakai
- [x] Model SQLAlchemy 13 tabel dan migrasi Alembic 0001 (ekstensi `vector`, indeks HNSW, batasan unik pengingat); uji skema tanpa basis data lolos (13 uji)
- [x] Skrip `scripts/seed_sumber.py` (sembilan sumber, upsert) dan `scripts/cleanup.py` (dijaga `pastikan_boleh_hapus`)
- [ ] Migrasi naik dan turun dijalankan di proyek Supabase uji (menunggu connection string)
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
