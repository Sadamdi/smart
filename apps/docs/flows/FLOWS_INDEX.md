# Indeks Alur

Diagram alur eksekusi lintas fitur (Mermaid dengan fallback teks). Alur per fitur ada di bagian Alur kerja tiap dokumen fitur; berkas di folder ini untuk alur yang melintasi beberapa fitur.

| Alur | Berkas | Status | Melibatkan |
| --- | --- | --- | --- |
| Dari laman sumber sampai rekomendasi tampil | `ALL-FLOWS.md` | Planned | crawler, backend, ml, web, mobile |
| Pembacaan dokumen sampai profil | `ALL-FLOWS.md` | Planned | backend, layanan AI |
| Pengingat tenggat | `ALL-FLOWS.md` | Planned | backend, FCM, SMTP |

Gambaran awal sudah ada di `Dokument/01-Arsitektur/01-ARSITEKTUR-OVERVIEW.md` dan `04-PEMANTAUAN-SUMBER.md`. `ALL-FLOWS.md` dibuat saat F5 selesai, ketika alur ujung ke ujung dapat dicoba.
