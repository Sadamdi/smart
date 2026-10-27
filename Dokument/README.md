# Dokument: dokumen teknis untuk membangun SMART

Folder ini berisi dokumen teknis yang dipakai saat membangun aplikasi. Strukturnya meniru `D:\Adam_Project\koperasi\Dokument` dan disesuaikan dengan SMART.

## Bedanya dengan `docs/`

| Folder | Isi | Cara mengubah |
| --- | --- | --- |
| `docs/` | Dokumen manajemen proyek untuk kelas (proposal, charter, WBS, laporan, RAB, PPT) | Hasil generator. Ubah sumbernya di `tools/`, jangan diedit langsung |
| `Dokument/` (folder ini) | Dokumen teknis hidup untuk pembangunan (arsitektur, skema, kontrak API, rencana) | Ditulis dan dirawat tangan. Wajib diselaraskan ke kode |
| `apps/docs/` | Catatan pengerjaan per tugas: version, todo, features, flows | Diisi setiap tugas, sesuai `.cursor/rules/` |

Angka dan istilah di sini harus sama dengan dokumen di `docs/` (periode proyek, 11 tabel, tiga kategori kelayakan, batas toleransi). Bila berbeda, perbaiki salah satunya dan catat di `00-Cross-Context/03-ADR-KEPUTUSAN-ARSITEKTUR.md`.

## Isi

| Folder | Isi |
| --- | --- |
| `00-Cross-Context/` | Gambaran proyek, rencana pembangunan, keputusan arsitektur, kebutuhan fungsional dan nonfungsional |
| `01-Arsitektur/` | Arsitektur sistem, skema basis data, aturan kelayakan dan model, pemantauan sumber |
| `02-Backend/` | PRD backend, kontrak API |
| `03-Frontend/` | PRD web dan mobile, peta layar ke endpoint |
| `04-Infra/` | Lingkungan, rahasia, CI/CD, hosting |
| `05-Pengujian/` | Strategi uji, gold set, kriteria lolos |
| `Probis/` | Rujukan ke Dokumen Proses Bisnis (BP-SM-001) |

## Urutan membaca untuk agent

1. `../AGENTS.md` (aturan wajib) dan `../.cursor/rules/` (aturan pengerjaan).
2. `00-Cross-Context/01-PROJECT_OVERVIEW.md`, lalu `02-MASTER-PLAN-PEMBANGUNAN.md`.
3. Dokumen kategori yang menyangkut tugas yang dikerjakan.
4. `../apps/docs/` untuk jejak tugas sebelumnya.
