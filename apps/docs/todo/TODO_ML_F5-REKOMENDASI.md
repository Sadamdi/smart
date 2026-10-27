# F5. Mesin rekomendasi

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F5, WBS 4.5, FR-SM-07 sampai 09 |
| **Module** | ml |
| **Priority** | P0 |
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `apps/docs/features/04-rekomendasi/1. mesin-rekomendasi.md` |

## Progress Summary

- Total tugas: 6
- Selesai: 0
- Sisa: 6

## Tugas

### T1. Penilai kelayakan
Kartu Kaneo: 4.5 `[ML] Fitur rekomendasi berperingkat`
- [ ] Konfigurasi toleransi (berkas terpisah), penilai per jenis syarat, kategori tiga tingkat
- [ ] Tabel uji keputusan: tiap jenis syarat dengan nilai di batas dan di luar batas
Penerimaan: semua baris tabel keputusan lolos.

### T2. Embedding dan pgvector
- [ ] Muat all-indo-e5-small-v4, hitung vektor beasiswa dan profil, simpan ke pgvector, indeks vektor
Penerimaan: kemiripan 1000 beasiswa dihitung dalam satu kueri.

### T3. Skor gabungan, alasan, catatan
- [ ] `0,6 x kelayakan + 0,4 x kemiripan`; alasan dan catatan kekurangan sebagai teks yang aman
Penerimaan: tidak ada klaim pasti diterima dan tidak ada persen peluang.

### T4. Endpoint rekomendasi
- [ ] `GET /rekomendasi`, `POST /rekomendasi/hitung-ulang`, simpan ke tabel `rekomendasi`
Penerimaan: 1000 beasiswa dalam 3 detik; tetap jalan saat layanan AI mati.

### T5. Gold set dan evaluasi
- [ ] Putuskan O-07; buat gold set; skrip Precision@5, NDCG@5, ablasi
Penerimaan: Precision@5 minimal 0,8 atau analisis penyebab.

### T6. Pemeringkatan lanjutan
- [ ] LightGBM LambdaMART dan SHAP setelah ada data interaksi; fitur dari tabel `interaksi`
Penerimaan: dapat dimatikan lewat konfigurasi; hasil dibandingkan dengan skor gabungan.

## Pertanyaan terbuka

O-05, O-07.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
