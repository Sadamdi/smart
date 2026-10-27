# apps/ : kode aplikasi SMART

Belum ada kode. Rencana pembangunan bertahap (fase F0 sampai F11), kontrak, dan aturan kerja ada di `../Dokument/00-Cross-Context/02-MASTER-PLAN-PEMBANGUNAN.md`; jejak pengerjaan per tugas di `docs/` (version, todo, features, flows); aturan agent di `../.cursor/rules/`. Pengembangan dimulai pada tahap Implementasi (paket kerja 4.1, 19 Oktober 2026), setelah rancangan (tahap 3) disetujui. Struktur di bawah adalah rencana; ubah lewat keputusan yang dicatat di `../agents/KEPUTUSAN.md`.

## Rencana struktur

```
apps/
├── backend/        FastAPI (Python): API REST, autentikasi, profil, rekomendasi, chatbot, kalender, notifikasi
│   ├── app/        api/ (rute), services/ (logika), repositories/ (akses data), models/, schemas/, core/ (konfigurasi)
│   ├── migrations/ Alembic
│   ├── tests/      pytest
│   └── .env.example
├── crawler/        Pemantauan laman resmi (Crawl4AI)
│   ├── sources/    satu berkas per sumber: URL, pola CSS/XPath, frekuensi
│   ├── extract/    pengekstrak, normalisasi ke skema baku, cadangan LLM
│   ├── validate/   aturan validasi dan deduplikasi
│   └── tests/      uji dengan contoh HTML tersimpan
├── ml/             Mesin rekomendasi
│   ├── eligibility/  penilaian kelayakan dengan toleransi
│   ├── embedding/    all-indo-e5-small-v4, vektor di pgvector
│   ├── ranking/      skor gabungan 0,6 / 0,4, lalu LightGBM LambdaMART dan SHAP
│   ├── eval/         gold set, Precision@5, NDCG@5, ablasi
│   └── tests/
├── web/            Next.js: halaman mahasiswa dan panel admin
└── mobile/         Flutter: aplikasi mahasiswa
```

Modul sistem (M1 sampai M5) dan paket kerja WBS yang menjadi dasarnya ada di `../docs/Proposal Proyek SMART.docx` bab 2 dan 4. Pembagian (dikonfirmasi Adam 27 Oktober 2026): Adam backend, mobile, mesin rekomendasi, dan chatbot; Riska UI/UX dan frontend web; Devan data (pemantauan beasiswa, pengisian dan validasi data). M1 Devan; M2 Adam (pembacaan CV) dan Riska (formulir); M3 dan M4 Adam; M5 Riska (web dan panel admin), Adam (mobile), Devan (validasi data).

## Menjalankan (keadaan 26 Oktober 2026)

```
backend   cd apps/backend && uv sync --python 3.12 && uv run uvicorn app.main:app --reload --port 8000   (Swagger di /docs)
web       cd apps/web && npm install && npm run dev
mobile    cd apps/mobile && flutter pub get && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
crawler   cd apps/crawler && uv sync --python 3.12 && uv run pytest
ml        cd apps/ml && uv sync --python 3.12 && uv run pytest
```

Salin `.env.example` menjadi `.env` di tiap komponen. Basis data memakai Supabase (tanpa Docker); lihat `../Dokument/04-Infra/01-LINGKUNGAN-DAN-RAHASIA.md`. Kerangka penempatan server ada di `../deploy/`.

## Aturan pengembangan

1. **Satu tugas Kaneo per fitur atau perbaikan**, judul berawalan `[BE]`, `[FE]`, `[ML]`, `[CRAWLER]`. Pindahkan status saat mulai dan selesai (`../agents/KANEO.md`). Pesan commit menyebut nomor tugas.
2. **Commit** memakai Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`), subjek di bawah 72 karakter, satu perhatian per commit. Tanpa baris atribusi AI.
3. **Lapisan backend**: rute, servis, lalu repositori. Rute tidak boleh memanggil basis data langsung.
4. **Basis data**: PostgreSQL dengan pgvector. Pisahkan database pengembangan, uji, dan produksi. Jangan menjalankan uji atau migrasi yang menghapus data ke basis data yang dipakai bersama. Skrip `seed` hanya membuat atau memperbarui; skrip `cleanup` terpisah dan menolak jalan kecuali `APP_ENV` dan daftar putih host terpenuhi (`Dokument/04-Infra/01-LINGKUNGAN-DAN-RAHASIA.md`).
5. **Rahasia**: `.env` tidak masuk repo; sediakan `.env.example`. Kunci layanan AI, token, dan kredensial tidak boleh ada di kode atau dokumen.
6. **Layanan AI** hanya untuk membaca dokumen, ekstraksi cadangan, dan chatbot dari data basis data. Tidak menentukan peringkat. Sertakan batas percakapan dan penanganan kuota habis.
7. **Crawler** hanya mengambil laman publik resmi yang terdaftar, menghormati `robots.txt`, dan tidak mengambil laman yang memerlukan login. Data yang ambigu tidak ditebak, tetapi ditandai untuk admin.
8. **Uji**: setiap modul punya uji otomatis. Kualitas rekomendasi diukur dengan gold set (Precision@5 minimal 0,8 sebagai target proyek). Hasil pengujian dicatat untuk laporan pengujian (tahap 5).
9. **Dokumentasi**: perubahan perilaku atau API dicatat di `docs/` atau README modul, dan dokumen proyek yang terdampak diperbarui lewat `tools/` (angka dan istilah harus tetap sama antardokumen).
10. **Sebelum lapor selesai**: jalankan uji dan pemeriksaan gaya kode modul itu, coba alur utama dari awal sampai akhir, lalu laporkan hasil apa adanya, termasuk yang gagal.

## Batas pengerjaan

SMART bukan sistem pendaftaran beasiswa, tidak memverifikasi keaslian dokumen, tidak memakai perangkat keras, dan tidak pernah menyatakan mahasiswa pasti diterima atau ditolak.
