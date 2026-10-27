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
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `Dokument/03-Frontend/02-PETA-LAYAR-KE-ENDPOINT.md` |

## Progress Summary

- Total tugas: 7
- Selesai: 0
- Sisa: 7

## Tugas

### T1. Kerangka web dan mobile
Kartu Kaneo: 4.6 `[FE] Aplikasi web dan mobile`
- [ ] Klien API (web: fetch terpusat; mobile: Dio), penyimpanan token, penyegaran token otomatis
- [ ] Tema, komponen dasar sesuai Figma, layout responsif
Penerimaan: halaman kosong memanggil `/health` dan menampilkan hasilnya.

### T2. Jelajah Beasiswa (irisan pertama)
- [ ] Daftar dengan pencarian, filter, urutan, paginasi kursor; keadaan memuat, kosong, galat
Penerimaan: terhubung ke `GET /beasiswa` di web dan Android.

### T3. Detail Beasiswa
- [ ] Persyaratan, berkas wajib, tautan resmi, simpan dan rencana daftar
Penerimaan: tautan resmi terbuka di tab baru; aksi simpan tercatat.

### T4. Login dan registrasi
- [ ] Layar registrasi (baru, minta desain), login, keluar, kata sandi
Penerimaan: jalur gagal menampilkan pesan Indonesia yang jelas.

### T5. Profil Saya dan Dokumen Saya
- [ ] Formulir profil dengan validasi, unggah dokumen, tampilan hasil baca dan koreksi
Penerimaan: nama dan tanggal lahir tetap tersimpan, hanya tidak dikirim ke layanan AI (cek di backend).

### T6. Rekomendasi dan Dashboard
- [ ] Tab kategori, kartu dengan alasan dan catatan kekurangan, tombol hitung ulang
- [ ] Dashboard tiga bagian
Penerimaan: tidak ada persen peluang atau kata "pencocokan" di antarmuka.

### T7. Kontras, bahasa, dan keadaan khusus
- [ ] Kontras WCAG AA, teks Indonesia, keadaan layanan AI tidak tersedia
Penerimaan: lolos pemeriksaan kontras dan telaah teks.

## Pertanyaan terbuka

O-08.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
