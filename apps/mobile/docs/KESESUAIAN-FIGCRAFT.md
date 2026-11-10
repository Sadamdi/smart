# Kesesuaian tampilan mobile dengan desain FigCraft

Dibuat 11 November 2026 (versi 1.5.0). Perbandingan dilakukan dengan membuka PNG desain (`design/render/M*.png`, terang dan gelap) berdampingan dengan tangkapan aplikasi (`design/render/mobile/*.png`, dihasilkan tes golden). Penilaian ini visual dan dilakukan manual; tidak ada pengukuran piksel otomatis.

## Cara menghasilkan tangkapan

```
cd apps/mobile
TANGKAP=1 flutter test test/tangkap_test.dart test/tangkap2_test.dart --update-goldens
```

Keluaran masuk ke `design/render/mobile/`. Data palsu bersama ada di `test/data_tangkap.dart` dan meniru isi desain (nama beasiswa, tenggat, angka 12, 31, 104). Tes golden memakai huruf Plus Jakarta Sans bobot Medium untuk semua gaya, sehingga tebal huruf pada tangkapan tidak persis desain (desain memakai Inter). Hanya tanggal tenggat yang berbeda dari desain karena dihitung dari hari ini.

## Selisih yang diperbaiki per layar

| Layar | Selisih pada kondisi awal | Perbaikan |
| --- | --- | --- |
| Semua tab | Ikon menu bawah berbeda; label "Rekomendasi" turun ke dua baris; kepala punya subjudul prodi dan avatar | Ikon rumah, bintang, kaca pembesar, kalender, orang; label satu baris dengan FittedBox; kepala hanya logo, SMART, dan lonceng dalam lingkaran |
| Pembuka | Latar gradien biru, huruf putih | Latar permukaan, logo dalam kotak biru 96 dp, SMART navy, tagline abu |
| Masuk | Logo 84, kolom berlabel dengan ikon, tautan daftar bergaya teks biasa | Logo 64, kolom hanya placeholder, tautan daftar berwarna utama, ukuran judul 22 |
| Beranda | Hero bergradien, kartu panjang dengan tombol "Lihat detail dan syarat", Jalan Pintas | Hero biru datar, kartu ringkas, baris tenggat berikon kalender, Jalan Pintas dihapus |
| Jelajah | Tombol Tersimpan sendiri, kolom cari persegi, chip tanpa garis | Kolom cari berbentuk kapsul dengan teks desain, chip putih bergaris, Tersimpan dipindah ke baris "Menampilkan N beasiswa" |
| Rekomendasi | Tombol Hitung ulang sendiri, chip panjang, tanpa tombol chat | Chip "Hampir" dan "Belum", Hitung ulang menjadi chip di ujung baris, tombol chat melayang |
| Detail | Banyak kartu putih, kotak Diperiksa, tombol simpan di bawah | Tombol kembali dan simpan bulat di atas, kotak tenggat tunggal, syarat berikon centang atau lingkaran kosong, Alasan rekomendasi berupa paragraf, tombol "Buka Laman Resmi" |
| Kalender | Judul panjang, agenda sebulan, kartu checklist | Judul "Kalender", titik merah pada tanggal bertenggat, agenda untuk tanggal terpilih, baris checklist berlingkaran |
| Profil | Gradien, kartu tanpa garis, menu berpanah | Hero datar, kartu bergaris tipis radius 20, judul "DATA UTAMA", menu tanpa panah |
| Dokumen | Dropdown jenis, tombol "Pilih berkas", tanpa lencana | Tombol "Unggah Dokumen", lencana Selesai/Menunggu/Gagal, ikon berkas persegi panjang |
| Chat | Chip aksi Material, gelembung bersudut tidak rata, judul "Chatbot AI" | Judul "Chatbot Beasiswa", chip saran putih bergaris, gelembung bergaris tipis, kolom kapsul dan tombol kirim membulat |
| Pengaturan | Satu kartu besar, urutan Pengingat dulu | Urutan Tampilan, Pengingat, Aplikasi; segmen kapsul; tiap baris kartu bergaris tipis |

## Status per layar (terang dan gelap)

| Layar | Status | Yang masih berbeda |
| --- | --- | --- |
| Pembuka | Sama pada kerangka akhir | Gelombang sinyal di logo sudah memudar pada bingkai tangkapan; animasi diteruskan dari kode lama |
| Masuk | Hampir sama | Ikon mata di kolom kata sandi (tetap ada demi fungsi); jarak atas bergantung status bar perangkat |
| Beranda | Sama | Angka dan tanggal dari data uji; tombol simpan di kartu tampil terisi bila beasiswa sudah tersimpan |
| Jelajah | Sama | Kolom cari tampil lebih lebar tulisannya; tautan Tersimpan ditambahkan di luar desain; chip D4 tambahan |
| Rekomendasi | Sama | Chip "Hitung ulang" tambahan di ujung baris chip |
| Detail | Hampir sama | Bagian Manfaat, Berkas wajib (dengan bilah progres dan centang), Rencana pendaftaran dan catatan kaki ada di luar desain karena datanya ada di API |
| Kalender | Hampir sama | Tombol "+ Tugas", legenda "Tugas pribadi" saat ada tugas, dan nama beasiswa di atas checklist ada di luar desain |
| Profil | Sebagian | Desain hanya menampilkan satu kartu Data utama; aplikasi menampilkan juga Domisili, Lainnya, tombol Ubah profil, menu Beasiswa Tersimpan, dan Keluar karena fungsinya diperlukan |
| Dokumen | Hampir sama | Pilihan jenis dokumen (chip) dan ikon hapus ada di luar desain karena API membutuhkannya |
| Chat | Sama | Tombol hapus riwayat di kepala dan teks sumber dari API ditambahkan |
| Pengaturan | Sama | Versi aplikasi tampil "..." pada tangkapan karena PackageInfo tidak tersedia di tes |
| Daftar | Tidak ada di desain | Memakai kerangka yang sama dengan Masuk |
| Beasiswa Tersimpan | Tidak ada di desain | Memakai kartu beasiswa baru |

## Catatan data

- Tombol chat melayang pada desain berada di layar Rekomendasi (M5), bukan Detail (M6); diterapkan di Rekomendasi.
- Kartu desain menampilkan satu kalimat alasan. API mengirim daftar alasan dan catatan kekurangan; semuanya ditampilkan sebagai baris teks kecil di bawah tenggat.
- Lencana status berkas Dokumen dipetakan dari `status_baca`: `selesai` menjadi Selesai, `gagal` menjadi Gagal, lainnya Menunggu.
- Daftar syarat Detail memakai `label` dan `nilai` dari API, sehingga teks seperti "IPK minimum 3.5" berbeda tipis dari "IPK minimal 3,50" pada desain.

## Menu bawah satu baris

`ItemMenuBawah` (`lib/core/widgets/item_menu_bawah.dart`) membungkus label dengan `FittedBox(scaleDown)`, `maxLines: 1`, `softWrap: false`, huruf 11 sp, dan skala huruf menu tetap dikunci 1.0. Diuji di `test/overflow_test.dart` pada lebar 320 dp dengan skala 1.0, 1.3, dan 2.0, dan dilihat pada tangkapan 320 dp skala 1.3.
