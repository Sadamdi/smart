# Aplikasi mobile mahasiswa (Flutter)

| Atribut | Nilai |
| --- | --- |
| **Versi** | v0.5.0 |
| **Tanggal** | 2026-11-03 |
| **Status** | In Progress |
| **Author** | Tim SMART |
| **Sumber bisnis** | `Dokument/03-Frontend/03-RENCANA-UIUX-DARI-FIGMA.md`, `01-PRD-WEB-MOBILE.md`, `02-PETA-LAYAR-KE-ENDPOINT.md`, `Dokument/02-Backend/openapi.json`; kartu Kaneo `[FE] Aplikasi web dan mobile` (WBS 4.6) |
| **Tipe** | Feature |
| **Module** | mobile |
| **Branch** | `adam/mobile-aplikasi` |
| **PR / Commit** | diisi saat PR dibuka |
| **Last Updated** | 2026-11-03 |

## 1. Tujuan

Membangun layar mahasiswa di Android sesuai Figma dan kontrak API: masuk dan daftar, beranda, rekomendasi, jelajah, detail beasiswa, kalender dan checklist, profil, notifikasi (FR-SM-05, 09, 10, 12, 13).

## 2. Ringkasan

- Yang berubah: `apps/mobile` dari kerangka kosong menjadi aplikasi lengkap dengan tema dari token Figma, klien Dio, penyimpanan token aman, Riverpod, go_router, dan delapan kelompok layar.
- Dampak: tidak menyentuh `apps/backend` dan `apps/web`. Memakai endpoint yang sudah ada di `openapi.json`.
- Perubahan yang merusak: tidak.

## 3. Rencana

- [x] Token desain dan `ThemeData` (Plus Jakarta Sans lewat paket `google_fonts`)
- [x] Widget bersama di `lib/core/widgets`
- [x] Klien API, penyegaran token sekali pada 401, penyimpanan token aman
- [x] Layar: masuk, daftar, beranda, rekomendasi, jelajah, detail, kalender dan checklist, profil, notifikasi
- [x] Uji klien, repositori, widget kartu dan layar utama; `flutter analyze` bersih
- [ ] Uji di emulator terhadap backend nyata
- [ ] Tangkapan layar dibandingkan dengan Figma untuk Kalender, Profil, Notifikasi

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Bentuk `nilai_batas` persyaratan belum baku | Teks syarat bisa kurang rapi | Ditampilkan generik dari nilai di dalam objek; sesuaikan setelah kontrak baku |
| Huruf diunduh saat pertama jalan | Tampilan awal memakai huruf bawaan bila offline | `google_fonts` menyimpan cache; aset huruf dapat ditambahkan bila perlu |

## 4. File yang diubah

| File | Tipe | Ringkasan |
| --- | --- | --- |
| `apps/mobile/pubspec.yaml` | Config | Tambah `google_fonts`, `url_launcher` |
| `apps/mobile/lib/core/` | Kode | Tema, format tanggal, klien API, penyimpanan token, router, provider, widget bersama |
| `apps/mobile/lib/features/*` | Kode | `data`, `domain`, `presentation` untuk auth, beranda, beasiswa, rekomendasi, kalender, profil, notifikasi |
| `apps/mobile/test/` | Uji | Klien API, repositori, widget, layar |

## 5. Sebelum dan sesudah

| Aspek | Sebelum | Sesudah |
| --- | --- | --- |
| Layar | Satu teks kerangka | Sembilan layar dengan keadaan memuat, kosong, galat |
| Token | Tidak ada | Disimpan di Keystore lewat `flutter_secure_storage` |

## 6. Verifikasi

| Pemeriksaan | Perintah atau langkah | Hasil |
| --- | --- | --- |
| Analisis statis | `flutter analyze` | Bersih |
| Format | `dart format lib test` | Bersih |
| Uji | `flutter test` | Lulus |
| Build | `flutter build apk --debug` | Lihat laporan PR |

## 7. Cara mundur

Kembalikan `apps/mobile` ke commit sebelum cabang ini digabung; tidak ada migrasi data.
