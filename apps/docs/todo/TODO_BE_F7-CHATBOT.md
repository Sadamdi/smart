# F7. Chatbot dan penjelasan rekomendasi

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F7, WBS 4.7, FR-SM-11 |
| **Module** | backend |
| **Priority** | P1 |
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `apps/docs/features/06-chatbot/1. chatbot-berbasis-data.md` |

## Progress Summary

- Total tugas: 3
- Selesai: 0
- Sisa: 3

## Tugas

### T1. Pengambilan konteks
Kartu Kaneo: 4.7 `[BE] Fitur chatbot AI`
- [ ] Ambil beasiswa relevan dari basis data (pencarian vektor atau kata kunci) sebagai konteks
- [ ] Susun perintah sistem: jawab hanya dari konteks, tolak sopan bila tidak ada
Penerimaan: pertanyaan di luar data dijawab penolakan sopan.

### T2. Endpoint chat
- [ ] `POST /chat` (maksimal 2000 karakter), `GET` dan `DELETE /chat/riwayat`, batas laju, batas harian
- [ ] Tanpa nama dan tanggal lahir di payload; jawaban menyertakan rujukan beasiswa
Penerimaan: kuota habis atau layanan mati mengembalikan `UPSTREAM_UNAVAILABLE`.

### T3. Penjelasan rekomendasi
- [ ] Pertanyaan "mengapa beasiswa ini" dijawab dari `alasan` dan `catatan_kekurangan`, bukan dikarang
Penerimaan: jawaban sama dengan alasan yang tersimpan; tanpa klaim pasti diterima.

## Pertanyaan terbuka

O-09.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
