# Master Prompt Pembangunan

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-11-03 |
| **Status** | Berlaku |
| **Author** | Tim SMART |
| **Sumber bisnis** | `02-MASTER-PLAN-PEMBANGUNAN.md`, `06-RENCANA-PENYELESAIAN.md`, `03-Frontend/03-RENCANA-UIUX-DARI-FIGMA.md`, `01-Arsitektur/03-ATURAN-KELAYAKAN-DAN-MODEL.md` |

Prompt ini dipakai agent (atau anggota tim) pada tiap modul agar hasilnya seragam dan sesuai tumpukan teknologi dan jadwal. Fase yang jadwalnya sudah lewat dikerjakan lebih dulu.

## Prompt induk (berlaku untuk semua modul)

```text
Proyek SMART (Scholarship Monitoring and Recommendation Tool), Kelompok 8 UIN Malang.
Baca dulu: SMART/AGENTS.md, Dokument/README.md, .cursor/rules/*.mdc.

Tumpukan: backend FastAPI (Python 3.12, uv) dengan pola rute, servis, repositori; SQLAlchemy 2, Alembic,
PostgreSQL 17 Supabase dengan pgvector; web Next.js 16 TypeScript Tailwind; mobile Flutter, Dio, Riverpod;
mesin rekomendasi tiga lapis (kelayakan dengan toleransi, kemiripan embedding, skor gabungan);
layanan AI lewat endpoint OpenAI-compatible hanya untuk membaca dokumen dan chatbot.

Aturan: respons {success,data,meta}; bahasa antarmuka Indonesia; jangan memakai kata "pencocokan", persen
kecocokan, atau klaim pasti diterima; mahasiswa hanya melihat beasiswa terbit dengan tenggat belum lewat;
jangan menulis rahasia ke repo; commit Conventional Commits tanpa atribusi AI; satu cabang adam/<slug> per
modul, PR ke testing, lalu testing ke main.

Selesai bila: uji otomatis lulus (backend pytest, web vitest dan typecheck, mobile flutter test dan analyze),
lint hijau, entri apps/docs (version, todo, features) ditulis, CI hijau, dan dicoba di peramban atau emulator.
Sampaikan apa yang dikerjakan, apa yang diuji, dan apa yang belum.
```

## Prompt per modul

| Modul | Fase | Prompt tambahan |
| --- | --- | --- |
| Admin validasi dan sumber | F9 | Endpoint antrean, perbaiki, terbitkan, tolak, input manual, sumber, laporan. Hanya peran admin. Terbitkan menolak tenggat kurang dari tiga hari dan tautan resmi kosong. Uji peran, uji aturan terbit |
| Mesin rekomendasi | F5 | Paket `ml/eligibility` murni (tanpa basis data) dengan konfigurasi toleransi; embedding dapat diganti (antarmuka `Pengemas`), implementasi cadangan berbasis hashing agar berjalan di server 1 GB; servis rekomendasi menyimpan hasil, alasan, catatan kekurangan; uji tiap jenis syarat, tiga kategori, batas toleransi, urutan |
| Profil dan baca dokumen | F4 | Unggah (maks 5 MB, tipe PDF, DOCX, gambar), simpan ke penyimpanan lokal berkonfigurasi, ekstraksi teks, penguraian lewat layanan AI bila kunci ada, cadangan aturan bila tidak; hasil baca dapat dikoreksi; profil lengkap memicu hitung ulang |
| Interaksi, checklist, kalender, notifikasi | F8 | Simpan, rencana daftar, checklist dari berkas wajib, tugas pribadi, kalender rentang tanggal, notifikasi tenggat tanpa duplikat |
| Chatbot | F7 | Jawaban hanya dari data basis data (beasiswa dan profil), rujukan beasiswa, batas 2000 karakter, riwayat, pesan jelas saat layanan AI mati |
| Web | F6 | Ikuti `03-RENCANA-UIUX-DARI-FIGMA.md`; komponen dipakai ulang; klien API bertipe; keadaan memuat, kosong, galat |
| Mobile | F6 | Ikuti rencana UI/UX untuk layar mobile; Riverpod; token di penyimpanan aman; uji widget dan klien |

## Urutan dan jadwal

Urutan kerja: admin, rekomendasi, dokumen, interaksi dan kalender, chatbot, web, mobile, uji lintas modul, penyebaran. Jadwal rinci dan tenggatnya ada di `06-RENCANA-PENYELESAIAN.md`. Pekerjaan yang tenggatnya sudah lewat ditandai terlambat di laporan kemajuan dan dikerjakan lebih dulu.
