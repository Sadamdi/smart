# CI/CD, Cabang, dan Alur PR

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft (menunggu O-01) |
| **Author** | Tim SMART |
| **Sumber bisnis** | Pola koperasi (alur PR) disesuaikan dengan tim tiga orang |

## Cabang

| Cabang | Fungsi | Aturan |
| --- | --- | --- |
| main | Rilis | Hanya lewat PR dari `testing`; merge ke `main` hanya dengan konfirmasi Adam |
| testing | Integrasi | Tujuan PR harian |
| `<inisial>/<slug>` | Kerja per tugas | Mis. `adam/auth-login`, `riska/layar-jelajah`, `devan/crawler-uin` |

Dilarang push langsung ke `main` dan `testing`. Dilarang `--no-verify`.

## Komit

- Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`.
- Subjek di bawah 72 karakter, satu perhatian per komit, pisahkan komit per komponen.
- Sebut nomor tugas Kaneo di badan komit.
- Tanpa baris atribusi AI di komit maupun deskripsi PR (aturan pengguna untuk repositori ini).

## Alur PR

1. Buat entri plan di `apps/docs/version/` sebelum kode.
2. Kerjakan di cabang tugas, jalankan padanan CI lokal (lihat bawah).
3. Buka PR ke `testing`. Judul `[modul] nama fitur`. Isi: ringkasan, cara uji, dampak lintas komponen, tautan tugas Kaneo.
4. Minimal satu anggota lain meninjau. Pemilik PR menangani semua komentar.
5. Setelah semua pemeriksaan hijau, merge. Perbarui entri version menjadi `Released` dan geser kartu Kaneo ke Done.
6. Rilis: PR `testing` ke `main` dengan konfirmasi Adam.

PR yang mengubah antarmuka menyertakan pesan serah terima seperti di `.cursor/rules/frontend-pr-handoff.mdc`.

## Padanan CI lokal (sebelum push)

| Komponen | Perintah |
| --- | --- |
| backend | `uv run ruff check .`, `uv run ruff format --check .`, `uv run pytest -q` (dari `apps/backend`; Python 3.12 lewat uv) |
| crawler | `uv run ruff check .`, `uv run pytest -q` (tanpa akses jaringan) |
| ml | `uv run ruff check .`, `uv run pytest -q`, skrip evaluasi bila model atau konfigurasi berubah |
| web | `npm run lint`, `npm run typecheck`, `npm test`, `npm run build` |
| mobile | `flutter analyze`, `flutter test` |

## Alur CI di host repositori

Satu alur per komponen yang berjalan bila folder komponen itu berubah: pasang dependensi, lint, uji, build. Basis data uji disediakan sebagai layanan di alur CI. Rahasia hanya dari penyimpan rahasia host.

Bila minit CI di host habis atau CI tidak berjalan: jalankan padanan lokal penuh pada HEAD cabang, tinjau diff sendiri terhadap `testing`, tulis komentar "Review manual" di PR berisi perintah dan hasilnya, lalu merge secara manual.

## Migrasi pada rilis

Migrasi Alembic dijalankan sebagai langkah terpisah sebelum layanan baru dinaikkan, dengan cadangan sebelumnya. Rilis yang mengubah skema dicatat di entri version beserta cara mundur.
