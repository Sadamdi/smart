# F6. Antarmuka web dan mobile

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F6, WBS 4.6, FR-SM-05, 09, 10 |
| **Module** | web, mobile |
| **Priority** | P0 |
| **Progress** | 70% (web selesai, mobile belum) |
| **Last Updated** | 2026-11-03 |
| **Doc Reference** | `Dokument/03-Frontend/02-PETA-LAYAR-KE-ENDPOINT.md` |

## Progress Summary

- Total tugas: 7
- Selesai: T1 sampai T6 untuk web, T7 sebagian
- Sisa: mobile (Flutter) dan perbandingan dengan Figma

## Tugas

### T1. Kerangka web dan mobile
Kartu Kaneo: 4.6 `[FE] Aplikasi web dan mobile`
- [x] Klien API (web: fetch terpusat; mobile: Dio), penyimpanan token, penyegaran token otomatis (web)
- [x] Tema, komponen dasar sesuai Figma, layout responsif (web)
Penerimaan: halaman kosong memanggil `/health` dan menampilkan hasilnya.

### T2. Jelajah Beasiswa (irisan pertama)
- [x] Daftar dengan pencarian, filter, urutan, paginasi kursor; keadaan memuat, kosong, galat (web)
Penerimaan: terhubung ke `GET /beasiswa` di web dan Android.

### T3. Detail Beasiswa
- [x] Persyaratan, berkas wajib, tautan resmi, simpan dan rencana daftar (web)
Penerimaan: tautan resmi terbuka di tab baru; aksi simpan tercatat.

### T4. Login dan registrasi
- [x] Layar registrasi (baru, minta desain), login, keluar, kata sandi (web)
Penerimaan: jalur gagal menampilkan pesan Indonesia yang jelas.

### T5. Profil Saya dan Dokumen Saya
- [x] Formulir profil dengan validasi, unggah dokumen, tampilan hasil baca dan koreksi (web)
Penerimaan: nama dan tanggal lahir tetap tersimpan, hanya tidak dikirim ke layanan AI (cek di backend).

### T6. Rekomendasi dan Dashboard
- [x] Tab kategori, kartu dengan alasan dan catatan kekurangan, tombol hitung ulang (web)
- [x] Dashboard tiga bagian (web)
Penerimaan: tidak ada persen peluang atau kata "pencocokan" di antarmuka.

### T7. Kontras, bahasa, dan keadaan khusus
- [x] Kontras WCAG AA, teks Indonesia, keadaan layanan AI tidak tersedia (web)
Penerimaan: lolos pemeriksaan kontras dan telaah teks.

## Pertanyaan terbuka

O-08.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
| 2026-11-03 | Antarmuka web dibangun (v20261103-f6-antarmuka-web.md) | Web selesai; mobile dan perbandingan Figma menyusul |
