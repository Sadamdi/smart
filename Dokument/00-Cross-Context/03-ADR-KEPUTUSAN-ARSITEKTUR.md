# ADR: Keputusan Arsitektur SMART

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | KEPUTUSAN.md (8 Oktober 2026), Dokumen Perancangan DP-SM-001 |

Status tiap keputusan: **Tetap** (sudah diputuskan tim atau dosen), **Diusulkan** (usulan penyusun rencana, perlu disetujui tim).

| ID | Keputusan | Status | Alasan |
| --- | --- | --- | --- |
| A-01 | Web Next.js, mobile Flutter, server FastAPI, PostgreSQL dengan pgvector, notifikasi FCM | Tetap (8 Okt) | Satu basis kode per platform, ekosistem Python untuk ML |
| A-02 | Rekomendasi tiga lapis: kelayakan dengan toleransi, kemiripan embedding, pemeringkatan | Tetap | Arahan dosen: berbasis machine learning, bukan Simple Additive Weighting |
| A-03 | Layanan AI hanya membaca dokumen, ekstraksi cadangan, dan chatbot; tidak menentukan peringkat | Tetap | Hasil dapat dijelaskan dan tetap jalan saat layanan AI mati |
| A-04 | Pemantauan campuran: SatuBeasiswa utama (dengan izin), UIN Malang tabel HTML, sumber lain tautan keluar atau input kurasi | Tetap (22 Okt, riset tim) | Tidak semua sumber boleh atau bisa diambil otomatis |
| A-05 | Monorepo satu repositori git dengan `apps/backend`, `crawler`, `ml`, `web`, `mobile` | Tetap (Adam, 26 Okt) | Tim tiga orang, perubahan lintas komponen sering, satu papan Kaneo. Cabang `main` dan `testing` |
| A-06 | Lapisan backend: rute, servis, repositori. Rute tidak menyentuh basis data | Tetap (apps/README) | Mudah diuji dan dirawat |
| A-07 | `ml` berupa paket Python yang diimpor backend, bukan layanan terpisah | Diusulkan | Satu proses cukup untuk 1000 beasiswa; menghindari jaringan antar layanan |
| A-08 | Crawler berjalan sebagai proses terpisah dengan penjadwal sendiri, menulis ke basis data yang sama | Diusulkan | Gangguan pemantau tidak menjatuhkan API |
| A-09 | Versi API di jalur `/api/v1`; respons `{success, data, error:{code,message}}`; paginasi berbasis kursor | Diusulkan (mengikuti pola Kelilink) | Konsisten untuk web dan mobile |
| A-10 | Migrasi dengan Alembic; basis data dev, uji, dan produksi terpisah | Tetap (apps/README) | Mencegah kejadian hapus data seperti di proyek lain |
| A-11 | Embedding: all-indo-e5-small-v4 disimpan di pgvector, dihitung ulang saat beasiswa atau profil berubah | Tetap (model), Diusulkan (jadwal hitung) | Model sudah ditetapkan di Laporan Inisiasi |
| A-12 | Dokumen pengguna disimpan terenkripsi; nama dan tanggal lahir tidak dikirim ke layanan AI | Tetap (NFR-SM-03, 04) | Kebutuhan privasi |
| A-13 | Bahasa kode dan komentar: Inggris untuk identifier, Indonesia untuk teks tampilan dan dokumentasi | Diusulkan | Identifier Inggris lazim; pengguna dan dosen berbahasa Indonesia |
| A-14 | Nama tabel dan kolom memakai bahasa Indonesia seperti di Dokumen Perancangan | Tetap | Konsisten dengan dokumen kelas |
| A-15 | Hanya beasiswa dengan tenggat paling cepat tiga hari ke depan yang diterbitkan | Tetap (FR-SM-03) | Aturan bisnis |
| A-16 | Basis data PostgreSQL memakai Supabase (ekstensi `vector` aktif), tanpa Docker. Proyek terpisah untuk dev dan uji; produksi menyusul bersama server Adam | Tetap (Adam, 26 Okt) | Mesin pengembang tidak memakai Docker dan PostgreSQL lokal tidak punya pgvector |
| A-17 | Backend, crawler, dan ml memakai Python 3.12 (lewat uv) | Diusulkan | Python 3.14 berisiko untuk PyTorch dan turunannya |
| A-18 | Produksi memakai server dan domain milik Adam; kerangka penempatan disiapkan di F1, nilai diisi saat server diberikan | Tetap (Adam, 26 Okt) | Keputusan pengguna |

## Hal yang dengan sengaja tidak dibangun

SSO dan SIAK, asisten esai, WhatsApp, sinkron kalender eksternal, dan profil ke kemitraan dipindah ke pengembangan lanjutan (catatan revisi Figma).

## Cara mengubah keputusan

Tambahkan baris baru dengan ID berikutnya, jangan menghapus baris lama. Bila keputusan lama diganti, ubah statusnya menjadi "Digantikan oleh A-xx". Catat juga di `agents/KEPUTUSAN.md`.
