# Gold Set Rekomendasi

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft (menunggu O-07) |
| **Author** | Tim SMART |
| **Sumber bisnis** | `01-Arsitektur/03-ATURAN-KELAYAKAN-DAN-MODEL.md` |

Gold set adalah kumpulan profil contoh beserta daftar beasiswa yang menurut penilai manusia pantas direkomendasikan. Dipakai untuk menghitung Precision@5 dan NDCG@5.

## Bentuk

- Lokasi: `apps/ml/eval/gold_set/` (berkas YAML atau JSON per profil), tanpa data pribadi nyata.
- Setiap profil: field profil yang dipakai kelayakan, daftar beasiswa relevan (id), dan catatan alasan.
- Profil dibuat sintetis tetapi realistis; bila memakai data mahasiswa sungguhan, hapus identitas dan minta persetujuan.

## Pembuatan

1. Kumpulkan minimal 30 beasiswa terbit dari pemantau (F3).
2. Susun 20 profil yang beragam: jenjang, IPK, semester, kampus negeri dan swasta, minat, dengan atau tanpa sertifikat bahasa.
3. Dua penilai (Riska dan Devan) melabeli beasiswa relevan secara terpisah. Selisih diselesaikan Adam.
4. Bagi profil: sekitar 70% pengembangan, 30% uji akhir. Profil uji tidak dipakai menyetel batas toleransi.

## Pelaporan

Cantumkan jumlah profil, jumlah beasiswa, kesepakatan antarpenilai, Precision@5, NDCG@5, dan hasil ablasi. Gold set dibekukan dengan nomor versi sebelum evaluasi akhir.
