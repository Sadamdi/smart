# Lingkungan dan Rahasia

| Atribut | Nilai |
| --- | --- |
| **Versi** | 1.0 |
| **Tanggal** | 2026-10-26 |
| **Status** | Draft |
| **Author** | Tim SMART |
| **Sumber bisnis** | `apps/README.md` aturan 4 dan 5, pelajaran keamanan data dari proyek lain |

## Tiga lingkungan

| Lingkungan | Basis data | Dipakai untuk | Boleh dihapus isinya |
| --- | --- | --- | --- |
| dev | Proyek Supabase `smart-dev` | Pengembangan harian | Ya, dengan skrip `cleanup` |
| test | Proyek Supabase `smart-test` (terpisah dari dev) | Uji otomatis | Ya, otomatis oleh pengaturan uji |
| prod | Server dan domain milik Adam (basis data: Supabase atau PostgreSQL di server, diputuskan saat server diberikan) | Pengguna sebenarnya | Tidak, kecuali dengan izin eksplisit dan cadangan |

**Aturan utama:** jangan pernah menunjuk `.env` lokal ke basis data prod. Uji dan skrip yang menghapus data wajib menolak jalan kecuali `APP_ENV` bernilai `test` atau `dev` dan host `DATABASE_URL` ada di daftar putih `DESTRUCTIVE_DB_HOSTS`. Daftar putih hanya berisi host proyek dev atau uji, tidak pernah host prod. Karena basis data berada di layanan awan dan bukan `localhost`, daftar putih ini satu-satunya pengaman. Alasan: di proyek lain, uji dari laptop menghapus semua tabel karena `.env` lokal menunjuk basis data yang sama dengan prod.

## Berkas `.env`

Setiap komponen punya `.env.example` yang masuk repo (tanpa nilai rahasia) dan `.env` yang tidak masuk repo.

| Variabel | Komponen | Keterangan |
| --- | --- | --- |
| DATABASE_URL | backend, crawler | `postgresql+psycopg://...` ke proyek Supabase sesuai lingkungan (kata sandi basis data dari dasbor Supabase, tidak masuk repo) |
| APP_ENV | backend, crawler, ml | `dev`, `test`, atau `prod` |
| DESTRUCTIVE_DB_HOSTS | backend, crawler | Daftar putih untuk uji dan skrip yang menghapus data; kosong di prod. Pooler Supabase memakai host yang sama untuk semua proyek satu wilayah, jadi isi dengan `pengguna@host` (mis. `postgres.<ref>@aws-0-....pooler.supabase.com`), bukan host saja |
| JWT_SECRET | backend | Acak panjang; berbeda per lingkungan |
| JWT_ACCESS_MENIT, JWT_REFRESH_HARI | backend | Umur token |
| ENCRYPTION_KEY | backend | Kunci enkripsi dokumen |
| AI_BASE_URL, AI_API_KEY, AI_MODEL | backend, crawler | Layanan AI kompatibel OpenAI |
| AI_BATAS_HARIAN | backend | Batas panggilan per hari untuk menjaga kuota |
| FCM_CREDENTIALS_PATH | backend | Berkas kredensial push; di luar repo |
| SMTP_HOST, SMTP_USER, SMTP_PASSWORD, SMTP_DARI | backend | Pengiriman surel |
| CRAWLER_JEDA_DETIK | crawler | Jeda antarpermintaan bawaan |
| NEXT_PUBLIC_API_URL | web | Alamat API |
| API_BASE_URL | mobile | Lewat `--dart-define` |

## Aturan rahasia

1. Kunci, token, kata sandi, dan kredensial tidak boleh ada di kode, dokumen, pesan komit, atau tangkapan layar.
2. Akun uji dan nilai rahasia ditaruh di `Dokument/local/` (diabaikan git). Contoh format di `Dokument/local/TESTING_ACCOUNTS.example.md`, tanpa nilai nyata.
3. Skrip uji membaca kredensial dari variabel lingkungan, bukan ditulis langsung. Contoh email di dokumen memakai `example.com`.
4. Kunci Kaneo dan kunci layanan AI yang pernah tampil di percakapan harus diganti.
5. Jangan mengubah rahasia prod tanpa konfirmasi eksplisit Adam. Yang diperbolehkan tanpa konfirmasi: membaca untuk diagnosa tanpa menuliskan nilainya ke obrolan atau dokumen.
6. `.gitignore` memuat `.env`, `.env.*` (kecuali `.env.example`), `Dokument/local/`, `*.pem`, `*.key`, berkas kredensial FCM, dan unggahan pengguna.

## Perubahan data prod

Cadangkan dulu (`pg_dump`), jalankan percobaan tanpa menulis dan tunjukkan hasilnya, baru eksekusi dalam satu transaksi, dengan izin eksplisit untuk perintah itu saja.

## Supabase

- Dua proyek: `smart-dev` dan `smart-test`. Aktifkan ekstensi `vector` (Database, Extensions) di keduanya. Rencana gratis Supabase membatasi jumlah proyek aktif; bila prod memakai Supabase juga, cek batasnya.
- Sambungan memakai connection string dari dasbor (mode langsung atau pooler). Simpan di `.env` masing-masing komponen, bukan di repo.
- Backend adalah satu-satunya klien basis data; aplikasi tidak memakai anon key Supabase. Jangan mengaktifkan akses langsung dari klien.
- Migrasi hanya lewat Alembic. Jangan mengubah skema dari dasbor.

Backend, web, dan crawler dijalankan langsung di mesin pengembang agar cepat dimuat ulang.
