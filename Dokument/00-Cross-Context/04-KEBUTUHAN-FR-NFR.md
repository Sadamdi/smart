# Kebutuhan Fungsional dan Nonfungsional

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Active |
| **Author** | Tim SMART |
| **Sumber bisnis** | Dokumen Proses Bisnis BP-SM-001 (bagian kebutuhan) |

Kode kebutuhan sama dengan Dokumen Proses Bisnis. Kolom komponen dan fase menunjukkan tempat membangunnya; kolom uji menunjukkan bukti di `05-Pengujian/`.

## Kebutuhan fungsional

| Kode | Kebutuhan | Proses | Komponen | Fase | Uji |
| --- | --- | --- | --- | --- | --- |
| FR-SM-01 | Memantau daftar sumber beasiswa secara terjadwal | M-SM-001 | crawler | F3 | Uji penjadwal, uji sumber dengan HTML tersimpan |
| FR-SM-02 | Mengekstrak pengumuman menjadi data terstruktur dengan pola per sumber dan cadangan layanan AI | M-SM-001 | crawler | F3 | Akurasi ekstraksi pada contoh berlabel |
| FR-SM-03 | Hanya menerbitkan beasiswa bertenggat paling cepat tiga hari ke depan; menandai kedaluwarsa | M-SM-001 | backend, crawler | F3, F9 | Uji aturan tenggat |
| FR-SM-04 | Admin memvalidasi dan memperbaiki data yang ditandai meragukan | M-SM-002 | backend, web | F9 | Uji alur antrean |
| FR-SM-05 | Mahasiswa mengisi profil dan mengunggah CV, sertifikat, pengalaman organisasi | M-SM-003 | backend, web, mobile | F4, F6 | Uji unggah dan batas ukuran |
| FR-SM-06 | Membaca dokumen menjadi profil terstruktur | M-SM-003 | backend | F4 | Uji pembacaan pada CV contoh |
| FR-SM-07 | Mengelompokkan beasiswa: memenuhi, hampir memenuhi, belum memenuhi | M-SM-004 | ml | F5 | Uji tabel keputusan kelayakan |
| FR-SM-08 | Menyusun peringkat dari skor kelayakan dan kemiripan | M-SM-004 | ml | F5 | Precision@5 pada gold set |
| FR-SM-09 | Menampilkan alasan dan catatan kekurangan syarat | M-SM-004 | ml, web, mobile | F5, F6 | Uji isi alasan |
| FR-SM-10 | Menampilkan detail beasiswa, langkah pendaftaran, tautan resmi | M-SM-005 | backend, web, mobile | F6 | Uji black box |
| FR-SM-11 | Chatbot menjawab dengan merujuk data di sistem | M-SM-005 | backend | F7 | Uji rujukan data dan penolakan |
| FR-SM-12 | Menyimpan beasiswa, kalender tenggat, checklist berkas | M-SM-006 | backend, web, mobile | F8 | Uji black box |
| FR-SM-13 | Notifikasi lewat surel dan aplikasi mobile | M-SM-007 | backend, mobile | F8 | Uji pengingat tidak ganda |
| FR-SM-14 | Admin mengelola sumber dan melihat laporan sistem | M-SM-008 | backend, web | F9 | Uji black box |

## Kebutuhan nonfungsional

| Kode | Kebutuhan | Cara memenuhi | Uji |
| --- | --- | --- | --- |
| NFR-SM-01 | Rekomendasi untuk 1000 beasiswa aktif selesai dalam 3 detik | Vektor di pgvector, skor dihitung dalam satu kueri bila mungkin, cache hasil per pengguna | Uji kinerja dengan 1000 beasiswa seed |
| NFR-SM-02 | Pemantauan mematuhi robots.txt dan memberi jeda antarpermintaan | Pemeriksa robots.txt di crawler, jeda per sumber dapat diatur | Uji unit pemeriksa, uji jeda |
| NFR-SM-03 | Dokumen dan data pribadi terenkripsi dan hanya dapat diakses pemiliknya | Enkripsi berkas saat disimpan, pemeriksaan kepemilikan di servis | Uji akses silang antarpengguna |
| NFR-SM-04 | Nama dan tanggal lahir tidak dikirim ke layanan AI | Pembersih payload sebelum panggilan | Uji otomatis atas payload |
| NFR-SM-05 | Rekomendasi tetap tampil saat layanan AI tidak tersedia | Rekomendasi tidak memanggil layanan AI | Uji dengan layanan AI dimatikan |
| NFR-SM-06 | Dapat diakses lewat peramban dan aplikasi mobile Android | Next.js responsif, Flutter Android | Uji black box di kedua platform |

## Aturan bisnis penting

Aturan bisnis lengkap (BR-SM-xx) ada di Dokumen Proses Bisnis. Yang paling memengaruhi kode:

- Sistem tidak pernah menyatakan pasti diterima atau ditolak, dan tidak menampilkan persen peluang lolos.
- Setiap beasiswa menyimpan tautan sumber resmi.
- Data yang ambigu tidak ditebak; ditandai untuk admin.
