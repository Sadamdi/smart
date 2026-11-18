"""Bagian identitas dan komponen untuk berkas desain utama (smart-ui.figcraft): logo Toga Lipat dan ikon aplikasi,
palet, ilustrasi pendamping (Jam Pasir, Gulungan, Lembar Terakhir), serta komponen baru (cincin skor, tab wilayah,
chip kategori, titik syarat). Menghasilkan teks SVG yang diubah svg_ke_figcraft menjadi layer FigCraft asli."""
import build_kartu as K

NAVY, DEEP, BLUE, MID, SKY, PALE, GOLD = K.NAVY, K.DEEP, K.BLUE, K.MID, K.SKY, K.PALE, K.GOLD
t, kotak = K.t, K.kotak


def toga(x0, y0, ukuran, bg=NAVY, bulat=False, tanpa_latar=False):
    """Toga Lipat pada kotak biru tua. Koordinat logo 120 x 120 diskalakan ke ukuran."""
    k = ukuran / 120

    def X(x):
        return x0 + k * (60 + 0.9 * (x - 60))

    def Y(y):
        return y0 + k * (60 + 0.9 * (y - 57))

    def poli(pts, fill):
        return '<polygon points="%s" fill="%s"/>' % (" ".join("%.1f,%.1f" % (X(a), Y(b)) for a, b in pts), fill)

    g = []
    if not tanpa_latar:
        if bulat:
            g.append('<circle cx="%.1f" cy="%.1f" r="%.1f" fill="%s"/>' % (x0 + ukuran / 2, y0 + ukuran / 2, ukuran / 2, bg))
        else:
            g.append(kotak(x0, y0, ukuran, ukuran, 26 * k, bg))
    g.append('<path d="M%.1f,%.1f V%.1f C%.1f,%.1f %.1f,%.1f %.1f,%.1f V%.1f L%.1f,%.1fZ" fill="#7FA8E0"/>' % (
        X(36), Y(62), Y(84), X(45), Y(92), X(75), Y(92), X(84), Y(84), Y(62), X(60), Y(74)))
    g.append(poli([(60, 52), (60, 22), (14, 52)], "#BCD2F1"))
    g.append(poli([(60, 52), (60, 22), (106, 52)], "#FFFFFF"))
    g.append(poli([(60, 52), (106, 52), (60, 82)], "#3E83D6"))
    g.append(poli([(60, 52), (60, 82), (14, 52)], "#7FA8E0"))
    g.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#F5B73B" stroke-width="%.1f"/>' % (X(106), Y(52), X(106), Y(78), 3.5 * k * 0.9))
    g.append(kotak(X(101), Y(78), 10 * k * 0.9, 13 * k * 0.9, 0, "#F5B73B"))
    return "".join(g)


def jam_pasir(x0, y0):
    g = [kotak(x0 + 30, y0 + 14, 60, 8, 2, NAVY), kotak(x0 + 30, y0 + 98, 60, 8, 2, NAVY)]
    g.append('<polygon points="%d,%d %d,%d %d,%d %d,%d" fill="#F5B73B"/>' % (x0 + 44, y0 + 36, x0 + 76, y0 + 36, x0 + 63, y0 + 52, x0 + 57, y0 + 52))
    g.append('<polygon points="%d,%d %d,%d %d,%d %d,%d" fill="#F5B73B"/>' % (x0 + 40, y0 + 95, x0 + 80, y0 + 95, x0 + 66, y0 + 76, x0 + 54, y0 + 76))
    g.append('<path d="M%d,%d H%d L%d,%d L%d,%d H%d L%d,%d Z" fill="none" stroke="%s" stroke-width="3.4" stroke-linejoin="round"/>' % (
        x0 + 36, y0 + 22, x0 + 84, x0 + 64, y0 + 60, x0 + 84, y0 + 98, x0 + 36, x0 + 56, y0 + 60, NAVY))
    return "".join(g)


def gulungan(x0, y0):
    g = [kotak(x0 + 32, y0 + 34, 56, 52, 0, "#FFFFFF", stroke=NAVY, sw=3)]
    for yy, w in ((46, 40), (55, 40), (64, 24)):
        g.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="4"/>' % (x0 + 40, y0 + yy, x0 + 40 + w, y0 + yy, SKY))
    g.append(kotak(x0 + 20, y0 + 28, 12, 64, 6, NAVY) + kotak(x0 + 88, y0 + 28, 12, 64, 6, NAVY))
    g.append('<circle cx="%d" cy="%d" r="11" fill="#F5B73B"/>' % (x0 + 60, y0 + 76))
    return "".join(g)


def lembar(x0, y0):
    g = ['<path d="M%d,%d V%d A6,6 0 0 1 %d,%d H%d A6,6 0 0 1 %d,%d V%d Z" fill="%s"/>' % (
        x0 + 22, y0 + 44, y0 + 28, x0 + 28, y0 + 22, x0 + 92, x0 + 98, y0 + 28, y0 + 44, NAVY)]
    g.append(kotak(x0 + 22, y0 + 44, 76, 58, 0, "#FFFFFF", stroke=NAVY, sw=3))
    for yy, w in ((62, 52), (74, 52), (86, 30)):
        g.append('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-width="4"/>' % (x0 + 34, y0 + yy, x0 + 34 + w, y0 + yy, SKY))
    g.append('<circle cx="%d" cy="%d" r="4" fill="%s"/><circle cx="%d" cy="%d" r="4" fill="%s"/>' % (x0 + 42, y0 + 22, SKY, x0 + 78, y0 + 22, SKY))
    return "".join(g)


def svg_identitas():
    W, H = 1180, 900
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">' % (W, H, W, H), kotak(0, 0, W, H, 0, "#F3F6FB")]
    o.append(t(40, 52, "Identitas SMART", 28, 800, NAVY))
    o.append(t(40, 78, "Logo Toga Lipat: kertas dilipat menjadi topi toga, jumbai emas penanda arah dan hasil.", 14, 500, K.MUTED))
    # logo dan ikon aplikasi
    o.append(toga(40, 110, 160))
    o.append(t(120, 296, "Logo utama", 12.5, 700, NAVY, "middle"))
    o.append(toga(230, 150, 96))
    o.append(toga(350, 166, 64))
    o.append(toga(440, 178, 40))
    o.append(t(278, 296, "Ikon aplikasi", 12.5, 700, NAVY, "middle"))
    o.append(toga(520, 150, 96, bulat=True))
    o.append(t(568, 296, "Ikon bulat (Android)", 12.5, 700, NAVY, "middle"))
    o.append(kotak(650, 110, 160, 160, 26, PALE))
    o.append(toga(650, 110, 160, bg="#143F7C", tanpa_latar=True).replace("#FFFFFF", "#FFFFFF"))
    o.append(t(730, 296, "Tanpa kotak (adaptif)", 12.5, 700, NAVY, "middle"))
    # palet
    o.append(t(40, 350, "Palet", 18, 800, NAVY))
    sw = [("Biru tua", "#143F7C"), ("Biru", "#3E83D6"), ("Biru sedang", "#7FA8E0"), ("Biru muda", "#BCD2F1"), ("Emas (aksen tunggal)", "#F5B73B"),
          ("Mint", "#CFEFE2"), ("Mentega", "#FFF1C9"), ("Persik", "#FFE3D5"), ("Koral (lencana)", "#FF7A6B")]
    for i, (n, c) in enumerate(sw):
        x = 40 + (i % 5) * 220
        y = 368 + (i // 5) * 100
        o.append(kotak(x, y, 200, 56, 16, c, stroke="#C9D6EC", sw=1))
        o.append(t(x + 12, y + 74, n + "  " + c, 12, 600, NAVY))
    # ilustrasi pendamping dalam aplikasi
    o.append(t(40, 590, "Ilustrasi pendamping di dalam aplikasi (bergerak di web dan mobile)", 18, 800, NAVY))
    for i, (n, fn, ket) in enumerate([("Jam Pasir", jam_pasir, "memuat satu halaman penuh, menunggu server"), ("Gulungan", gulungan, "notifikasi atau pengumuman kosong"),
                                      ("Lembar Terakhir", lembar, "kalender dan checklist kosong")]):
        x = 40 + i * 300
        o.append(kotak(x, 612, 280, 250, 28, "#FFFFFF", stroke="#C9D6EC", sw=1))
        o.append(fn(x + 80, 622))
        o.append(t(x + 140, 770, n, 15, 800, NAVY, "middle"))
        o.append(t(x + 140, 792, ket, 12, 500, K.MUTED, "middle"))
    o.append("</svg>")
    return "\n".join(o), W, H


def svg_komponen():
    W, H = 1180, 760
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">' % (W, H, W, H), kotak(0, 0, W, H, 0, "#F3F6FB")]
    o.append(t(40, 52, "Komponen skor kelayakan", 28, 800, NAVY))
    o.append(t(40, 78, "Skor kelayakan adalah seberapa banyak syarat terukur terpenuhi, bukan peluang diterima.", 14, 500, K.MUTED))
    o.append(t(40, 124, "Cincin skor", 18, 800, NAVY))
    estados = [(82, "#2FA37A", "Memenuhi"), (64, GOLD, "Hampir memenuhi"), (28, "#BA1A1A", "Belum memenuhi"), (None, MID, "Syarat belum tercatat")]
    for i, (p, c, n) in enumerate(estados):
        x = 80 + i * 260
        o.append(kotak(x - 40, 140, 230, 150, 28, "#FFFFFF"))
        o.append(K.cincin(x + 30, 214, 34, p, c, tebal=9))
        o.append(t(x + 30, 274, n, 12.5, 700, NAVY, "middle"))
    o.append(t(40, 340, "Tab dalam dan luar negeri", 18, 800, NAVY))
    o.append(kotak(40, 356, 170, 40, 20, NAVY) + t(125, 381, "Dalam negeri", 13.5, 700, "#FFFFFF", "middle"))
    o.append(kotak(220, 356, 170, 40, 20, "#FFFFFF", stroke=PALE, sw=1.5) + t(305, 381, "Luar negeri", 13.5, 700, DEEP, "middle"))
    o.append(t(40, 448, "Chip kategori dan tenggat", 18, 800, NAVY))
    x = 40
    for label, fill, warna in (("Memenuhi", K.MINT, K.MINT_T), ("Hampir memenuhi", K.BUTTER, "#8A5A00"), ("Belum memenuhi", K.PEACH, "#B03A1E"), ("Tenggat 13 hari", PALE, DEEP)):
        c, w = K.chip(x, 464, label, fill, warna)
        o.append(c)
        x += w + 10
    o.append(t(40, 540, "Titik syarat terpenuhi", 18, 800, NAVY))
    o.append(K.titik_syarat(52, 566, 5, 6, "#2FA37A") + t(150, 570, "Syarat terpenuhi 5 dari 6", 12.5, 600, K.MUTED))
    o.append(K.titik_syarat(52, 594, 4, 7, GOLD) + t(160, 598, "Syarat terpenuhi 4 dari 7", 12.5, 600, K.MUTED))
    o.append(t(40, 650, "Tombol", 18, 800, NAVY))
    o.append(kotak(40, 666, 200, 52, 26, BLUE) + t(140, 698, "Buka laman resmi", 15, 700, "#FFFFFF", "middle"))
    o.append(kotak(256, 666, 200, 52, 26, "#FFFFFF", stroke=PALE, sw=1.5) + t(356, 698, "Simpan", 15, 700, DEEP, "middle"))
    o.append("</svg>")
    return "\n".join(o), W, H


def _hp(x, y, judul_layar):
    return [kotak(x, y, 360, 720, 36, "#FFFFFF", stroke="#C9D6EC", sw=2), t(x + 20, y - 12, judul_layar, 14, 800, NAVY)]


def _kepala(x, y):
    g = [toga(x + 16, y + 14, 32), t(x + 56, y + 37, "SMART", 16, 800, NAVY)]
    g.append('<circle cx="%d" cy="%d" r="18" fill="%s"/><circle cx="%d" cy="%d" r="5" fill="#FFFFFF"/>' % (x + 276, y + 30, PALE, x + 276, y + 26))
    g.append(kotak(x + 266, y + 33, 20, 9, 4, "#FFFFFF"))
    g.append('<circle cx="%d" cy="%d" r="18" fill="%s"/>' % (x + 322, y + 30, PALE))
    g.append('<circle cx="%d" cy="%d" r="4" fill="#FF7A6B"/>' % (x + 330, y + 20))
    return "".join(g)


def _nav(x, y, aktif):
    """Bar bawah: Beranda, Rekomendasi, Jelajah, Kalender, Asisten AI. Profil ada di kepala halaman."""
    g = [kotak(x, y, 360, 76, 28, "#FFFFFF", stroke="#C9D6EC", sw=1)]
    for i, n in enumerate(["Beranda", "Rekomendasi", "Jelajah", "Kalender", "Asisten AI"]):
        cx = x + 36 + i * 72
        warna = BLUE if i == aktif else "#7A8CA8"
        g.append('<circle cx="%d" cy="%d" r="11" fill="%s"/>' % (cx, y + 28, warna if i == aktif else PALE))
        g.append(t(cx, y + 58, n, 10.5, 700 if i == aktif else 500, warna, "middle"))
    return "".join(g)


def svg_pembaruan():
    W, H = 1680, 880
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">' % (W, H, W, H), kotak(0, 0, W, H, 0, "#F3F6FB")]
    o.append(t(40, 48, "Pembaruan 18 November 2026: bar bawah, kalender, dokumen, profil lanjutan", 24, 800, NAVY))
    # 1. Rekomendasi dengan urut peluang dan bar bawah baru
    x, y = 40, 120
    o += _hp(x, y, "Rekomendasi: urut peluang, Asisten AI di bar bawah")
    o.append(_kepala(x, y))
    o.append(t(x + 20, y + 92, "Rekomendasi Beasiswa", 20, 800, NAVY))
    xx = x + 20
    for lab, on in (("Peluang diterima", True), ("Tenggat", False), ("Skor kelayakan", False)):
        c, w = K.chip(xx, y + 112, lab, NAVY if on else PALE, "#FFFFFF" if on else DEEP)
        o.append(c)
        xx += w + 8
    for i in range(3):
        yy = y + 168 + i * 150
        o.append(kotak(x + 16, yy, 328, 134, 24, "#FFFFFF", stroke="#E1E9F6", sw=1))
        o.append(t(x + 32, yy + 30, "Nama beasiswa %d" % (i + 1), 15, 800, NAVY))
        o.append(t(x + 32, yy + 50, "Penyelenggara | Tenggat 12 hari", 12, 500, K.MUTED))
        o.append(K.cincin(x + 290, yy + 40, 24, [62, 38, 21][i], [GOLD, GOLD, "#BA1A1A"][i], tebal=6))
        o.append(t(x + 32, yy + 92, "Estimasi peluang (perkiraan)", 11.5, 600, K.MUTED))
    o.append(_nav(x, y + 636, 4))
    # 2. Kalender dengan pop up
    x = 450
    o += _hp(x, y, "Kalender: rekomendasi masuk otomatis, pop up ke detail")
    o.append(_kepala(x, y))
    o.append(t(x + 20, y + 92, "November 2026", 18, 800, NAVY))
    for r_ in range(5):
        for c_ in range(7):
            n = r_ * 7 + c_ + 1
            if n > 30:
                continue
            cx, cy = x + 40 + c_ * 46, y + 128 + r_ * 44
            o.append(t(cx, cy + 5, str(n), 13, 600, NAVY, "middle"))
            if n in (12, 19, 24):
                o.append('<circle cx="%d" cy="%d" r="3" fill="#F5B73B"/>' % (cx, cy + 14))
            if n in (8, 27):
                o.append('<circle cx="%d" cy="%d" r="3" fill="#BA1A1A"/>' % (cx, cy + 14))
    o.append(t(x + 20, y + 372, "Emas: rekomendasi. Merah: tersimpan.", 12, 500, K.MUTED))
    o.append(kotak(x, y + 440, 360, 280, 36, "#FFFFFF", stroke="#C9D6EC", sw=2))
    o.append(kotak(x + 150, y + 452, 60, 5, 2, "#C9D6EC"))
    o.append(t(x + 24, y + 496, "Beasiswa Prestasi Nusantara", 17, 800, NAVY))
    o.append(t(x + 24, y + 522, "Direkomendasikan: memenuhi syarat", 13, 500, K.INK))
    o.append(t(x + 24, y + 544, "Tenggat 24 November 2026", 12, 500, K.MUTED))
    o.append(kotak(x + 24, y + 572, 312, 48, 24, BLUE) + t(x + 180, y + 602, "Lihat detail", 15, 700, "#FFFFFF", "middle"))
    o.append(t(x + 180, y + 660, "Tutup", 13, 600, DEEP, "middle"))
    # 3. Dokumen dengan lihat isi
    x = 860
    o += _hp(x, y, "Dokumen: disimpan di server, tombol Lihat isi")
    o.append(_kepala(x, y))
    o.append(t(x + 20, y + 92, "Dokumen Saya", 20, 800, NAVY))
    o.append(t(x + 20, y + 116, "PDF, DOCX, TXT, PNG, JPG. Maksimal 10 MB.", 12, 500, K.MUTED))
    o.append(kotak(x + 16, y + 132, 328, 48, 24, BLUE) + t(x + 180, y + 162, "Unggah dokumen", 15, 700, "#FFFFFF", "middle"))
    for i, (n, s) in enumerate((("CV_Nabila.pdf", "Terbaca: IPK 3.72, Semester 5"), ("Sertifikat_TOEFL.jpg", "Terbaca: TOEFL 520"))):
        yy = y + 204 + i * 110
        o.append(kotak(x + 16, yy, 328, 96, 20, "#FFFFFF", stroke="#E1E9F6", sw=1))
        o.append(kotak(x + 28, yy + 14, 40, 50, 10, PALE))
        o.append(t(x + 80, yy + 32, n, 14, 800, NAVY))
        o.append(t(x + 80, yy + 52, s, 11.5, 500, K.MUTED))
        o.append(chip_kecil(x + 80, yy + 64, "Selesai"))
        o.append('<circle cx="%d" cy="%d" r="14" fill="%s"/>' % (x + 280, yy + 30, PALE))
        o.append('<circle cx="%d" cy="%d" r="14" fill="%s"/>' % (x + 318, yy + 30, PALE))
    o.append(_nav(x, y + 636, -1))
    # 4. Profil lanjutan dengan bilah simpan aman
    x = 1270
    o += _hp(x, y, "Profil Lanjutan: kartu, lembar isian, bilah simpan")
    o.append(t(x + 20, y + 40, "Profil Lanjutan", 20, 800, NAVY))
    for i, (n, ket) in enumerate((("Keahlian", "Python, Desain, Analisis"), ("Prestasi", "2 prestasi"), ("Organisasi", "BEM Fakultas"), ("Sertifikat", "1 sertifikat"), ("Target jenjang", "S2"))):
        yy = y + 72 + i * 84
        o.append(kotak(x + 16, yy, 328, 72, 20, "#FFFFFF", stroke="#E1E9F6", sw=1))
        o.append(t(x + 32, yy + 30, n, 14, 800, NAVY))
        o.append(t(x + 32, yy + 52, ket, 12, 500, K.MUTED))
        o.append(t(x + 326, yy + 40, "Ubah", 12, 700, BLUE, "end"))
    o.append(kotak(x, y + 600, 360, 120, 36, "#FFFFFF", stroke="#C9D6EC", sw=1))
    o.append(kotak(x + 20, y + 620, 320, 48, 24, BLUE) + t(x + 180, y + 650, "Simpan perubahan", 15, 700, "#FFFFFF", "middle"))
    o.append(kotak(x + 130, y + 700, 100, 4, 2, "#143F7C", op=0.25))
    o.append(t(x + 180, y + 690, "Jarak aman untuk tombol navigasi Android", 10, 500, K.MUTED, "middle"))
    o.append("</svg>")
    return "\n".join(o), W, H


def chip_kecil(x, y, label):
    return kotak(x, y, 60, 20, 10, K.MINT) + t(x + 30, y + 14, label, 10.5, 700, K.MINT_T, "middle")


def svg_chat():
    W, H = 1260, 880
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">' % (W, H, W, H), kotak(0, 0, W, H, 0, "#F3F6FB")]
    o.append(t(40, 48, "Chatbot AI: jawaban beraturan, sumber, dan pilihan server atau ponsel", 24, 800, NAVY))
    # 1. Chat dengan markdown
    x, y = 40, 120
    o += _hp(x, y, "Chat: markdown, lencana sumber, rujukan")
    o.append(t(x + 20, y + 40, "Chatbot Beasiswa", 18, 800, NAVY))
    o.append(kotak(x + 220, y + 20, 110, 32, 16, BLUE) + t(x + 275, y + 41, "Ponsel", 13, 700, "#FFFFFF", "middle"))
    o.append(kotak(x + 50, y + 70, 290, 40, 18, BLUE) + t(x + 64, y + 95, "Beasiswa apa yang cocok untukku?", 13, 600, "#FFFFFF"))
    o.append(kotak(x + 16, y + 126, 320, 330, 20, "#FFFFFF", stroke="#E1E9F6", sw=1))
    o.append(t(x + 32, y + 156, "Rekomendasi untukmu", 16, 800, NAVY))
    for i, (n, d) in enumerate((("Program Bantuan Pendidikan", "estimasi 49%, memenuhi"), ("KIP Kuliah Jalur SNBP", "estimasi 39%, memenuhi"), ("Beasiswa Prestasi Nusantara", "estimasi 21%, hampir"))):
        yy = y + 180 + i * 52
        o.append('<circle cx="%d" cy="%d" r="3" fill="%s"/>' % (x + 38, yy - 4, BLUE))
        o.append(t(x + 50, yy, n, 13.5, 800, NAVY) + t(x + 50, yy + 18, d, 12, 500, K.MUTED))
    o.append(kotak(x + 32, y + 346, 288, 54, 10, PALE))
    o.append(t(x + 44, y + 368, "Estimasi hanya perkiraan, bukan jaminan.", 12, 600, DEEP))
    o.append('<circle cx="%d" cy="%d" r="6" fill="none" stroke="%s" stroke-width="2"/>' % (x + 40, y + 430, K.MUTED))
    o.append(t(x + 52, y + 435, "Dijawab model AI di ponsel", 11, 600, K.MUTED))
    o.append(t(x + 32, y + 480, "Sumber data beasiswa SMART", 11, 600, K.MUTED))
    for i, n in enumerate(("Program Bantuan...", "KIP Kuliah...")):
        o.append(kotak(x + 32 + i * 150, y + 490, 140, 30, 15, "#FFFFFF", stroke=PALE, sw=1.5) + t(x + 102 + i * 150, y + 510, n, 12, 700, DEEP, "middle"))
    o.append(kotak(x + 16, y + 640, 328, 52, 26, "#FFFFFF", stroke="#C9D6EC", sw=1.5) + t(x + 36, y + 672, "Tulis pertanyaanmu", 14, 500, K.MUTED))
    # 2. Pilihan sumber
    x = 450
    o += _hp(x, y, "Pilih jawab lewat server atau ponsel")
    o.append(t(x + 20, y + 40, "Chatbot Beasiswa", 18, 800, NAVY))
    o.append(kotak(x + 220, y + 20, 110, 32, 16, "#FFFFFF", stroke=PALE, sw=1.5) + t(x + 275, y + 41, "Server", 13, 700, DEEP, "middle"))
    o.append(kotak(x + 16, y + 90, 328, 150, 20, "#FFFFFF", stroke="#E1E9F6", sw=1))
    o.append(t(x + 32, y + 122, "Server (layanan AI)", 15, 800, NAVY))
    o.append(t(x + 32, y + 146, "Jawaban lengkap, butuh jaringan", 12.5, 500, K.MUTED))
    o.append(t(x + 32, y + 180, "Ponsel (model AI)", 15, 800, NAVY))
    o.append(t(x + 32, y + 204, "Tanpa server, algoritma dihitung di ponsel", 12.5, 500, K.MUTED))
    o.append(kotak(x + 16, y + 260, 328, 120, 20, PALE))
    o.append(t(x + 32, y + 292, "Alat yang dipakai AI di ponsel", 14, 800, NAVY))
    for i, n in enumerate(("Simulasi: jika IPK 3,8", "Tenggat terdekat", "Banding dua beasiswa")):
        o.append(t(x + 44, y + 318 + i * 20, n, 12.5, 600, DEEP))
        o.append('<circle cx="%d" cy="%d" r="3" fill="%s"/>' % (x + 34, y + 314 + i * 20, "#F5B73B"))
    # 3. Model AI luring
    x = 860
    o += _hp(x, y, "Model AI luring: spesifikasi dan saran")
    o.append(t(x + 20, y + 40, "Chatbot AI luring", 18, 800, NAVY))
    o.append(kotak(x + 16, y + 64, 328, 118, 18, "#FFFFFF", stroke="#E1E9F6", sw=1))
    for i, ln in enumerate(("vivo I2501", "RAM 14,9 GB | 8 inti | 64-bit", "GPU Vulkan | 49,6 GB kosong", "Saran: Gemma 4 E2B")):
        o.append(t(x + 30, y + 90 + i * 22, ln, 13 if i else 15, 800 if i in (0, 3) else 500, NAVY if i in (0, 3) else K.MUTED))
    o.append(kotak(x + 16, y + 198, 328, 230, 18, "#FFFFFF", stroke=BLUE, sw=2))
    o.append(t(x + 30, y + 228, "Gemma 4 E2B", 16, 800, NAVY))
    o.append(kotak(x + 244, y + 212, 86, 24, 12, K.MINT) + t(x + 287, y + 229, "Disarankan", 11, 700, K.MINT_T, "middle"))
    for i, ln in enumerate(("Parameter: 2 miliar efektif", "Konteks: hingga 32 ribu token", "Kecepatan: sedang", "Bahasa Indonesia: baik")):
        o.append('<circle cx="%d" cy="%d" r="5" fill="%s"/>' % (x + 36, y + 256 + i * 24, PALE))
        o.append(t(x + 50, y + 260 + i * 24, ln, 12.5, 600, NAVY))
    xx = x + 30
    for lab in ("Obrolan", "Fungsi", "Gambar", "Suara"):
        c, w = K.chip(xx, y + 360, lab, PALE, DEEP)
        o.append(c)
        xx += w + 6
    o.append(kotak(x + 30, y + 394, 300, 28, 14, BLUE) + t(x + 180, y + 413, "Sedang dipakai", 12.5, 700, "#FFFFFF", "middle"))
    o.append("</svg>")
    return "\n".join(o), W, H
