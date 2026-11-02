# apps/mobile

Flutter (Android). Aplikasi mahasiswa SMART.

- Peta layar ke endpoint: `../../Dokument/03-Frontend/02-PETA-LAYAR-KE-ENDPOINT.md`
- Rencana UI/UX dan token desain: `../../Dokument/03-Frontend/03-RENCANA-UIUX-DARI-FIGMA.md`
- Dokumen fitur: `../docs/features/09-mobile/`
- TODO: `../docs/todo/TODO_FE_F6-ANTARMUKA.md`

## Menjalankan

```
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

`10.0.2.2` adalah alamat komputer host dari emulator Android; ganti dengan alamat server untuk perangkat nyata. Token disimpan di penyimpanan aman perangkat dan tidak pernah ditulis ke repo.

## Pemeriksaan

```
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Struktur

```
lib/
  core/        api_client, token_storage, providers, router, theme, format, widgets/
  features/<fitur>/{data,domain,presentation}
test/          klien API, repositori, widget, layar (server palsu lewat adaptor Dio)
```

Fitur: auth, beranda, beasiswa (jelajah dan detail), rekomendasi, kalender (checklist dan tugas), profil, notifikasi.

## Aturan tampilan

Tanpa kata "pencocokan", persen kecocokan, atau klaim peluang lolos. Rekomendasi memakai kategori memenuhi, hampir memenuhi, belum memenuhi dengan alasan dan catatan kekurangan. Semua teks berbahasa Indonesia dan data berasal dari API.
