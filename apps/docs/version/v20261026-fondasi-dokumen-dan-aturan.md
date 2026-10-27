# Fondasi dokumen teknis dan aturan kerja (F0)

| Atribut | Nilai |
| --- | --- |
| **Versi** | v0.0.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Released |
| **Author** | Tim SMART |
| **Sumber bisnis** | Permintaan Adam 26 Oktober 2026: dokumen arsitektur dan aturan sebelum membangun aplikasi, mengikuti struktur proyek koperasi dan Kelilink |
| **Tipe** | Docs |
| **Module** | docs |
| **Branch** | (belum ada repositori git) |
| **PR / Commit** | (belum ada) |
| **Last Updated** | 2026-10-26 |

## 1. Tujuan

Menyiapkan kontrak (arsitektur, skema, API, aturan kelayakan) dan aturan kerja sebelum kode ditulis, supaya pembangunan dapat dicicil per fase dan dikerjakan agent atau anggota tim tanpa menebak.

## 2. Ringkasan

- Yang berubah: ditambah `Dokument/` (enam kategori), `.cursor/rules/` (delapan aturan), `apps/docs/` (version, todo, features, flows), `scripts/verify-frontmatter.ps1`, kerangka README per komponen di `apps/`.
- Dampak: tidak ada perubahan pada dokumen kelas di `docs/`.
- Perubahan yang merusak: tidak.

## 4. File yang diubah

| File | Tipe | Ringkasan |
| --- | --- | --- |
| `Dokument/**` | add | Dokumen teknis |
| `.cursor/rules/*.mdc` | add | Aturan kerja |
| `apps/docs/**` | add | Indeks, templat, TODO per fase |
| `apps/*/README.md` | add | Kerangka komponen |
| `scripts/verify-frontmatter.ps1` | add | Pemeriksa tabel atribut |
| `AGENTS.md`, `CLAUDE.md`, `apps/README.md`, `agents/*` | update | Rujukan ke struktur baru |

## 6. Verifikasi

| Pemeriksaan | Langkah | Hasil |
| --- | --- | --- |
| Tabel atribut | `scripts/verify-frontmatter.ps1` | Lihat laporan penutupan F0 |
| Angka sama dengan dokumen kelas | Bandingkan 11 tabel, tiga kategori, toleransi, skor 0,6 dan 0,4 dengan `docs/` | Sama |

## 7. Cara mundur

Hapus folder yang ditambahkan; tidak ada kode yang bergantung.
