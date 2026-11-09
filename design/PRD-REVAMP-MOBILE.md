# PRD Revamp Antarmuka Mobile SMART

Versi 1, 10 November 2026. Pemilik: Adam. Acuan pola: aplikasi Kelilink dan Smartcook milik tim (tata letak dan ritme, bukan salinan aset). Desain disimpan offline di `design/` dan dibangun dari `design/build_figcraft.py`.

## 1. Tujuan

1. Aplikasi terasa buatan tangan, bukan templat: hierarki jelas, satu aksi utama per layar, isi nyata (bukan teks pengisi).
2. Semua layar bagus di lebar 320 sampai 430 dp, skala huruf sampai 130 persen, mode terang dan gelap, tanpa teks terpotong atau tumpang tindih.
3. Tanpa kebocoran gaya AI: tidak ada gradasi ungu, ikon dekoratif tanpa fungsi, kartu bersarang tiga lapis, atau tulisan klise.
4. Web dan mobile memakai fitur, istilah, dan urutan yang sama.

## 2. Pengguna dan tugas utama (jobs to be done)

| Tugas pengguna | Layar utama | Ukuran sukses |
| --- | --- | --- |
| Tahu beasiswa mana yang layak dikejar minggu ini | Beranda | Pilihan utama terlihat tanpa menggulir |
| Menyaring dan membaca semua beasiswa | Jelajah | Hasil filter muncul kurang dari 1 detik terasa |
| Paham alasan sebuah beasiswa cocok atau belum | Rekomendasi, Detail | Alasan dan kekurangan terbaca dalam satu layar |
| Tidak melewatkan tenggat | Kalender, Notifikasi | Tenggat terdekat tampil di Beranda |
| Menjaga data profil dan berkas | Profil, Dokumen | Mengubah satu data kurang dari tiga ketukan |
| Bertanya soal beasiswa | Chat | Jawaban memuat sumber data |

## 3. Prinsip desain

- **Satu aksi utama.** Setiap layar punya satu tombol terisi. Aksi lain berupa tombol garis atau teks.
- **Isi dulu, hiasan belakangan.** Warna dan bentuk hanya untuk membedakan status atau mengelompokkan.
- **Ritme 8 dp.** Jarak antarbagian 24, antarkartu 12, padding kartu 16.
- **Sentuhan nyaman.** Target minimal 48 x 48 dp, jarak antartarget 8 dp.
- **Gerak bermakna.** 150 sampai 300 ms, kurva keluar (easeOutCubic), hormati pengaturan kurangi animasi.
- **Bahasa.** Indonesia baku, kalimat pendek, tanpa persen kecocokan, tanpa janji diterima.

## 4. Sistem desain

| Token | Terang | Gelap |
| --- | --- | --- |
| Utama | #225EAA | #3F7FD4 |
| Latar | #F9F9FF | #0C1320 |
| Kartu | #FFFFFF | #141E30 |
| Teks judul | #051B38 | #E8EEFA |
| Teks isi | #424751 | #C6CEDC |
| Sukses, peringatan, galat | #1B6B3A, #8A5A00, #BA1A1A | #6FD39A, #FFD27A, #FF8F86 |
| Aksen emas (logo, penanda) | #F5B73B | #F5B73B |

Tipografi Plus Jakarta Sans: judul layar 28/700, judul bagian 20/700, judul kartu 16/700, isi 14/400, keterangan 12/400, label 11/700. Radius: kontrol 14, kartu 20, hero 24, chip penuh. Ikon: Material Rounded 24 dp, satu keluarga saja. Tombol: tinggi 52, radius 14. Navigasi bawah: kapsul sudut atas 28, indikator pil, label selalu tampil.

Komponen: tombol (terisi, garis, teks, ikon), chip (status, filter), kartu beasiswa, kartu angka, bilah progres, kepala layar, keadaan kosong, keadaan galat, skeleton pemuat, bottom sheet, snackbar.

## 5. Spesifikasi per layar

1. **Pembuka.** Logo disusun dari potongan (topi jatuh, alas naik, jumbai turun, bintang, gelombang), lalu SMART per huruf dan tagline. 3 detik, dapat dilewati dengan ketukan.
2. **Masuk dan Daftar.** Logo, judul, dua kolom, satu tombol utama, tautan pindah. Kolom kata sandi dengan tombol lihat. Galat muncul di bawah kolom, bukan dialog.
3. **Beranda.** Hero (sapaan, tiga angka, kelengkapan profil), Pilihan Utama (satu kartu), Tenggat Terdekat (maks 3), Jalan Pintas. Tarik untuk menyegarkan.
4. **Rekomendasi.** Chip kategori (Semua, Memenuhi, Hampir, Belum) dengan jumlah, daftar kartu, alasan dan kekurangan terlipat bila panjang.
5. **Jelajah.** Kolom cari, chip jenjang, jumlah hasil, kartu ringkas (nama, penyelenggara, tenggat, jenjang), muat berikutnya otomatis di ujung daftar.
6. **Detail.** Kepala (nama, penyelenggara, tenggat, status), ringkasan manfaat, syarat dalam daftar bertanda terpenuhi atau tidak, berkas, bilah aksi bawah menetap (Simpan, Kunjungi Laman Resmi).
7. **Kalender.** Bulan dengan titik tenggat, daftar acara hari terpilih, checklist berkas.
8. **Profil.** Kepala bergradasi, tujuh data utama dengan penanda "wajib untuk rekomendasi", sisanya opsional, menu satu kartu.
9. **Dokumen.** Daftar berkas dengan status baca, tombol unggah, koreksi hasil baca.
10. **Chat.** Gelembung, saran pertanyaan, sumber di bawah jawaban.
11. **Pengaturan.** Tampilan (Sistem, Terang, Gelap), pengingat, versi, pembaruan.

Tiap layar wajib punya keadaan: memuat (skeleton), kosong (langkah berikutnya), galat (coba lagi), dan tanpa jaringan.

## 6. Kriteria penerimaan

- Tidak ada overflow pada lebar 320 dp dan skala huruf 130 persen (diuji dengan uji widget).
- Kontras teks minimal 4,5 : 1 di terang dan gelap.
- Tangkapan layar terang dan gelap untuk semua layar ada di `design/render/mobile/`.
- Analisis statis bersih, semua uji lulus.
- Desain FigCraft (`design/smart-ui.figcraft`) mencakup semua layar di atas dan selaras dengan kode.

## 7. Rencana kerja

| Tahap | Isi | Keluaran |
| --- | --- | --- |
| 1 | Sistem desain dan komponen bersama | Tema, komponen, uji overflow 320 dp |
| 2 | Desain FigCraft semua layar mobile | `smart-ui.figcraft`, render PNG |
| 3 | Penerapan Beranda, Rekomendasi, Jelajah | Kode dan tangkapan layar |
| 4 | Penerapan Detail, Kalender, Dokumen, Chat, Pengaturan, Masuk | Kode dan tangkapan layar |
| 5 | Tinjauan visual terang dan gelap, perbaikan | Daftar temuan ditutup |
| 6 | Rilis APK dan uji di ponsel | Rilis 1.2.0 |
