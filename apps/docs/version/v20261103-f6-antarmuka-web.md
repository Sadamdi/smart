# F6: antarmuka web mahasiswa dan panel admin

| Atribut | Nilai |
| --- | --- |
| **Versi** | v0.6.0 |
| **Tanggal** | 2026-11-03 |
| **Status** | In Progress |
| **Author** | Tim SMART |
| **Sumber bisnis** | Master Plan F6 dan F9, `Dokument/03-Frontend/03-RENCANA-UIUX-DARI-FIGMA.md`, `02-PETA-LAYAR-KE-ENDPOINT.md`, `Dokument/02-Backend/openapi.json` |
| **Tipe** | Feature |
| **Module** | web |
| **Branch** | `adam/web-antarmuka` |
| **PR / Commit** | PR ke `testing` (tautan di serah terima) / lihat riwayat cabang |
| **Last Updated** | 2026-11-03 |

## 1. Tujuan

Membangun seluruh antarmuka web SMART di atas kontrak API yang sudah jadi: kerangka aplikasi, pustaka komponen, klien API dengan penyegaran token, halaman mahasiswa, dan panel admin. Bahasa Indonesia, tanpa data contoh fiktif, tanpa kata "pencocokan", persen kecocokan, atau klaim peluang lolos.

## 2. Ringkasan

- Yang berubah: `apps/web` dari kerangka kosong menjadi aplikasi lengkap (22 rute). Token desain, huruf Plus Jakarta Sans, `AppShell`, komponen bersama, klien API bertipe, hook TanStack Query, layar Masuk, Daftar, Dashboard, Jelajah, Detail, Rekomendasi, Beasiswa Tersimpan, Kalender dan Checklist, Dokumen Saya, Chatbot, Profil, Notifikasi, Pengaturan, serta Admin (dashboard, antrean, detail validasi, kelola, tambah, edit sumber, laporan).
- Dampak: web dapat dipakai penuh terhadap backend lokal lewat proxy `/backend`. Tidak ada perubahan di `apps/backend`.
- Perubahan yang merusak: tidak. `meta.nextCursor` di klien lama diganti `meta.kursor_berikut` sesuai kontrak.

## 3. Rencana

- [x] Token, `AppShell`, klien API, penyimpanan token, Masuk dan Daftar
- [x] Jelajah, Detail, Dashboard, Rekomendasi, Tersimpan
- [x] Profil, Dokumen, Kalender dan Checklist, Notifikasi, Chatbot, Pengaturan
- [x] Admin: dashboard, antrean, detail validasi, sumber, laporan
- [x] Uji vitest dan pemeriksaan di peramban
- [ ] Perbandingan visual dengan Figma (alat Figma MCP terkena batas panggilan paket Starter, lihat bagian 6)
- [ ] Layar admin tambah beasiswa manual (`POST /admin/beasiswa`), tidak diminta di inventaris layar

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Figma tidak terbaca saat dibangun | Selisih visual kecil | Mengikuti token dan inventaris di `03-RENCANA-UIUX-DARI-FIGMA.md`; perbandingan menyusul |
| Token di localStorage | Rentan XSS | Tanpa HTML mentah; CSP menyusul di tahap penempatan |

## 4. File yang diubah

| File | Tipe | Ringkasan |
| --- | --- | --- |
| `apps/web/src/app/globals.css`, `layout.tsx` | Edit | Token warna, Plus Jakarta Sans, Providers |
| `apps/web/src/app/(auth)/masuk`, `daftar` | Baru | Layar masuk dan daftar |
| `apps/web/src/app/(app)/**` | Baru | Halaman mahasiswa dan admin di dalam gerbang sesi |
| `apps/web/src/components/*` | Baru | AppShell, Gerbang, ui, state, KartuBeasiswa, KalenderBulan, DaftarChecklist, GelembungChat, KolomUnggah, KoreksiHasilBaca, FormMasuk, FormDaftar, FormSumber, PanelAuth, Providers |
| `apps/web/src/lib/*` | Baru dan edit | api (penyegaran token), token, auth, hooks, types, format, profil, validasi |
| `apps/web/src/**/*.test.ts(x)` | Baru | 30 uji vitest |
| `apps/web/next.config.ts` | Edit | Validasi navigasi instan hanya untuk segmen yang meminta |
| `apps/web/package.json` | Edit | lucide-react, @testing-library/dom |

## 5. Sebelum dan sesudah

| Aspek | Sebelum | Sesudah |
| --- | --- | --- |
| Halaman | Satu halaman kerangka | 22 rute |
| Klien API | `apiFetch` tanpa sesi | `api` dengan penyegaran otomatis sekali pada 401, lalu kembali ke `/masuk` |
| Uji | 3 uji | 30 uji |

## 6. Verifikasi

| Pemeriksaan | Perintah atau langkah | Hasil |
| --- | --- | --- |
| Lint | `npm run lint` | Lulus |
| Tipe | `npm run typecheck` | Lulus |
| Uji | `npm test` | 30 lulus |
| Build | `npm run build` | Lulus, 22 rute |
| Alur mahasiswa | Backend lokal (`adam/backend-modul-lengkap`), web `npm run dev` dengan `BACKEND_ORIGIN`; akun mahasiswa uji: masuk, jelajah, detail, simpan (POST interaksi 200), rekomendasi, kalender, checklist, dokumen (unggah, koreksi, terapkan ke profil), chat (status AI tidak tersedia), notifikasi | Berjalan; console tanpa galat aplikasi |
| Alur admin | Akun admin uji: dashboard, antrean, detail validasi (PUT lalu POST terbitkan, 200), sumber, laporan | Berjalan |
| Jalur gagal | Mahasiswa membuka `/admin` | Layar "Halaman khusus admin" |
| Ponsel | Lebar 375 px, `/masuk` dan `/kalender` | Tanpa gulir horizontal |
| Figma | `get_screenshot` 627:2 | Gagal: batas panggilan Figma MCP paket Starter tercapai |

Akun uji hanya ada di basis data uji lokal dan tidak ditulis ke repositori.

## 7. Cara mundur

`git revert` komit di cabang `adam/web-antarmuka`. Tidak ada migrasi.
