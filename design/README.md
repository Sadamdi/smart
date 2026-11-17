# Desain SMART (offline)

Berkas desain UI web dan mobile dibuat dengan FigCraft (bagian dari ArtCraft, terpasang di `C:\Program Files\ArtCraft\FigCraft`). Semuanya tersimpan lokal; tidak butuh akun atau internet.

| Berkas | Isi |
| --- | --- |
| `smart-ui.figcraft` | **Satu berkas desain utama** untuk mobile, web, logo, dan komponen. Berisi 13 layar mobile (390 px: pembuka, masuk, beranda, jelajah, rekomendasi, detail, kalender, profil, dokumen, chat, pengaturan, tersimpan, keadaan memuat/kosong/galat/tanpa jaringan) dan 12 layar web (1280 px: dashboard, jelajah, rekomendasi, detail, kalender, profil, dokumen, chat, masuk, tersimpan, antrean validasi admin, keadaan). Semuanya dalam mode terang dan gelap (berakhiran "(gelap)"). Buka dengan `figcraft.exe`. |
| `render/*.png` | Hasil render tiap layar |
| `logo-smart.svg`, `logo-smart-512.png` | Logo SMART (vektor dan PNG 512) |
| `logo-smart-animasi.svg` | Logo beranimasi (topi turun, jumbai naik, bintang berkilau); menghormati `prefers-reduced-motion` |
| `build_figcraft.py` | Sumber desain. Ubah di sini lalu jalankan ulang |

Bangun ulang dan render:

```powershell
cd SMART/design
python build_figcraft.py
& "C:\Program Files\ArtCraft\FigCraft\figcraft-cli.exe" export smart-ui.figcraft --out render --format png
```

Token warna dan jari-jari sama dengan `apps/web/src/app/globals.css` dan `apps/mobile/lib/core/theme/app_theme.dart`. Huruf aplikasi Plus Jakarta Sans; berkas desain memakai Inter bawaan FigCraft karena Plus Jakarta Sans tidak terpasang di PC. Data di layar adalah contoh dengan nama beasiswa nyata dan tanggal rekaan. Web dan mobile memakai token, ikon, istilah, dan urutan menu yang sama dengan aplikasi (`AppShell.tsx`).

Server MCP FigCraft (lingkup lokal, tidak masuk repo): `claude mcp add --scope local figcraft -- "C:\Program Files\ArtCraft\FigCraft\figcraft-cli.exe" mcp --automation-read-root <design> --automation-write-root <design>`. Aktif di sesi Claude Code berikutnya.


## Berkas desain tunggal (17 November 2026)

`smart-ui.figcraft` adalah satu-satunya berkas desain. Selain layar mobile dan web, di bawahnya (y = 2400, berjajar ke kanan) terdapat empat bagian yang dibuat dari `build_identitas.py`, `build_ilustrasi.py`, dan `build_kartu.py` lalu diubah menjadi layer FigCraft asli oleh `svg_ke_figcraft.py` (tetap dapat disunting):

1. **Identitas**: logo Toga Lipat, ikon aplikasi (persegi, bulat, adaptif), palet, ilustrasi pendamping Jam Pasir, Gulungan, Lembar Terakhir.
2. **Komponen**: cincin skor kelayakan (empat keadaan), tab Dalam/Luar negeri, chip kategori, titik syarat, tombol.
3. **Ilustrasi gaya pastel**: tumpukan buku, topi toga, kalender, roket, piala, lonceng.
4. **Kartu skor**: Beranda mobile, Detail mobile, dan Jelajah web dengan skor kelayakan dan "Syarat terpenuhi X dari Y".

Layar lama di bagian atas berkas masih bergaya versi sebelumnya dan belum disesuaikan dengan tema pasteline; bagian 4 adalah rancangan yang diikuti kode.

Bangun ulang: `python build_figcraft.py`.
