# F3. Pemantau beasiswa dan dataset

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F3, WBS 4.3, FR-SM-01 sampai 03 |
| **Module** | crawler |
| **Priority** | P0 |
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `apps/docs/features/03-beasiswa-pemantauan/1. pemantau-beasiswa.md` |

## Progress Summary

- Total tugas: 6
- Selesai: 0
- Sisa: 6

## Tugas

### T1. Kerangka crawler
Kartu Kaneo: 4.3 `[CRAWLER] Crawler terjadwal dan dataset beasiswa`
- [ ] Pemeriksa `robots.txt`, jeda per sumber, pencatat hasil putaran
- [ ] Skema keluaran sesuai tabel `beasiswa` dan `persyaratan`
Penerimaan: uji unit pemeriksa dan jeda lolos.

### T2. Sumber UIN Malang
- [ ] Simpan contoh HTML di `tests/fixtures/`
- [ ] Pola ekstraksi tabel HTML, normalisasi, uji dengan HTML tersimpan
Penerimaan: hasil ekstraksi cocok dengan label; hasil nol membuat uji gagal.

### T3. Validasi dan deduplikasi
- [ ] Validasi tenggat, tautan, jenjang; `sidik_isi` untuk duplikat dan deteksi perubahan
- [ ] Aturan terbit: tenggat paling cepat tiga hari; ambigu menjadi `menunggu_validasi` dengan alasan
Penerimaan: uji aturan terbit dan tandai.

### T4. Cadangan layanan AI
- [ ] Ekstraksi cadangan dari teks pengumuman; batas harian; penanganan kuota habis
Penerimaan: payload tidak memuat data pengguna; gagal tidak menghentikan putaran.

### T5. SatuBeasiswa dan sumber lain
- [ ] Putuskan O-06 (izin); implementasi bila izin ada
- [ ] Periksa sumber nomor 3 (Beasiswa Unggulan) dan perbarui `04-PEMANTAUAN-SUMBER.md`
- [ ] Input kurasi untuk Djarum dan sumber tautan keluar lewat tabel `sumber`
Penerimaan: minimal 30 beasiswa aktif tersimpan dengan tautan sumber.

### T6. Penjadwal dan laporan
- [ ] Penjadwal per sumber, ringkasan putaran untuk laporan admin
Penerimaan: putaran terjadwal berjalan tanpa campur tangan dan mencatat hasilnya.

## Pertanyaan terbuka

O-06.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
