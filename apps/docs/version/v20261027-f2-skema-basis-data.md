# F2: skema basis data (model, migrasi, seed)

| Atribut | Nilai |
| --- | --- |
| **Versi** | v0.2.0 |
| **Tanggal** | 2026-10-27 |
| **Status** | In Progress |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F2, WBS 4.2; ERD final 27 Oktober 2026 |
| **Tipe** | Migration |
| **Module** | backend |
| **Branch** | `adam/skema-basis-data` |
| **PR / Commit** | (diisi saat PR dibuka) |
| **Last Updated** | 2026-10-27 |

## 1. Tujuan

Mewujudkan ERD final (13 tabel) sebagai model dan migrasi sehingga autentikasi, profil, dan daftar beasiswa dapat dibangun di atasnya.

## 2. Ringkasan

- Yang berubah: model SQLAlchemy untuk 13 tabel, migrasi Alembic `0001_skema_awal` (ekstensi `vector`, indeks HNSW pada vektor beasiswa, batasan unik rekomendasi dan pengingat), skrip `seed_sumber` (sembilan sumber, upsert) dan `cleanup` (dijaga daftar putih host), uji skema tanpa basis data. CI web memakai `next typegen` sebelum typecheck.
- Dampak: belum ada endpoint baru.
- Perubahan yang merusak: tidak.

## 3. Rencana

- [x] Model dan migrasi
- [x] Seed dan cleanup
- [x] Uji skema tanpa basis data (13 tabel, ekstensi vector, indeks, batasan pengingat)
- [x] Migrasi naik dijalankan di proyek Supabase SMART (dipakai sebagai dev)
- [ ] Migrasi naik dan turun di proyek Supabase uji terpisah
- [ ] Seed sumber (belum dijalankan)

## 4. File yang diubah

| File | Tipe | Ringkasan |
| --- | --- | --- |
| `apps/backend/app/models/**` | add | Model 13 tabel |
| `apps/backend/migrations/**`, `alembic.ini` | add | Alembic dan migrasi 0001 |
| `apps/backend/scripts/**` | add | seed_sumber, cleanup |
| `apps/backend/tests/test_skema.py` | add | Uji skema |
| `apps/web/package.json` | update | typecheck memakai next typegen |
| `Dokument/**`, `apps/docs/**` | update | 13 tabel, keputusan 27 Oktober |

## 6. Verifikasi

| Pemeriksaan | Langkah | Hasil |
| --- | --- | --- |
| Lint dan uji backend | `uv run ruff check .`, `ruff format --check .`, `pytest -q` | Lolos, 13 uji |
| SQL migrasi | `alembic upgrade head --sql` | 13 tabel, ekstensi vector, indeks HNSW |
| Basis data nyata | `alembic upgrade head` di Supabase SMART (basis data kosong sebelumnya) | Lolos: 13 tabel, `alembic_version` = 0001, ekstensi vector terpasang, indeks `ix_beasiswa_vektor` (hnsw) ada, kolom vector pada `beasiswa` dan `pengguna` |
| Pengaman hapus data | `pytest` | Lolos, 14 uji, termasuk pembeda proyek lewat nama pengguna pada pooler bersama |

## 7. Cara mundur

`alembic downgrade base` pada basis data dev atau uji. Jangan di produksi tanpa izin dan cadangan.
