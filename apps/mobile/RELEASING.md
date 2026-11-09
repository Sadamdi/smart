# Merilis aplikasi SMART (APK) dan pembaruan otomatis

Setiap rilis diterbitkan lewat `scripts/release.ps1`. Skrip membangun APK 64-bit dan 32-bit, memastikan tanda tangan rilis, menghitung SHA-256, lalu menerbitkannya ke GitHub Releases bersama berkas `latest.json`. Aplikasi yang sudah terpasang membaca `latest.json`, menawarkan pembaruan, mengunduh APK yang sesuai dengan arsitektur ponsel, dan menyerahkannya ke pemasang Android.

Alamat pembaruan tetap, gratis, dan tidak membutuhkan server: `https://github.com/Sadamdi/smart/releases/latest/download/latest.json`.

## Cara kerja

1. Aplikasi membaca `latest.json` saat dibuka dan setiap kembali ke latar depan (paling sering sekali per enam jam). Pengguna juga dapat memeriksa manual di Pengaturan, Periksa pembaruan.
2. Bila nomor build di manifest lebih tinggi dari build terpasang, muncul dialog dengan catatan rilis. Pembaruan wajib tidak bisa ditutup.
3. Arsitektur ponsel dideteksi otomatis (`dart:ffi`): ponsel 32-bit mengunduh APK `arm32`, selebihnya `arm64`.
4. Unduhan dapat dilanjutkan bila koneksi putus (permintaan `Range`), lalu SHA-256 diperiksa.
5. Sebelum diserahkan ke pemasang, kunci penandatangan APK unduhan dibandingkan dengan kunci aplikasi terpasang.
6. Android meminta konfirmasi "Perbarui". Pertama kali, pengguna juga mengizinkan SMART memasang aplikasi dari sumber ini.

## Keamanan

| Lapisan | Perlindungan |
| --- | --- |
| Alamat | Hanya HTTPS dari `github.com` dan `*.githubusercontent.com`. Alamat lain di manifest ditolak. |
| Keutuhan | SHA-256 APK harus sama dengan nilai di manifest; berkas rusak dihapus. |
| Keaslian | Kunci penandatangan APK unduhan harus sama dengan kunci aplikasi terpasang. Android sendiri menolak pembaruan yang tanda tangannya berbeda. |
| Build tidak resmi | Build debug atau berkunci lain tidak menerima pembaruan (`certSha256` di manifest tidak cocok). |
| Rilis bermasalah | `blockedBuilds` memaksa ponsel yang memakai build bermasalah untuk memperbarui. `minBuild` memaksa semua ponsel di bawahnya. |
| Akun penerbit | Aktifkan autentikasi dua langkah pada akun GitHub pemilik repositori; siapa pun yang dapat menerbitkan rilis dapat mengganti `latest.json`. |
| Kunci rilis | Berkas kunci dan `android/key.properties` tidak pernah di-commit. Simpan cadangan kunci di dua tempat; bila hilang, aplikasi yang sudah terpasang tidak dapat diperbarui lagi. |

## Sekali di tiap laptop

1. Berkas kunci rilis `smart-release.jks` dan `android/key.properties` (minta ke pemegang kunci; jangan di-commit). Sidik jari kunci resmi ada di `release-cert.sha256`.
2. GitHub CLI sudah login: `gh auth login`.
3. Flutter dan Android SDK terpasang (`apksigner` dipakai untuk memeriksa tanda tangan).

## Jenis rilis

| Jenis | `-Type` | Contoh | Kapan | Pembaruan |
| --- | --- | --- | --- | --- |
| Perbaikan | `patch` | 1.0.0 menjadi 1.0.1 | perbaikan bug, teks, performa | opsional |
| Fitur | `minor` | 1.0.3 menjadi 1.1.0 | fitur baru kecil atau sedang | opsional |
| Rilis besar | `big` | 1.1.0 menjadi 1.5.0 | paket fitur besar | opsional |
| Rombak | `major` | 1.x menjadi 2.0.0 | perubahan total atau tidak kompatibel | wajib |

Nomor build (`+N`) selalu naik 1. Bawaan wajib atau opsional dapat diganti dengan `-Mandatory` atau `-Optional`, atau `mandatory: true|false` pada catatan rilis.

## Rilis biasa

```powershell
cd SMART/apps/mobile
.\scripts\release.ps1 -Type patch
```

1. Pertama kali, skrip membuat templat `release-notes/<build>-<versi>.md` lalu berhenti.
2. Isi catatan rilis dengan bahasa awam, hanya perubahan yang dirasakan pengguna aplikasi:

   ```markdown
   ---
   version: 1.0.1
   build: 3
   date: 2026-11-20
   type: patch
   mandatory: false
   blocks: []
   ---
   Ringkasan satu kalimat.

   Yang baru
   - ...

   Perbaikan
   - ...
   ```

   Hanya paragraf pertama tampil di dialog pembaruan; seluruh catatan ada di riwayat.
3. Jalankan ulang perintah yang sama. Skrip membangun, memeriksa tanda tangan, menghitung SHA-256, membuat commit rilis, mendorong cabang, dan menerbitkan rilis GitHub dengan tag `app-vX.Y.Z-bN`.
4. Gabungkan commit rilis ke `testing` dan `main` lewat pull request seperti biasa.

## Pemulihan

Android tidak dapat menurunkan build, jadi pemulihan berarti membangun ulang kode versi stabil dengan build baru:

```powershell
.\scripts\release.ps1 -Rollback -To 1.0.0 -Block 3
```

Build 3 masuk `blockedBuilds`, sehingga ponsel yang memakainya wajib memperbarui. Setelah perbaikan siap, rilis lagi seperti biasa.

Bila rilis baru belum banyak terpasang, hentikan distribusinya:

```powershell
.\scripts\release.ps1 -Unpublish
```

Rilis sebelumnya kembali menjadi yang terbaru. Ponsel yang sudah terlanjur memasang tetap membutuhkan `-Rollback`.

## Menguji alur pembaruan tanpa memengaruhi pengguna

1. Isi `build/android-release.env` dengan `UPDATE_MANIFEST_URL=https://github.com/Sadamdi/smart/releases/download/<tag-uji>/latest.json`.
2. Terbitkan dua rilis uji dengan `-Prerelease -NoGit` (versi lama dan versi baru). Rilis `prerelease` tidak pernah menjadi "terbaru".
3. Pasang APK lama di emulator atau ponsel, buka aplikasi, dan ikuti dialog pembaruan.
4. Hapus rilis uji: `gh release delete <tag> --cleanup-tag --yes`, dan hapus baris `UPDATE_MANIFEST_URL` dari berkas lingkungan.
