---
title: Rencana penyelesaian sampai 8 Desember 2026
doc_id: SM-RENCANA-01
status: aktif
updated: 2026-11-02
---

# Rencana penyelesaian sampai 8 Desember 2026

Keadaan 2 November 2026: skema basis data (4.2 bagian skema), autentikasi, profil, dan daftar beasiswa sudah jalan di backend (41 uji lulus, migrasi 0002 di Supabase SMART). Pemantau, rekomendasi, dan seluruh layar web masih harus dikerjakan.

## Batas MVP

Wajib (dikejar sebelum 25 November):

- Autentikasi, profil, daftar dan detail beasiswa.
- Data awal sedikitnya 30 beasiswa dari sumber resmi.
- Rekomendasi dengan alasan (kelayakan dan kemiripan, skor gabungan).
- Layar web: masuk, daftar, profil, daftar beasiswa, detail, rekomendasi.
- Validasi admin minimal.
- Terpasang di server dan Vercel.

Opsional (dikerjakan bila waktu tersisa): chatbot, kalender dan notifikasi, aplikasi mobile penuh, pemeringkatan LightGBM.

## Jadwal

| Minggu | Tanggal | Adam (backend, mobile, ML) | Riska (UI/UX, web) | Devan (data) |
| --- | --- | --- | --- | --- |
| 1 | 2 sampai 8 Nov | Gabung PR auth; 4.3 pemantau UIN Malang; seed sumber | Layar masuk, daftar, profil | Kumpulkan contoh HTML tiap sumber, tabel kolom |
| 2 | 9 sampai 15 Nov | Pemantau sumber lain, validasi dan terbit | Daftar dan detail beasiswa tersambung API | Isi dan periksa data awal sampai 30 beasiswa |
| 3 | 16 sampai 22 Nov | Mesin kelayakan dan embedding (F5) | Layar rekomendasi dan alasan | Validasi hasil rekomendasi terhadap data |
| 4 | 23 sampai 29 Nov | Admin validasi, deploy, uji menyeluruh | Panel admin, perbaikan UI | Uji penerimaan pengguna (UAT) |
| 5 | 30 Nov sampai 6 Des | Perbaikan galat, dokumentasi, laporan implementasi | Perapian, tangkapan layar laporan | Data akhir, lessons learned |
| 6 | 7 sampai 8 Des | Penutupan, serah terima | Penutupan | Penutupan |

## Risiko

- Server 1 GB tidak muat model embedding: hitung embedding secara lokal atau pakai layanan, simpan hasil di pgvector.
- Alamat Quick Tunnel berubah bila layanan restart: tetapkan domain bila ada.
- Struktur laman sumber berubah: simpan fixture HTML dan uji ekstraktor terhadapnya.

## Setiap modul selesai

Perbarui `apps/docs` (version, todo, features), jalankan uji, bangun ulang laporan kemajuan dan implementasi, lalu unggah ke folder Kelompok 8 agar sheet kelas membaca kemajuan.
