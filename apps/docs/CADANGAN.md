# Cadangan basis data

Basis data produksi (Supabase Postgres) dicadangkan setiap hari oleh `apps/backend/scripts/cadangan.py` di server tim.

| Hal | Nilai |
| --- | --- |
| Jadwal | cron root, 02.30 server (`30 2 * * *`) |
| Tujuan | `/opt/smart/cadangan/cadangan-YYYYMMDD-HHMM.json.gz` (izin 600, folder 700) |
| Isi | semua tabel; kolom vektor dilewati (dibangun ulang dari teks profil) |
| Penyimpanan | 14 berkas terbaru, sisanya dihapus otomatis |
| Log | `/opt/smart/cadangan.log` |

Menjalankan manual di server:

```bash
cd /opt/smart/backend && set -a && . /opt/smart/backend.env && set +a && /opt/smart/venv/bin/python -m scripts.cadangan
```

Memulihkan: berkas berupa JSON per tabel; sisipkan kembali dengan skrip sekali pakai sesuai kebutuhan (urutan tabel mengikuti kunci asing).
Cadangan ini berada di server yang sama dengan backend, jadi salin berkala ke tempat lain (misalnya unduh dengan `scp`).
