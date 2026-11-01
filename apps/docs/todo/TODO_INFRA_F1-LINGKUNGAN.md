# F1. Repositori dan lingkungan pengembangan

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F1, WBS 4.1 |
| **Module** | infra |
| **Priority** | P0 |
| **Progress** | 0% |
| **Last Updated** | 2026-10-26 |
| **Doc Reference** | `Dokument/04-Infra/01-LINGKUNGAN-DAN-RAHASIA.md` |

## Progress Summary

- Total tugas: 5
- Selesai: 0
- Sisa: 5

## Tugas

### T1. Repositori git
Kartu Kaneo: 4.1 `[INFRA] Repositori proyek`
- [x] O-01 diputuskan: monorepo, cabang `main` dan `testing` (host GitHub belum dipilih)
- [x] `git init -b main`, `.gitignore` (aturan rahasia)
- [ ] Komit awal dan cabang `testing` (menunggu identitas git dan keputusan isi repositori)
- [x] Repositori github.com/Sadamdi/smart, cabang main dan testing (27 Okt)
- [ ] Undang anggota tim, atur perlindungan cabang
Penerimaan: tiga anggota dapat clone dan membuat cabang.

### T2. Basis data lokal
- [ ] Adam membuat dua proyek Supabase (`smart-dev`, `smart-test`) dan mengaktifkan ekstensi `vector`; kata sandi dan connection string hanya di `.env`
- [ ] Panduan singkat di `Dokument/04-Infra/01-LINGKUNGAN-DAN-RAHASIA.md` bagian Supabase
Penerimaan: backend terhubung ke `smart-dev` dan `/api/v1/health/siap` menjawab siap.

### T3. Kerangka komponen
- [x] `apps/backend` (FastAPI, `GET /api/v1/health` dan `/health/siap`, Swagger `/docs`), `pyproject.toml`, ruff, pytest
- [x] `apps/web` (Next.js, halaman kosong), eslint, typecheck, vitest
- [x] `apps/mobile` (Flutter, layar kosong), `flutter analyze`, `flutter test`
- [x] `apps/crawler` dan `apps/ml` (paket Python, pytest)
- [x] `.env.example` per komponen (backend, crawler, web) sesuai `01-LINGKUNGAN-DAN-RAHASIA.md`; mobile memakai `--dart-define`
Penerimaan: tiap komponen lolos lint dan uji kosong.

### T4. CI dasar
- [x] `.github/workflows/ci.yml` ditulis (belum dijalankan; perlu remote GitHub)
Penerimaan: PR contoh menjalankan CI hijau.

### T5. Pelindung keamanan
- [x] `app/core/safety.py` (`pastikan_boleh_hapus`) dengan 6 uji; belum dipasang ke pengaturan uji basis data karena belum ada uji yang menyentuh basis data (dipasang di F2)
- [ ] Pra-komit pemindai rahasia (mis. gitleaks) bila memungkinkan
Penerimaan: uji gagal keras bila `DATABASE_URL` menunjuk host di luar daftar putih (diuji dengan host contoh prod). Fungsi sudah teruji; pemasangan ke fixture basis data di F2.

## Pertanyaan terbuka

O-01, O-02.

## Log eksekusi

| Tanggal | Tindakan | Hasil |
| --- | --- | --- |
