# F1: kerangka komponen, pengaman basis data, CI, dan kerangka penempatan

| Atribut | Nilai |
| --- | --- |
| **Versi** | v0.1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | In Progress |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F1, WBS 4.1; keputusan Adam 26 Okt 2026 (monorepo, Supabase tanpa Docker, server dan domain milik Adam) |
| **Tipe** | Config |
| **Module** | infra, backend, crawler, ml, web, mobile |
| **Branch** | main (belum ada komit) |
| **PR / Commit** | (belum ada) |
| **Last Updated** | 2026-10-26 |

## 1. Tujuan

Menyiapkan kerangka yang dapat dijalankan dan diuji untuk setiap komponen sebelum fitur dibangun, termasuk Swagger, pengaman penghapusan data, CI, dan kerangka penempatan.

## 2. Ringkasan

- Yang berubah: repositori git lokal (`main`), kerangka `apps/backend` (FastAPI, Swagger di `/docs`, respons dan galat baku, `/api/v1/health`, `/api/v1/health/siap`, pengaman `pastikan_boleh_hapus`), `apps/web` (Next.js 16, Tailwind, TanStack Query, Zod, React Hook Form, Vitest, klien API), `apps/mobile` (Flutter Android, Dio, Riverpod, go_router, secure storage, klien API), `apps/crawler` dan `apps/ml` (paket Python dengan satu uji), `.github/workflows/ci.yml`, `deploy/` (templat Nginx dan systemd), dokumen yang menyesuaikan Supabase.
- Dampak: belum ada fitur pengguna.
- Perubahan yang merusak: tidak.

## 3. Rencana

- [x] Git lokal, cabang `main`
- [ ] Cabang `testing` dan komit awal (menunggu identitas git dan keputusan isi repositori)
- [ ] Dua proyek Supabase dan ekstensi `vector` (Adam)
- [ ] Remote GitHub dan perlindungan cabang (menunggu keputusan host)
- [x] Kerangka lima komponen lolos lint dan uji
- [x] CI ditulis (belum pernah dijalankan di host)
- [x] Kerangka penempatan server (placeholder)
- [ ] Kartu Kaneo per tugas pembangunan

## 4. File yang diubah

| File | Tipe | Ringkasan |
| --- | --- | --- |
| `apps/backend/**` | add | FastAPI, konfigurasi, galat, pengaman, health, uji |
| `apps/web/**` | add | Next.js dan klien API, uji |
| `apps/mobile/**` | add | Flutter Android dan klien API, uji |
| `apps/crawler/**`, `apps/ml/**` | add | Paket Python dan uji awal |
| `.github/workflows/ci.yml` | add | CI per komponen dan pemindai rahasia |
| `deploy/**` | add | Templat server |
| `Dokument/**`, `.cursor/rules/**` | update | Supabase tanpa Docker, daftar putih host |

## 6. Verifikasi

| Pemeriksaan | Langkah | Hasil |
| --- | --- | --- |
| Backend | `uv run ruff check .`, `ruff format --check .`, `pytest -q` | Lolos, 10 uji |
| Backend jalan | uvicorn di port 8000; GET `/api/v1/health`, `/health/siap`, `/docs`, jalur tidak ada | 200 hidup; 503 UPSTREAM_UNAVAILABLE karena DATABASE_URL kosong (sesuai rancangan); 200; 404 format baku |
| Web | `npm run lint`, `typecheck`, `test`, `build` | Lolos, 3 uji |
| Crawler, ml | `ruff check`, `pytest` | Lolos, 2 dan 1 uji |
| Mobile | `flutter analyze`, `flutter test` | Lolos, 3 uji |
| Belum diverifikasi | Sambungan ke Supabase, CI di GitHub, jalan di emulator atau peramban | Menunggu proyek Supabase dan remote |

## 7. Cara mundur

Hapus folder komponen dan `.git`; tidak ada data produksi.
