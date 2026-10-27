# Gambaran Proyek SMART

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Active |
| **Author** | Tim SMART |
| **Sumber bisnis** | Laporan Inisiasi bagian 5, Dokumen Perancangan DP-SM-001 |

## Produk

SMART (*Scholarship Monitoring and Recommendation Tool*) memantau laman beasiswa resmi, menyimpannya sebagai data terstruktur, lalu merekomendasikan beasiswa kepada mahasiswa beserta alasan dan catatan kekurangan syarat. Sistem tidak pernah menyatakan mahasiswa pasti diterima atau ditolak.

## Pengguna

| Peran | Kebutuhan utama |
| --- | --- |
| Mahasiswa | Mengisi profil, mengunggah CV dan sertifikat, melihat rekomendasi tiga kategori, menyimpan beasiswa, mengisi checklist berkas, bertanya ke chatbot, menerima pengingat tenggat |
| Admin | Memeriksa data yang ditandai meragukan, mengelola sumber, melihat laporan sistem |

## Komponen

| Komponen | Folder | Teknologi | Port atau cara jalan |
| --- | --- | --- | --- |
| Backend API | `apps/backend` | FastAPI (Python), SQLAlchemy, Alembic | 8000 |
| Pemantau beasiswa | `apps/crawler` | Crawl4AI, penjadwal | Proses terpisah, menulis ke basis data |
| Mesin rekomendasi | `apps/ml` | sentence embedding, LightGBM, SHAP | Paket Python yang dipakai backend |
| Web | `apps/web` | Next.js | 3000 |
| Mobile | `apps/mobile` | Flutter | Android |
| Basis data | (layanan) | PostgreSQL dengan pgvector | 5432 |

## Batas pengerjaan

SMART bukan sistem pendaftaran beasiswa, tidak memverifikasi keaslian dokumen, tidak memakai perangkat keras, dan tidak melewati login, captcha, atau batas laju laman sumber. Tidak memakai Simple Additive Weighting maupun istilah "pencocokan".

## Peta sumber kebenaran

| Pertanyaan | Baca |
| --- | --- |
| Proses bisnis dan aturan bisnis | `docs/Dokumen Proses Bisnis SMART (BP-SM-001).pdf` (kode M-SM, BR-SM, FR-SM) |
| Tabel dan kolom | `01-Arsitektur/02-SKEMA-DATABASE.md` |
| Kontrak endpoint | `02-Backend/02-API-CONTRACT.md`, lalu `openapi.json` setelah backend ada |
| Aturan kelayakan | `01-Arsitektur/03-ATURAN-KELAYAKAN-DAN-MODEL.md` |
| Tampilan | desain Figma tim UI/UX (tautan ada di panduan internal tim) dan `03-Frontend/02-PETA-LAYAR-KE-ENDPOINT.md` |
| Tugas dan tenggat | Kaneo (project SMT) dan `tools/build_jadwal.py` |
