# Validasi AI, pemantau sumber AI, baca CV gambar, LightGBM dengan SHAP, layar mobile lanjutan

| Atribut | Nilai |
| --- | --- |
| **Versi** | v0.7.0 |
| **Tanggal** | 2026-11-04 |
| **Last Updated** | 2026-11-04 |
| **Status** | In Progress |
| **Author** | Tim SMART |
| **Sumber bisnis** | Arahan pengguna 4 November 2026; `Dokument/01-Arsitektur/04-PEMANTAUAN-SUMBER.md`; Master Plan F3, F4, F5 |
| **Tipe** | Feature |
| **Module** | backend, web, mobile |
| **Branch** | `adam/validasi-ai-dan-pemantau`, `adam/mobile-dokumen-chat-pengaturan`, `adam/peringkat-lightgbm` |

## 1. Tujuan

Mengurangi pekerjaan validasi manual, memperluas sumber data, dan melengkapi lapisan pemeringkatan serta layar mobile yang tertinggal.

## 2. Ringkasan

- Validasi AI otomatis: laman resmi dibaca, dinormalkan ke skema SMART, lalu diperiksa aturan tegas. Tenggat dan syarat hanya dipakai bila kutipannya ada di teks laman; terbit hanya bila tenggat paling cepat 3 hari. Satu kali per beasiswa (`divalidasi_ai_pada`). Saklar admin `auto_validasi_ai` (default aktif), tombol "Validasi AI sekarang", tombol "Pantau sekarang" per sumber. Penjadwal opsional (`PENJADWAL_AKTIF`): validasi tiap 10 menit, pemantauan harian 05.30 WIB.
- Pemantau sumber berbasis AI untuk SatuBeasiswa, Beasiswa Unggulan, Djarum, BSI. Luarkampus (login) dan LPDP (captcha) tidak dilewati; Komdigi dan Scholarpedia tetap rujukan. Hasil nyata: SatuBeasiswa 9 program, Beasiswa Unggulan 4; Djarum dan BSI 0 karena laman dirender JavaScript.
- Baca CV berupa gambar lewat model gambar (`AI_MODEL_GAMBAR`); AI sebagai cadangan bila aturan tidak menemukan apa pun.
- Profil tambahan (kondisi khusus dan catatan), tidak dikirim ke layanan AI.
- Pemeringkat LightGBM LambdaRank dengan SHAP (pred_contrib) di dalam kategori kelayakan; model demo sintetis berlabel, model dari interaksi nyata menunggu data (minimal 20 pengguna dan 200 pasangan).
- Mobile: layar Dokumen, Chatbot AI, Pengaturan, dan profil tambahan.
- Migrasi 0003 dan 0004; tabel `pengaturan` (14 tabel).
- Uji: backend 81, web 30, mobile 31.

## 3. Rencana

- [x] Validasi AI, saklar, pemicu, penjadwal
- [x] Pemantau sumber berbasis AI dan baca CV gambar
- [x] LightGBM dan SHAP (model demo sintetis)
- [x] Layar mobile Dokumen, Chatbot, Pengaturan
- [ ] Model e5 asli, gold set dan evaluasi Precision@5
- [ ] Pemantau untuk laman yang dirender JavaScript (Djarum, BSI)
- [ ] Pengiriman email dan push
- [ ] Uji mobile di emulator dan pembandingan dengan Figma
