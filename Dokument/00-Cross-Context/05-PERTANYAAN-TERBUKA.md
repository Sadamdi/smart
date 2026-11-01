# Pertanyaan Terbuka

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Active |
| **Author** | Tim SMART |
| **Sumber bisnis** | Dokumen Perancangan DP-SM-001, catatan penyusunan rencana |

Butir yang menghalangi pekerjaan ditandai dengan fase yang tertahan. Jawaban dicatat di kolom keputusan, lalu dipindahkan ke `03-ADR-KEPUTUSAN-ARSITEKTUR.md` bila berdampak arsitektur.

| ID | Pertanyaan | Menahan | Penentu | Usulan | Keputusan |
| --- | --- | --- | --- | --- | --- |
| O-01 | Apakah monorepo satu git (A-05) disetujui, dan di mana host repositorinya (GitHub organisasi atau akun pribadi)? | F1 | Adam | Monorepo, GitHub, cabang `main` dan `testing` | **Diputuskan Adam 26 Okt 2026:** monorepo satu git, cabang `main` dan `testing`. Host: GitHub `Sadamdi/smart` (27 Okt 2026). Repositori publik, jadi hanya kode dan dokumen teknis yang dipublikasikan |
| O-02 | Layanan hosting untuk penempatan (6.1): VPS, platform terkelola, atau kampus? Batas biaya hosting ada di RAB biaya langsung | F11 | Adam, Riska | Server dan domain milik Adam | **Diputuskan Adam 26 Okt 2026:** produksi memakai server dan domain milik Adam, detailnya diberikan nanti. F1 menyiapkan kerangka penempatan awal (variabel, proxy, layanan) tanpa nilai server |
| O-03 | Tugas pribadi di Kalender dan Checklist belum punya tabel. Tambah tabel `tugas_pribadi` (pengguna_id, judul, tanggal, selesai)? | F2 (migrasi), F8 | Tim, bersama desainer | Ya, tambah satu tabel | **Diputuskan 27 Okt 2026 (ERD final):** `tugas_pribadi` ditambahkan |
| O-04 | Token push (FCM) perlu disimpan per perangkat. Tambah tabel `perangkat_push` (pengguna_id, token, platform)? | F2, F8 | Adam | Ya, tambah satu tabel | **Diputuskan 27 Okt 2026 (ERD final):** `perangkat_push` ditambahkan |
| O-05 | Field profil tambahan untuk aturan kelayakan: penghasilan orang tua, skor bahasa, kewarganegaraan. Dipakai atau tidak di purwarupa? | F2, F5 | Tim | Dipakai, kolom boleh kosong | **Diputuskan Adam 26 Okt 2026:** kolom boleh dipakai bila dibutuhkan (kolom opsional, boleh kosong) |
| O-06 | Izin SatuBeasiswa (API resmi atau persetujuan pengambilan). Siapa yang menghubungi dan kapan? | F3 | Devan | Ajukan segera; sambil menunggu, UIN Malang dan input kurasi | (kosong) |
| O-07 | Gold set rekomendasi: berapa profil contoh dan siapa yang melabeli? | F5, F10 | Adam, Riska | 20 profil, dilabel Riska dan Devan, disepakati Adam | (kosong) |
| O-08 | Revisi desain Figma dari tim UI/UX (catatan di `docs/Catatan Figma untuk Desainer`). Perubahan layar mana yang final? | F6 | Riska | Mulai dari layar yang tidak terdampak revisi | **Diputuskan Adam 27 Okt 2026:** desain Figma final, menjadi pedoman implementasi |
| O-09 | Layanan AI: kunci, kuota, dan model. Siapa pemegang kunci produksi? | F4, F7 | Adam | Kunci hanya di `.env` dan penyimpan rahasia host | (kosong) |
| O-10 | Bukti persetujuan dosen atas judul belum tersimpan | Bukan teknis | Adam | Simpan di `docs/` | (kosong) |
| O-11 | Basis data lokal: mesin ini tidak punya Docker dan PostgreSQL 16 lokal belum punya ekstensi pgvector. Pilih: pasang Docker Desktop, pasang pgvector untuk PostgreSQL 16 Windows, atau pakai PostgreSQL terkelola yang mendukung pgvector (terpisah untuk dev dan uji) | F1, F2 | Adam | Docker Desktop (sama dengan rencana dan CI) | **Diputuskan Adam 26 Okt 2026:** tanpa Docker; basis data PostgreSQL memakai Supabase. Proyek dev dan uji terpisah. Produksi: ikut Supabase atau PostgreSQL di server Adam, diputuskan saat server diberikan |
