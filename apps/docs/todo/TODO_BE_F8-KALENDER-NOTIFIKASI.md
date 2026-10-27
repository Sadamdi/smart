# F8. Kalender, checklist, dan notifikasi

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F8, WBS 4.8, FR-SM-12 dan 13 |
| **Module** | backend, web, mobile |
| **Priority** | P1 |
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `apps/docs/features/05-interaksi-checklist/1. tersimpan-checklist-kalender.md` |

## Progress Summary

- Total tugas: 5
- Selesai: 0
- Sisa: 5

## Tugas

### T1. Interaksi dan tersimpan
Kartu Kaneo: 4.8 `[BE] Kalender, checklist, dan notifikasi`
- [ ] `POST /beasiswa/{id}/interaksi`, `GET /me/tersimpan`, status rencana daftar
Penerimaan: simpan dan batal simpan idempoten.

### T2. Checklist dan tugas pribadi
- [ ] `GET /me/checklist`, `PUT /me/checklist/{id}`, `/me/tugas` (menunggu O-03)
Penerimaan: pengguna A tidak dapat mencentang berkas milik B.

### T3. Kalender
- [ ] `GET /me/kalender` rentang tanggal: tenggat tersimpan dan tugas
Penerimaan: zona waktu WIB tampil benar di klien.

### T4. Pengirim notifikasi
- [ ] Penjadwal pengingat tenggat (mis. 7, 3, 1 hari) dan beasiswa baru; surel (SMTP) dan push (FCM)
- [ ] Unik per pengguna, beasiswa, jenis, kanal, tanggal acuan agar tidak ganda; hormati preferensi
- [ ] `POST /me/perangkat` (menunggu O-04)
Penerimaan: pengingat tidak terkirim dua kali walau penjadwal berjalan ulang.

### T5. Layar klien
- [ ] Beasiswa Tersimpan, Kalender dan Checklist, Notifikasi, Pengaturan
Penerimaan: keadaan kosong dan galat ditangani; Android menerima push.

## Pertanyaan terbuka

O-03, O-04.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
