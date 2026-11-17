# Rencana mode luring dan penyimpanan lokal (18 November 2026)

Dasar: permintaan pengguna agar data bisa disimpan lokal, algoritma bisa jalan di perangkat, dan chatbot punya mode luring dengan model ringan yang diunduh bila pengguna mau. Pemeriksaan dokumen proyek (`Dokument/`, `apps/docs/`, `agents/`) menemukan bahwa belum ada rencana luring sebelumnya; hanya catatan huruf yang di-cache. Dokumen ini rencana awalnya.

## Yang sudah ada (tahap 1, selesai 18 November 2026)

- Mobile menyimpan respons GET terakhir di folder aplikasi (`lib/core/cache_lokal.dart`). Bila jaringan putus, layar menampilkan data terakhir dan muncul tanda "Mode luring: menampilkan data terakhir". Cache dikosongkan saat keluar atau sesi berakhir. Hanya baca; tulis (simpan, centang, ubah profil) tetap butuh jaringan.
- Simpan beasiswa bersifat optimis: tombol langsung berubah, server menyusul di belakang.

## Tahap 2: algoritma di perangkat (bertahap)

| Bagian | Bisa lokal | Catatan |
| --- | --- | --- |
| Skor kelayakan (aturan) | Ya | Aturan murni (`kelayakan.py`), mudah dipindah ke Dart. Perlu data beasiswa dan profil di perangkat |
| Estimasi peluang | Ya | Tabel statistik seleksi (JSON kecil) dan rumus di `peluang.py`; dapat dibundel dan diperbarui lewat sinkronisasi |
| Kemiripan embedding | Sulit | Butuh model embedding; di perangkat memakan unduhan ratusan MB. Pakai hasil server yang sudah dicache |
| Pemeringkatan LightGBM | Tidak perlu | Hasil server sudah cukup; di perangkat cukup urut menurut estimasi peluang |
| Hitung ulang setelah ubah profil | Sebagian | Skor kelayakan dan peluang dapat dihitung lokal seketika; embedding menunggu server |

Urutan kerja: sinkronkan daftar beasiswa terbit ke basis data lokal (SQLite), pindahkan aturan kelayakan dan peluang ke Dart, uji kesamaan hasil dengan server memakai gold set, lalu jadikan hasil lokal sebagai tampilan awal dan hasil server sebagai pembaruan.

## Tahap 3: chatbot luring

Pilihan, dari yang paling ringan:

1. **Jawaban berbasis data lokal tanpa model** (disarankan lebih dulu): maksud pertanyaan dikenali dengan aturan (tenggat, syarat, peluang, dokumen), jawaban disusun dari data beasiswa yang sudah dicache. Tanpa unduhan, tanpa kuota. Cakupan terbatas pada pertanyaan yang bisa dijawab data.
2. **Model bahasa kecil di perangkat, diunduh bila pengguna memilih**: kelas 0,5 sampai 1 miliar parameter terkuantisasi (kira-kira 400 sampai 700 MB). Di Android lewat pustaka inferensi seperti MediaPipe LLM Inference (paket Flutter pembungkusnya tersedia), di web lewat WebGPU dengan pustaka seperti WebLLM atau transformers.js. Pemanggilan alat (tool calling) tidak asli di model sekecil itu; dibuat dengan format keluaran terstruktur dan pencarian ke data lokal (RAG sederhana). Ada pengaturan "Unduh model luring", ukuran ditampilkan, hanya lewat Wi-Fi secara bawaan.
3. Chatbot daring (Gemini) tetap utama bila ada jaringan; mode luring hanya cadangan.

Risiko: kualitas jawaban model kecil dalam bahasa Indonesia rendah, perangkat lama lambat, ruang penyimpanan, dan masa pakai baterai. Karena itu opsi 2 hanya dikerjakan setelah opsi 1 dan diukur di HP nyata.

## Keputusan yang perlu dari pengguna

- Apakah opsi 1 cukup untuk UAS Mobile Programming, atau opsi 2 diperlukan sebagai nilai tambah.
- Apakah tulis luring (antrean simpan dan centang yang dikirim saat online) dibutuhkan. Belum dikerjakan.
