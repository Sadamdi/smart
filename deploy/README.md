# deploy: kerangka penempatan di server sendiri

Disiapkan lebih awal; **semua nilai server dan domain masih placeholder**. Isi setelah Adam memberikan detail server dan domain (WBS 6.1, `Dokument/04-Infra/03-HOSTING-DAN-PENEMPATAN.md`). Berkas berakhiran `.example` adalah templat, bukan konfigurasi yang dipakai.

Asumsi (belum dikonfirmasi): server Linux dengan systemd dan Nginx, tanpa Docker.

| Berkas | Fungsi |
| --- | --- |
| `nginx/smart.conf.example` | Reverse proxy dan TLS untuk web dan API |
| `systemd/smart-backend.service.example` | Menjalankan backend FastAPI |
| `systemd/smart-web.service.example` | Menjalankan web Next.js |
| `systemd/smart-crawler.service.example` | Menjalankan pemantau |

## Yang dibutuhkan dari Adam

- Alamat server, sistem operasi, akses (SSH), dan pengguna layanan
- Domain dan subdomain (usulan: `<DOMAIN>` untuk web, `api.<DOMAIN>` untuk API)
- Keputusan basis data produksi: Supabase atau PostgreSQL di server (dengan pgvector)
- Kunci layanan AI, SMTP, dan FCM produksi (hanya di `.env` server, tidak di repo)

## Aturan

- Tidak ada rahasia di berkas ini. `.env` produksi dibuat di server.
- `APP_ENV=prod` dan `DESTRUCTIVE_DB_HOSTS` kosong di server.
- Migrasi dijalankan sebagai langkah terpisah dengan cadangan lebih dulu.
