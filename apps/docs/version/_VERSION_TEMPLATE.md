# Templat Version Log

Salin untuk setiap perubahan atau rencana. Nama berkas `vYYYYMMDD-<slug>.md`. Daftarkan di `VERSION_INDEX.md`.

---

# [Judul perubahan atau plan]

| Atribut | Nilai |
| --- | --- |
| **Versi** | vX.Y.Z |
| **Tanggal** | YYYY-MM-DD |
| **Status** | Plan / In Progress / Released / Rolled Back |
| **Author** | Tim SMART |
| **Sumber bisnis** | Dokumen, kartu Kaneo, atau diskusi |
| **Tipe** | Feature / Fix / Refactor / Migration / Docs / Config |
| **Module** | backend / crawler / ml / web / mobile / infra / docs |
| **Branch** | `<inisial>/<slug>` |
| **PR / Commit** | `<url>` / `<hash>` |
| **Last Updated** | YYYY-MM-DD |

## 1. Tujuan

Mengapa perubahan ini dilakukan, dikaitkan ke kebutuhan (FR-SM atau NFR-SM) atau temuan. 1 sampai 3 kalimat.

## 2. Ringkasan

- Yang berubah:
- Dampak ke pengguna atau komponen lain:
- Perubahan yang merusak? Ya atau tidak (bila ya, cara migrasi)

## 3. Rencana (diisi saat Plan)

- [ ] Langkah 1
- [ ] Langkah 2
- [ ] Migrasi dan dampak data
- [ ] Perbarui dokumen: skema, kontrak API, feature, flows, TODO

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |

## 4. File yang diubah

| File | Tipe | Ringkasan |
| --- | --- | --- |

## 5. Sebelum dan sesudah

| Aspek | Sebelum | Sesudah |
| --- | --- | --- |

## 6. Verifikasi

| Pemeriksaan | Perintah atau langkah | Hasil |
| --- | --- | --- |

Untuk endpoint: jalur, status code, peran akun yang dipakai (bukan nilai kredensial), dan hasil uji dua pengguna.

## 7. Cara mundur

Langkah mengembalikan perubahan, termasuk migrasi turun bila ada.
