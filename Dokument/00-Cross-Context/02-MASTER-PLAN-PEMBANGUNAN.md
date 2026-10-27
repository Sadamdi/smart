# Master Plan Pembangunan SMART

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft (menunggu persetujuan tim) |
| **Author** | Tim SMART |
| **Sumber bisnis** | WBS Waterfall SMART (paket kerja 4.1 sampai 7.5), Dokumen Perancangan DP-SM-001 |

Rencana ini membagi pembangunan menjadi fase kecil yang dapat dicicil. Setiap fase punya masukan, keluaran, dan gerbang selesai. Fase berikutnya tidak dimulai sebelum gerbang fase sebelumnya lolos. Tanggal mengikuti jadwal di Kaneo dan `tools/build_jadwal.py`; durasi di bawah memakai satuan hari kerja menurut WBS.

## Prinsip

1. Dokumen dulu, kode kemudian. Kontrak (skema, API, aturan) harus tertulis sebelum kode yang memakainya.
2. Satu tugas Kaneo per fitur atau perbaikan, judul berawalan `[BE]`, `[FE]`, `[ML]`, `[CRAWLER]`, `[INFRA]`, `[DOC]`.
3. Bangun irisan vertikal tipis lebih dulu (daftar beasiswa dari basis data sampai layar), baru diperluas.
4. Data dan rekomendasi dijaga dapat dijelaskan: setiap hasil menyimpan alasan.
5. Layanan AI tidak menentukan peringkat dan tidak dipanggil dengan nama atau tanggal lahir pengguna.

## Peta fase

| Fase | Nama | WBS | Durasi | PIC utama | Bergantung pada |
| --- | --- | --- | --- | --- | --- |
| F0 | Fondasi dokumen dan aturan | (di luar WBS, prasyarat 4.1) | 2 | Adam | Dokumen perancangan |
| F1 | Repositori dan lingkungan | 4.1 | 1 | Adam | F0 |
| F2 | Basis data, backend inti, autentikasi | 4.2 | 5 | Adam | F1 |
| F3 | Pemantau beasiswa dan dataset | 4.3 | 8 | Devan | F1 |
| F4 | Profil dan pembacaan CV | 4.4 | 4 | Riska | F2 |
| F5 | Mesin rekomendasi | 4.5 | 5 | Adam | F2, data dari F3 |
| F6 | Antarmuka web dan mobile | 4.6 | 6 | Riska | F4 |
| F7 | Chatbot dan penjelasan rekomendasi | 4.7 | 4 | Adam | F5 |
| F8 | Kalender, checklist, notifikasi | 4.8 | 3 | Devan | F6 |
| F9 | Panel admin dan validasi data | 4.9 | 3 | Devan | F3, F6 |
| F10 | Pengujian | 5.1 sampai 5.4 | 10 | Semua | Purwarupa selesai (4.10) |
| F11 | Penempatan, UAT, penutup | 6.1 sampai 7.5 | 10 | Semua | Sistem lolos uji (5.5) |

## Rincian fase

### F0. Fondasi dokumen dan aturan

- **Keluaran:** folder `Dokument/` lengkap, `.cursor/rules/`, `apps/docs/` beserta indeks dan templat, struktur `apps/` (kerangka kosong dengan README per komponen).
- **Gerbang selesai:** tim membaca `05-PERTANYAAN-TERBUKA.md` dan memutuskan butir yang menghalangi F1 sampai F2 (O-01 sampai O-04); Adam menyetujui ADR.

### F1. Repositori dan lingkungan (4.1)

- **Keluaran:** repositori git dengan cabang `main` dan `testing`; dua proyek Supabase (dev dan uji) dengan ekstensi `vector` aktif; `.env.example` per komponen; linter dan formatter; CI dasar (lint dan uji kosong lolos).
- **Gerbang selesai:** anggota tim mana pun dapat mengisi `.env` dari `.env.example`, menjalankan backend, lalu backend kosong menjawab `GET /api/v1/health`.

### F2. Basis data, backend inti, autentikasi (4.2)

- **Masukan:** `01-Arsitektur/02-SKEMA-DATABASE.md`, `02-Backend/02-API-CONTRACT.md` bagian auth dan profil.
- **Keluaran:** migrasi Alembic untuk 11 tabel; registrasi, login, penyegaran token, hapus akun, ekspor data; lapisan rute, servis, repositori; format respons dan kode galat baku.
- **Gerbang selesai:** uji otomatis auth lolos; pengguna dapat register, login, dan membaca profil lewat API; cakupan uji servis auth minimal 80%.

### F3. Pemantau beasiswa dan dataset (4.3)

- **Masukan:** `01-Arsitektur/04-PEMANTAUAN-SUMBER.md`, hasil riset sembilan sumber (Drive tim).
- **Keluaran:** konfigurasi per sumber, pengekstrak, normalisasi ke skema `beasiswa` dan `persyaratan`, validasi dan deduplikasi, penjadwal, antrean validasi untuk data meragukan.
- **Urutan sumber:** UIN Malang dahulu (kecil, stabil), SatuBeasiswa setelah izin atau API resmi tersedia, sumber lain berupa tautan keluar atau input kurasi.
- **Gerbang selesai:** minimal 30 beasiswa aktif tersimpan dengan tautan sumber; uji ekstraksi dengan HTML tersimpan lolos; pengambilan menghormati `robots.txt` dan jeda antarpermintaan.

### F4. Profil dan pembacaan CV (4.4)

- **Keluaran:** unggah dokumen (PDF, DOCX, JPG, PNG, maksimal 5 MB), pembacaan oleh layanan AI menjadi profil terstruktur, layar koreksi hasil baca, penyimpanan terenkripsi.
- **Gerbang selesai:** CV contoh terbaca menjadi profil yang dapat dikoreksi; nama dan tanggal lahir terbukti tidak ikut terkirim ke layanan AI (uji otomatis pada payload).

### F5. Mesin rekomendasi (4.5)

- **Masukan:** `01-Arsitektur/03-ATURAN-KELAYAKAN-DAN-MODEL.md`, dataset dari F3, profil dari F4.
- **Keluaran:** penilai kelayakan dengan toleransi, embedding dan pgvector, skor gabungan 0,6 kelayakan dan 0,4 kemiripan, alasan dan catatan kekurangan, gold set, skrip evaluasi. LightGBM LambdaMART dan SHAP menyusul setelah ada data interaksi.
- **Gerbang selesai:** Precision@5 pada gold set minimal 0,8 (target proyek); rekomendasi untuk 1000 beasiswa aktif tersusun dalam 3 detik; hasil tetap muncul bila layanan AI mati.

### F6. Antarmuka web dan mobile (4.6)

- **Masukan:** Figma (setelah revisi), `03-Frontend/02-PETA-LAYAR-KE-ENDPOINT.md`.
- **Urutan layar:** login dan registrasi, profil, jelajah dan detail beasiswa, rekomendasi, dokumen saya, beranda. Web dan mobile berjalan paralel per layar.
- **Gerbang selesai:** alur mahasiswa dari registrasi sampai melihat rekomendasi berjalan di web dan Android; kontras teks dan bahasa Indonesia sesuai catatan desain.

### F7. Chatbot dan penjelasan rekomendasi (4.7)

- **Keluaran:** endpoint chat yang menjawab dari data basis data saja, batas 2000 karakter per pesan, penanganan kuota layanan AI habis, riwayat percakapan.
- **Gerbang selesai:** jawaban selalu merujuk beasiswa yang ada di basis data; pertanyaan di luar data dijawab penolakan sopan.

### F8. Kalender, checklist, notifikasi (4.8)

- **Keluaran:** daftar tersimpan, status rencana daftar, checklist berkas, tugas pribadi, pengingat tenggat lewat surel dan push (FCM), preferensi notifikasi.
- **Gerbang selesai:** pengingat terkirim pada tenggat yang ditentukan dan tidak terkirim dua kali.

### F9. Panel admin dan validasi data (4.9)

- **Keluaran:** antrean validasi, perbaiki atau terbitkan atau tolak beasiswa, kelola sumber, laporan sistem.
- **Gerbang selesai:** data meragukan dari pemantau dapat diperiksa dan diterbitkan admin; hanya beasiswa bertenggat paling cepat tiga hari ke depan yang tampil ke mahasiswa.

### F10. Pengujian (5.1 sampai 5.4)

- Unit dan integrasi (Adam), black box (Riska), evaluasi kualitas rekomendasi dan akurasi ekstraksi (Adam), perbaikan temuan (semua). Rincian di `05-Pengujian/`.
- **Gerbang selesai (5.5):** semua kriteria di `05-Pengujian/01-STRATEGI-UJI.md` terpenuhi atau pengecualiannya tercatat.

### F11. Penempatan, UAT, penutup (6.1 sampai 7.5)

- Penempatan di hosting, UAT bersama calon pengguna, perbaikan, manual pengguna, alih teknologi ke admin, laporan akhir dan lessons learned, serah terima. Rincian di `04-Infra/`.

## Urutan irisan vertikal pertama

Ini yang dikerjakan lebih dulu setelah F1 supaya kerangka teruji ujung ke ujung sebelum fitur diperbanyak:

1. Tabel `sumber` dan `beasiswa` dengan data uji dari seed.
2. `GET /api/v1/scholarships` dan `GET /api/v1/scholarships/{id}`.
3. Layar Jelajah Beasiswa di web membaca endpoint itu.
4. Pemantau UIN Malang mengisi tabel yang sama.

## Cara mencicil

- Satu fase dipecah menjadi tugas Kaneo kecil (maksimal sekitar dua hari kerja). Pecahan tercatat di `apps/docs/todo/`.
- Tiap tugas memakai alur di `.cursor/rules/01-delivery-workflow.mdc`: plan di `apps/docs/version/`, kerjakan, uji, perbarui feature dan flow, tutup di Kaneo.
- Setelah tiap fase selesai, perbarui `tools/build_kemajuan_pdf.py` (realisasi) dan unggah Laporan Kemajuan ke folder K8 agar progres terbaca kelas.

## Risiko utama pembangunan

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Izin SatuBeasiswa belum ada | Dataset kecil | Mulai dari UIN Malang dan input kurasi; ajukan izin sejak F1 |
| Struktur laman sumber berubah | Pemantau gagal diam-diam | Uji dengan HTML tersimpan, alarm bila hasil ekstraksi nol, antrean validasi |
| Kuota layanan AI habis | Pembacaan CV dan chatbot berhenti | Rekomendasi tidak bergantung pada layanan AI; tampilkan pesan dan isi manual |
| Data latih LambdaMART belum ada | Pemeringkatan lanjutan tertunda | Skor gabungan sudah cukup untuk purwarupa; LambdaMART tahap lanjutan |
| Waktu sempit (realisasi di bawah rencana) | Tahap 4 tidak selesai | Prioritaskan irisan vertikal; fitur F8 dan F9 dikurangi bila perlu, catat di KEPUTUSAN |
