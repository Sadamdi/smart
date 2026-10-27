# PRD Web dan Mobile SMART

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft (menunggu revisi Figma, O-08) |
| **Author** | Tim SMART |
| **Sumber bisnis** | DP-SM-001 bagian 5, desain Figma tim UI/UX, catatan revisi desain |

## Tujuan

Mahasiswa dapat dari registrasi sampai menyimpan beasiswa dan menyiapkan berkas tanpa bantuan. Admin dapat memvalidasi data dan mengelola sumber.

## Platform

| Platform | Teknologi | Cakupan |
| --- | --- | --- |
| Web | Next.js | Seluruh layar mahasiswa dan panel admin |
| Mobile | Flutter (Android) | Layar mahasiswa: login, beranda, rekomendasi, jelajah, kalender dan checklist, notifikasi; layar lain menyusul |

## Prinsip tampilan (dari revisi desain)

1. Semua teks tampilan berbahasa Indonesia.
2. Gunakan istilah "Mesin Rekomendasi". Jangan memakai kata "pencocokan", persen kecocokan, atau klaim peluang lolos.
3. Dashboard tiga bagian, satu tombol utama per kartu.
4. Kontras teks memenuhi WCAG AA.
5. Komponen dipakai ulang dari pustaka komponen (Figma components dipetakan ke komponen kode).
6. Hasil rekomendasi selalu disertai alasan dan, untuk hampir memenuhi, catatan kekurangan.
7. Layanan AI tidak tersedia: tampilkan pesan yang jelas dan jalur manual; jangan membiarkan layar kosong.

## Fitur di luar rencana (jangan dibangun)

SSO dan SIAK, asisten esai, WhatsApp, sinkron kalender eksternal, profil ke kemitraan.

## Struktur kode

```text
apps/web/
  src/app/          rute (App Router)
  src/components/   komponen UI bersama
  src/features/     per fitur: komponen, hook, klien API
  src/lib/          klien API, autentikasi, util
  tests/

apps/mobile/
  lib/core/         klien API (Dio), penyimpanan token, tema
  lib/features/     per fitur: data, domain, presentasi
  test/
```

Klien API dibuat dari OpenAPI backend bila memungkinkan, atau ditulis tangan mengikuti `02-Backend/02-API-CONTRACT.md`. Tipe data tidak ditulis ulang berbeda di web dan mobile.

## Kriteria selesai per layar

- Sesuai desain Figma terbaru (atau catatan penyimpangan di entri version).
- Menangani keadaan kosong, memuat, galat, dan tidak ada koneksi.
- Dicoba di peramban atau emulator, termasuk tab Network dan Console tanpa galat.
- Teks Indonesia, kontras memadai, dapat dipakai di lebar ponsel.
- Setiap perubahan frontend lewat PR dan serah terima mengikuti `.cursor/rules/frontend-pr-handoff.mdc`.
