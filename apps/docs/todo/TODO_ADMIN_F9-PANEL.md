# F9. Panel admin dan validasi data

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F9, WBS 4.9, FR-SM-04 dan 14 |
| **Module** | backend, web |
| **Priority** | P1 |
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `apps/docs/features/08-admin/1. validasi-dan-sumber.md` |

## Progress Summary

- Total tugas: 4
- Selesai: 0
- Sisa: 4

## Tugas

### T1. Peran admin
Kartu Kaneo: 4.9 `[BE] Panel admin dan validasi data`
- [ ] Pemeriksaan `peran = admin` di semua rute `/admin`; pembuatan admin lewat prosedur aman
Penerimaan: mahasiswa menerima 403 di rute admin.

### T2. Antrean validasi
- [ ] `GET /admin/antrean-validasi`, perbaiki, terbitkan, tolak dengan alasan, input manual
Penerimaan: hanya beasiswa terbit dan bertenggat paling cepat tiga hari yang tampil ke mahasiswa.

### T3. Kelola sumber dan laporan
- [ ] CRUD sumber, pemicu putaran, `GET /admin/laporan`
Penerimaan: hasil putaran terakhir per sumber terlihat.

### T4. Layar admin di web
- [ ] Antrean validasi, kelola sumber, laporan sistem (menunggu desain)
Penerimaan: admin dapat memproses satu beasiswa dari ditandai sampai terbit.

## Pertanyaan terbuka

O-08.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
