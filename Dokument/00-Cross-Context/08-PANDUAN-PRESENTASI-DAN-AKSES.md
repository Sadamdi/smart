# Panduan Presentasi dan Akses SMART

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-11-03 |
| **Status** | Berlaku |
| **Author** | Tim SMART |
| **Sumber bisnis** | `07-MASTER-PROMPT-PEMBANGUNAN.md`, `01-Arsitektur/03-ATURAN-KELAYAKAN-DAN-MODEL.md`, `01-Arsitektur/04-PEMANTAUAN-SUMBER.md`, sheet pemantauan kelas |

Panduan untuk manajer proyek yang menjelaskan SMART kepada dosen tanpa harus hafal kode.

## 1. SMART dalam tiga kalimat

SMART memantau laman resmi beasiswa, menyimpannya sebagai data terstruktur, lalu menyarankan beasiswa yang cocok untuk tiap mahasiswa beserta alasannya. Mahasiswa melihat saran itu di web atau aplikasi Android, menyimpan beasiswa, mencentang berkas yang harus disiapkan, dan mendapat pengingat tenggat. Sistem tidak pernah menyatakan mahasiswa pasti diterima atau ditolak.

## 2. Alur kerja dari data sampai layar

| Langkah | Apa yang terjadi | Di mana kodenya |
| --- | --- | --- |
| 1. Pemantauan | Program membuka laman resmi beasiswa (setelah memeriksa `robots.txt`), membaca tabel programnya, dan mengubahnya menjadi data baku | `apps/crawler` |
| 2. Validasi | Beasiswa baru terbit hanya bila tenggatnya minimal 3 hari lagi dan tautan resmi ada. Data yang meragukan masuk antrean admin | `apps/crawler/smart_crawler/validasi.py`, `apps/backend/app/services/admin.py` |
| 3. Penyimpanan | Data masuk ke basis data PostgreSQL (13 tabel) di Supabase | `apps/backend/app/models/tables.py` |
| 4. Profil | Mahasiswa mengisi profil atau mengunggah CV; sistem membaca IPK, skor bahasa, semester | `apps/backend/app/services/dokumen.py` |
| 5. Rekomendasi | Mesin menilai tiap beasiswa terhadap profil (bagian 4 di bawah) | `apps/backend/app/rekomendasi` |
| 6. Tampilan | Web dan aplikasi mobile menampilkan saran, kalender, checklist, notifikasi | `apps/web`, `apps/mobile` |
| 7. Chatbot | Menjawab pertanyaan hanya dari data di basis data, bukan dari pengetahuan umum | `apps/backend/app/services/chat.py` |

## 3. Data berasal dari mana

- **Pemantauan otomatis:** laman Informasi Beasiswa Kemahasiswaan UIN Malang. Hasil nyata: 36 program tersimpan di basis data. Semuanya menunggu validasi karena laman tidak menuliskan tenggat dan sistem tidak boleh menebak.
- **Riset sumber (dokumen Hasil Riset Data Beasiswa, disusun Devan, ditambah bagian 12 dan 13):** sembilan laman awal dari daftar tim ditambah empat sumber baru (Beasiswa Unggulan, KIP Kuliah, Tanoto Foundation, Australia Awards). Hasilnya: hanya SatuBeasiswa yang datanya lengkap dan terstruktur, sebagian besar sumber lain berupa tabel statis atau pengumuman sehingga butuh validasi admin.
- **Input manual admin:** untuk beasiswa yang tidak bisa dipantau otomatis, admin mengisi lewat panel admin.
- **Data demo:** untuk presentasi tersedia data berawalan `[DEMO]` yang jelas diberi tanda dan tautannya memakai domain contoh. Data ini bukan beasiswa nyata dan dapat dihapus dengan satu perintah (bagian 7).
- **Kuesioner:** 25 responden mahasiswa (dokumen Data Hasil Kuesioner) menjadi dasar kebutuhan pengguna.

## 4. Metode: bagaimana saran dibuat

Tiga lapis, semuanya dapat dijelaskan:

1. **Kelayakan dengan toleransi.** Tiap syarat beasiswa (IPK minimum, semester, jenjang, jenis kampus, domisili, usia, skor bahasa, berkas) dicocokkan dengan profil. Hasilnya tiga kategori: memenuhi, hampir memenuhi (kurang sedikit pada syarat yang masih bisa dikejar, misalnya IPK kurang tidak lebih dari 0,25), dan belum memenuhi. Syarat yang tidak bisa dikejar seperti jenjang atau domisili yang tidak sesuai langsung membuat kategori belum memenuhi.
2. **Kemiripan teks.** Minat dan program studi mahasiswa dibandingkan dengan nama dan manfaat beasiswa memakai vektor teks. Saat ini memakai pengemas hashing 384 dimensi yang ringan; model bahasa Indonesia all-indo-e5-small-v4 disiapkan sebagai pengganti.
3. **Pengurutan.** Skor gabungan = 0,6 kelayakan + 0,4 kemiripan, hanya untuk mengurutkan di dalam kategori. Skor tidak ditampilkan sebagai persen peluang.

Setiap saran disertai alasan ("IPK 3,55 memenuhi syarat minimum 3,00") dan, untuk hampir memenuhi, catatan kekurangan ("IPK kurang 0,10 dari syarat 3,65"). Layanan AI (Gemini) hanya dipakai untuk chatbot dan membaca dokumen, bukan untuk menentukan peringkat. Dosen menolak istilah "pencocokan" dan Simple Additive Weighting, jadi tidak dipakai.

Tahap berikutnya yang belum dikerjakan: peringkat belajar-mesin LightGBM dan penjelasan SHAP setelah ada data interaksi pengguna, serta evaluasi dengan gold set (target Precision@5 minimal 0,8).

## 5. Di mana semuanya (untuk ditunjukkan)

| Yang ditanyakan | Tunjukkan |
| --- | --- |
| Web | `http://localhost:3000` (lokal), atau alamat Vercel setelah dipasang |
| UI/UX | Desain Figma `pot92lK04wCd7uc2iEAY1G` (Riska) dan `Dokument/03-Frontend/03-RENCANA-UIUX-DARI-FIGMA.md` |
| Backend | `http://localhost:8000/docs` (Swagger, semua endpoint bisa dicoba) dan folder `apps/backend` |
| Mobile | Folder `apps/mobile`; APK debug dibuat dengan `flutter build apk --debug` |
| Basis data | Supabase proyek SMART; skema di `Dokument/01-Arsitektur/02-SKEMA-DATABASE.md` |
| Pengujian | `uv run pytest` (backend, 68 uji), `npm test` (web, 30), `flutter test` (mobile, 28), `uv run pytest` di `apps/crawler` (11) |
| Kode dan riwayat | GitHub `Sadamdi/smart`, cabang `main`, PR nomor 4 sampai 12 |
| Dokumen manajemen proyek | Folder Kelompok 8 di Drive kelas |

## 6. Menjalankan secara lokal (laptop)

Syarat: Python 3.12 dengan `uv`, Node.js, dan `apps\backend\.env` berisi `DATABASE_URL` dan `JWT_SECRET`. Basis data tetap Supabase, jadi laptop perlu internet. Basis data lokal sepenuhnya tanpa internet membutuhkan PostgreSQL dengan ekstensi pgvector yang belum dipasang di laptop ini.

```powershell
cd D:\Adam_Project\SmartAI\SMART
powershell -ExecutionPolicy Bypass -File scripts\jalankan-lokal.ps1 -Demo
```

Skrip memasang dependensi, mengisi data demo, lalu membuka dua jendela: backend di port 8000 dan web di port 3000. Masuk dengan akun di `Dokument\local\AKUN-DEMO.md` (mahasiswa dan admin; berkas ini tidak masuk git). Menghentikan: `scripts\jalankan-lokal.ps1 -Berhenti`.

## 7. Data demo

```powershell
cd apps\backend
uv run python -m scripts.seed_demo --konfirmasi   # isi (aman diulang; tenggat selalu relatif hari ini)
uv run python -m scripts.seed_demo --hapus        # hapus semua data demo dan akun demo
```

Hapus data demo sebelum penggunaan nyata supaya mahasiswa tidak melihat beasiswa contoh.

## 8. Pertanyaan yang mungkin diajukan dosen

| Pertanyaan | Jawaban ringkas |
| --- | --- |
| Datanya dari mana? | Dari pemantauan otomatis laman resmi (UIN Malang sudah berjalan), riset sumber lain, dan input manual admin. Setiap beasiswa menyimpan tautan resmi dan tanggal terakhir diperiksa |
| Mengapa semua data menunggu validasi? | Aturan tim: tenggat tidak boleh ditebak. Laman UIN Malang hanya menulis bulan pelaksanaan, jadi admin melengkapi tenggat dari tautan resmi |
| Apa metodenya? | Kelayakan dengan toleransi, kemiripan teks, lalu skor gabungan. Bukan pencocokan persen dan bukan SAW |
| Apakah ini machine learning? | Lapisan kemiripan memakai representasi vektor teks. Peringkat belajar-mesin (LightGBM) dan SHAP direncanakan setelah ada data interaksi. Perlu dijawab jujur: saat ini kelayakan berbasis aturan, kemiripan berbasis vektor |
| Seberapa akurat? | Belum diukur dengan gold set. Evaluasi Precision@5 dijadwalkan pada tahap pengujian |
| Apa peran AI? | Chatbot dan pembacaan dokumen, hanya dari data basis data. Bila layanan AI mati, sistem menampilkan pesan jelas dan profil bisa diisi manual |
| Apakah menjamin diterima? | Tidak. Teks sistem tidak pernah menyatakan pasti diterima atau ditolak |
| Keamanan? | Kata sandi di-hash Argon2, token berumur pendek yang bisa dicabut, mahasiswa hanya melihat datanya sendiri, rahasia tidak ada di repo (dipindai gitleaks di CI) |
| Mengapa realisasi di sheet kelas tidak sama dengan laporan kita? | Lihat bagian 9 |

## 9. Cara kerja sheet kelas dan agar realisasi tercatat benar

Sheet membaca dokumen di folder Kelompok 8 tiap pagi sekitar 06.30 WIB dan menaikkan realisasi per kegiatan hanya bila dokumen memuat bukti untuk kegiatan itu. Realisasi hanya naik, tidak pernah turun.

Mengapa pernah tercatat sekitar 7 persen padahal kita memperkirakan lebih tinggi:

1. **Keterlambatan baca.** Sheet membaca dokumen versi 28 Oktober saat kode baru dimulai. Kegiatan modul profil dan modul saran saat itu tercatat 0 persen karena belum ada dokumen bukti.
2. **Bobot.** Tahap Pelaksanaan bernilai 50 persen dari total dan dibagi ke sepuluh kegiatan menurut jumlah hari. Kegiatan besar yang belum ada buktinya menahan angka tahap ini.
3. **Rumus kelas berbeda dari rumus WBS tim.** Angka laporan kemajuan tim (misalnya 65 persen) memakai bobot WBS. Sheet memakai bobot lima tahap kelas, jadi angkanya berbeda walau pekerjaannya sama.

Agar tidak meleset lagi:

- Unggah dokumen bukti ke folder Kelompok 8 **sebelum 06.30 WIB** setiap hari ada kemajuan. Pakai nama kegiatan yang sama dengan sheet (modul pemantauan beasiswa, modul profil dan dokumen, modul rekomendasi, modul chatbot kalender dan notifikasi, aplikasi web mobile admin, pengujian, penempatan).
- Tabel pemetaan kegiatan ke bukti ada di Laporan Implementasi Proyek SMART bagian ringkasan.
- Tahap Laporan (15 persen) naik bila ada laporan kemajuan mingguan dan laporan pengujian; buat tiap pekan.
- Tahap Penutup (10 persen) baru terisi dari uji coba pengguna dan serah terima (26 November sampai 8 Desember).
- Jangan menyunting sheet. Hanya unggah dokumen.
