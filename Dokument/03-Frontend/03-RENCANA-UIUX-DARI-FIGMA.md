# Rencana UI/UX dari Figma

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-11-03 |
| **Status** | Disetujui untuk dibangun |
| **Author** | Tim SMART |
| **Sumber bisnis** | Figma `pot92lK04wCd7uc2iEAY1G` (kanvas SMART PROJECT, dibaca lewat Figma MCP), `01-PRD-WEB-MOBILE.md`, `02-PETA-LAYAR-KE-ENDPOINT.md` |

Dokumen ini menjadi dasar pembangunan seluruh antarmuka web dan mobile. Tema dan susunan layar mengikuti Figma. Bagian yang bertentangan dengan aturan proyek (kata "pencocokan", persen kecocokan, klaim peluang lolos) diganti sesuai tabel penyimpangan di bawah.

## Token desain

Diambil dari simpul Figma Dashboard Mahasiswa. Huruf Plus Jakarta Sans (Regular, Medium, SemiBold, Bold).

| Token | Nilai | Pemakaian |
| --- | --- | --- |
| `primary` | #225EAA | Tombol utama, tautan, penanda aktif |
| `primary-soft` | #6C9FEF | Aksen grafik, status hampir memenuhi |
| `navy` | #051B38 | Judul dan angka |
| `ink` | #424751 | Teks isi |
| `muted` | #576676 | Teks sekunder, label huruf kapital kecil |
| `surface` | #F9F9FF | Latar halaman |
| `container-1` | #F0F3FF | Latar kartu dalam |
| `container-2` | #E7EEFF | Chip dan baris |
| `container-3` | #DFE8FF | Hover dan ikon |
| `container-4` | #D6E3FF | Garis lingkaran dan penanda |
| `error` | #BA1A1A | Tenggat dekat, galat |
| `error-soft` | #FFDAD6 | Latar peringatan tenggat |
| `outline` | #C2C6D3 | Garis tepi |

| Properti | Nilai |
| --- | --- |
| Radius | 6, 8 (kontrol), 12 (kartu dalam), 16 (kartu), 9999 (chip dan tombol bulat) |
| Ukuran huruf | 11 (label), 12, 13, 14, 16, 20, 28 (judul halaman) |
| Bayangan | `0 1px 2px rgba(0,0,0,0.05)` pada kartu putih |
| Lebar web | 1280, sidebar 250, isi 1030 dengan padding 48, header 64 |
| Lebar mobile | 390 |

Tema gelap tidak ada di Figma. Tidak dibangun pada tahap ini.

## Kerangka web mahasiswa

Sidebar kiri 250 px: logo SMART (Scholarship Assistant), menu Dashboard, Rekomendasi Beasiswa, Jelajah Beasiswa, Kalender dan Checklist, Dokumen Saya, Chatbot AI, Profil Saya; di bawah kartu pengguna, Pengaturan, dan tombol keluar. Header 64 px: breadcrumb "Portal Akademik > Mahasiswa", chip semester dan IPK, kolom cari (pintasan Ctrl K), lonceng notifikasi, avatar.

## Inventaris layar

Kolom "Frame Figma" memuat ID frame versi terbaru (rangkaian 627 dan 628).

| Layar | Frame web | Frame mobile | Bagian utama | Data dari |
| --- | --- | --- | --- | --- |
| Masuk | 627:4605, 627:4765 | 627:7789 | Panel promosi tiga manfaat dan angka, formulir email dan kata sandi, tautan daftar | `POST /auth/login` |
| Daftar (baru, memakai gaya Masuk) | tambahan | tambahan | Nama, email, kata sandi, kampus, jenjang | `POST /auth/register` |
| Dashboard atau Beranda | 627:2 | 627:5430 | Sapaan dan dua tombol, empat metrik (IPK, rekomendasi utama, hampir memenuhi, tenggat terdekat), pilihan utama, checklist berkas, peta kelayakan (donat), kelengkapan profil, kalender tenggat, jalan pintas | `/rekomendasi`, `/me/kalender`, `/me/checklist`, `/me` |
| Jelajah Beasiswa | 627:496 | 627:6125 | Judul, kolom cari, chip filter, kisi tiga kolom kartu, paginasi, ajakan chatbot | `GET /beasiswa` |
| Detail Beasiswa dan Mulai Berkas | 627:1087 | 627:6529 | Manfaat, syarat, berkas wajib, tautan portal resmi, tombol simpan | `GET /beasiswa/{id}`, `/interaksi`, `/me/checklist` |
| Rekomendasi | 627:1636 | 627:5781 | Ringkasan profil, tab kategori, filter, kartu dengan alasan dan catatan kekurangan, ajakan chatbot | `GET /rekomendasi` |
| Kalender dan Checklist | 627:2110 | 627:6939 | Kalender bulan, daftar tenggat, checklist berkas per beasiswa, tugas pribadi | `/me/kalender`, `/me/checklist`, `/me/tugas` |
| Dokumen Saya | 627:3086 | menyusul | Ringkasan kelengkapan, unggah, daftar dokumen dengan status baca, koreksi hasil baca | `/me/dokumen` |
| Chatbot AI | 627:2652 | menyusul | Percakapan dengan konteks profil, rujukan beasiswa, kolom masukan | `POST /chat` |
| Profil Saya | 627:3693 | 627:7385 | Data akademik dan pribadi, minat, pengalaman, kelengkapan profil | `GET /me`, `PUT /me/profil` |
| Notifikasi | 627:4930 | 627:7937 | Daftar per jenis, tandai dibaca | `/notifikasi` |
| Pengaturan dan Akun | 627:4229 | menyusul | Preferensi pengingat, ganti kata sandi, ekspor, hapus akun | `/me/*`, `/auth/ganti-kata-sandi` |
| Admin, Dashboard | 628:8194 | tidak ada | Ringkasan sistem | `GET /admin/laporan` |
| Admin, Antrean Validasi | 628:8645 | tidak ada | Daftar menunggu dengan alasan ditandai | `GET /admin/antrean-validasi` |
| Admin, Detail Validasi | 628:9129 | tidak ada | Nilai terbaca sistem berdampingan dengan teks asal, edit, terbitkan, tolak | `PUT /admin/beasiswa/{id}` dan aksi |
| Admin, Kelola, Tambah, Edit Sumber | 628:9567, 628:10105, 628:10868 | tidak ada | Daftar sumber dan status, formulir sumber | `/admin/sumber` |
| Admin, Laporan Sistem | 628:10428 | tidak ada | Angka ekstraksi dan keandalan kanal | `GET /admin/laporan` |

## Penyimpangan dari Figma (wajib)

| Teks di Figma | Diganti menjadi | Alasan |
| --- | --- | --- |
| "100% Cocok (5/5 Kriteria)" | "Memenuhi 5 dari 5 syarat" | Tidak ada persen kecocokan (PRD web) |
| "Pencocokan akurat" | "Rekomendasi berdasarkan profil" | Kata dilarang dosen |
| "peluang lolos", "estimasi kecocokan 98%" | "kelengkapan syarat" tanpa angka peluang | Sistem tidak menyatakan kepastian |
| "Peta Kelayakan" dengan persentase | Jumlah per kategori (memenuhi, hampir memenuhi, belum memenuhi) | Skor tidak ditampilkan sebagai persen |
| Data contoh (Nabila, UI, BI 2025) | Data pengguna dan basis data nyata | Tidak ada data fiktif di produk |
| "Sinkronisasi hari ini 08.30 WIB dari Puslapdik" | Waktu pemeriksaan sumber dari `tanggal_diperiksa` | Hanya fakta yang tercatat |

## Pustaka komponen

Dibuat sekali, dipakai ulang di semua layar web (`apps/web/src/components/`) dan padanannya di Flutter (`apps/mobile/lib/core/widgets/`).

`AppShell` (sidebar, header), `KartuBeasiswa`, `ChipFilter`, `ChipStatus`, `Metrik`, `Donat`, `BarProgres`, `DaftarChecklist`, `KalenderBulan`, `GelembungChat`, `KolomUnggah`, `KosongState`, `MemuatState`, `GalatState`, `Tombol` (utama, sekunder, hantu), `Masukan`, `Pilihan`.

## Keadaan wajib per layar

Memuat (kerangka), kosong (pesan dan langkah berikutnya), galat jaringan (coba lagi), token kedaluwarsa (kembali ke masuk), layanan AI tidak tersedia (pesan dan jalur manual). Kontras WCAG AA: teks `ink` dan `navy` di atas `surface` memenuhi; `muted` hanya untuk teks 12 px ke atas.

## Urutan pembangunan

1. Token, `AppShell`, klien API, penyimpanan token, Masuk dan Daftar.
2. Jelajah, Detail, Dashboard, Rekomendasi.
3. Profil, Dokumen, Kalender dan Checklist, Notifikasi, Chatbot, Pengaturan.
4. Admin (antrean, detail, sumber, laporan).
5. Mobile: Masuk, Beranda, Rekomendasi, Jelajah, Detail, Kalender dan Checklist, Profil, Notifikasi.
6. Uji komponen, uji alur, tangkapan layar dibandingkan dengan Figma, perbaikan selisih.
