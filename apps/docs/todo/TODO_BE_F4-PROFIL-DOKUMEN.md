# F4. Profil dan pembacaan CV

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F4, WBS 4.4, FR-SM-05 dan 06 |
| **Module** | backend |
| **Priority** | P1 |
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `apps/docs/features/02-profil-dokumen/1. unggah-dan-baca-dokumen.md` |

## Progress Summary

- Total tugas: 4
- Selesai: 0
- Sisa: 4

## Tugas

### T1. Unggah dokumen
Kartu Kaneo: 4.4 `[BE] Fitur profil dan ekstraksi CV`
- [ ] `POST /me/dokumen` (PDF, DOCX, JPG, PNG, maksimal 5 MB), validasi tipe isi, bukan hanya ekstensi
- [ ] Penyimpanan terenkripsi; tautan unduh bertanda tangan dan berumur pendek
Penerimaan: berkas pengguna A tidak dapat diakses pengguna B.

### T2. Pembacaan oleh layanan AI
- [ ] Pembersih payload (tanpa nama dan tanggal lahir), klien layanan AI, batas harian
- [ ] Keluaran terstruktur ke `hasil_baca`; `status_baca` menunggu, selesai, gagal
Penerimaan: uji otomatis atas payload; layanan mati menghasilkan `gagal` dan pengguna dapat mengisi manual.

### T3. Koreksi hasil baca
- [ ] `PUT /me/dokumen/{id}/hasil-baca`, terapkan ke profil dengan persetujuan pengguna
Penerimaan: profil hanya berubah setelah pengguna menyetujui.

### T4. Vektor profil
- [ ] Hitung `vektor_profil` saat profil berubah (memakai paket ml)
Penerimaan: profil berubah memicu hitung ulang.

## Pertanyaan terbuka

O-05, O-09.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
