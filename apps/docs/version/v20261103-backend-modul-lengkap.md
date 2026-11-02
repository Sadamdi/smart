# Backend modul lengkap: admin, rekomendasi, dokumen, kalender, notifikasi, chatbot

| Atribut | Nilai |
| --- | --- |
| **Versi** | v0.4.0 |
| **Tanggal** | 2026-11-03 |
| **Status** | In Progress |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F4, F5, F7, F8, F9; WBS 4.4 sampai 4.9 |
| **Tipe** | Feature |
| **Module** | backend |
| **Branch** | `adam/backend-modul-lengkap` |

## 1. Tujuan

Menyediakan seluruh endpoint yang dibutuhkan layar web dan mobile pada Figma.

## 2. Ringkasan

- Yang berubah: paket mesin rekomendasi, layanan admin, dokumen, interaksi dan kalender, notifikasi, chatbot; 13 endpoint admin dan mahasiswa baru; OpenAPI diekspor ke `Dokument/02-Backend/openapi.json`.
- Dampak: 68 uji backend lulus (27 baru), batas panjang baris ruff 125.
- Perubahan yang merusak: tidak.

## 3. Rencana

- [x] Mesin rekomendasi dan uji tabel keputusan
- [x] Admin, dokumen, interaksi, kalender, notifikasi, chatbot dengan uji integrasi
- [ ] Penyebaran ke server dan pengisian kunci AI
- [ ] Pemicu pemantauan dari panel admin, pengiriman email dan push
- [ ] LightGBM LambdaMART dan SHAP, model e5 asli
