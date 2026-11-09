# Desain SMART (offline)

Berkas desain UI web dan mobile dibuat dengan FigCraft (bagian dari ArtCraft, terpasang di `C:\Program Files\ArtCraft\FigCraft`). Semuanya tersimpan lokal; tidak butuh akun atau internet.

| Berkas | Isi |
| --- | --- |
| `smart-ui.figcraft` | Berkas desain: 6 layar mobile (390 px: pembuka, masuk, beranda, jelajah, rekomendasi, detail) dan 2 layar web (1280 px: dashboard, jelajah). Buka dengan `figcraft.exe`. |
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

Token warna dan jari-jari sama dengan `apps/web/src/app/globals.css` dan `apps/mobile/lib/core/theme/app_theme.dart`. Huruf aplikasi Plus Jakarta Sans; berkas desain memakai Inter bawaan FigCraft karena Plus Jakarta Sans tidak terpasang di PC. Data di layar adalah contoh.

Server MCP FigCraft (lingkup lokal, tidak masuk repo): `claude mcp add --scope local figcraft -- "C:\Program Files\ArtCraft\FigCraft\figcraft-cli.exe" mcp --automation-read-root <design> --automation-write-root <design>`. Aktif di sesi Claude Code berikutnya.
