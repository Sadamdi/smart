# Hosting dan Penempatan

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft (menunggu O-02) |
| **Author** | Tim SMART |
| **Sumber bisnis** | WBS 6.1, RAB (biaya langsung) |

Biaya hosting dan layanan AI tercantum di RAB dan bersumber dari `tools/build_sdm.py`. Dokumen ini hanya menetapkan susunan teknis; pilihan penyedia menunggu keputusan O-02.

## Kerangka di repositori

Templat Nginx dan systemd ada di `deploy/` (placeholder, menunggu detail server dan domain dari Adam). Keputusan 26 Okt 2026: produksi memakai server dan domain milik Adam.

## Susunan usulan (satu server Linux)

| Layanan | Cara jalan | Catatan |
| --- | --- | --- |
| Reverse proxy dan TLS | Nginx | Sertifikat Let's Encrypt |
| Backend | systemd, uvicorn 2 pekerja | Port internal 8000 |
| Web | systemd, `next start` | Port internal 3000 |
| Crawler | systemd, proses terpisah dengan penjadwal | Tidak membuka port |
| PostgreSQL dengan pgvector | Supabase atau PostgreSQL di server (menunggu keputusan) | Cadangan harian |
| Penyimpanan dokumen | Volume terenkripsi atau penyimpanan objek | Bukan di folder web |

## Cadangan

- `pg_dump` harian disimpan di luar mesin utama, simpan tujuh hari terakhir.
- Uji pemulihan satu kali sebelum UAT.

## Pemantauan dasar

- `/health` dan `/health/siap` diperiksa pemantau eksternal gratis.
- Log aplikasi terstruktur; jangan mencatat kata sandi, token, isi dokumen, atau isi pesan chatbot secara utuh.
- Laporan sistem untuk admin: hasil putaran pemantau, jumlah galat layanan AI, kuota.

## Penempatan (WBS 6.1)

Daftar periksa:

- [ ] Variabel lingkungan prod diisi dan berbeda dari dev dan test
- [ ] Migrasi dijalankan, data awal sumber diisi (`seed` aman diulang)
- [ ] TLS aktif, CORS hanya untuk domain web
- [ ] Cadangan terjadwal dan pemulihan teruji
- [ ] Pemantau pantau hidup
- [ ] Akun admin dibuat lewat prosedur aman (bukan kata sandi bawaan)
- [ ] Kunci layanan AI produksi terpasang dan batas harian diatur
- [ ] APK Android untuk UAT tersedia
