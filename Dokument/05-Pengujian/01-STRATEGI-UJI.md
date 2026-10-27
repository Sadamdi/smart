# Strategi Pengujian

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | WBS 5.1 sampai 5.5, `04-KEBUTUHAN-FR-NFR.md` |

## Tingkat uji

| Tingkat | Alat | Pemilik | Cakupan |
| --- | --- | --- | --- |
| Unit | pytest, flutter test, jest atau vitest | Pembuat kode | Servis, aturan kelayakan, validator, penguraian |
| Integrasi | pytest dengan basis data uji | Adam (5.1) | Rute sampai basis data, migrasi naik dan turun |
| Fungsional black box | Skenario manual terdokumentasi | Riska (5.2) | Alur mahasiswa dan admin di web dan Android |
| Kualitas rekomendasi | Skrip evaluasi dan gold set | Adam (5.3) | Precision@5, NDCG@5, ablasi |
| Akurasi ekstraksi | Contoh HTML berlabel | Devan dan Adam (5.3) | Field penting per sumber |
| Kinerja | Skrip beban kecil | Adam | NFR-SM-01 |
| UAT | Calon pengguna | Riska (6.2) | Kuesioner dan catatan penggunaan |

## Aturan uji

1. Uji tidak mengakses laman sumber sungguhan dan tidak memanggil layanan AI sungguhan (pakai tiruan atau rekaman respons).
2. Uji yang menghapus data hanya berjalan di proyek Supabase uji; pemeriksaan daftar putih host ada di pengaturan uji dan gagal keras bila host lain.
3. Endpoint data pengguna wajib diuji dengan dua pengguna berbeda: data pengguna A tidak boleh muncul untuk B.
4. Jalur gagal wajib: tanpa token, token kedaluwarsa, peran tidak berhak, masukan tidak valid, layanan AI mati.
5. Uji hijau bukan bukti fitur jalan. Sebelum melapor selesai, jalankan layanan dan coba alurnya (curl untuk API, peramban untuk web dengan tab Network dan Console).
6. Hasil uji yang gagal dilaporkan apa adanya.

## Kriteria lolos (gerbang 5.5)

| Butir | Syarat |
| --- | --- |
| Uji otomatis | Semua lolos di CI atau padanan lokal |
| Cakupan servis inti | Minimal 70% (auth, kelayakan, rekomendasi, validasi) |
| FR-SM-01 sampai 14 | Masing-masing punya minimal satu skenario lolos |
| NFR-SM-01 sampai 06 | Masing-masing terbukti atau pengecualian tercatat |
| Precision@5 | Minimal 0,8 pada gold set, atau analisis penyebab dan rencana perbaikan |
| Temuan kritis dan tinggi | Nol yang terbuka |

## Pelaporan

- Catatan uji unit: keluaran CI (WBS 5.1).
- Laporan black box: tabel skenario, langkah, hasil, bukti (WBS 5.2).
- Laporan evaluasi: angka evaluasi, gold set, ablasi, akurasi ekstraksi (WBS 5.3).
- Catatan perbaikan: temuan, tingkat, status (WBS 5.4).
- Ringkas ke `tools/build_kemajuan_pdf.py` supaya progres terbaca kelas.

## Templat skenario black box

| ID | FR | Prasyarat | Langkah | Hasil diharapkan | Hasil sebenarnya | Status | Bukti |
| --- | --- | --- | --- | --- | --- | --- | --- |
