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
