"""Rancangan kartu beasiswa dengan skor kelayakan, tab Dalam/Luar negeri, dan Detail (mobile dan web).

Keluaran: kartu-skor.svg, kartu-skor.figcraft, render/kartu-skor.png. Jalankan: python build_kartu.py
Gaya: pasteline berbasis biru SMART, sudut sangat membulat, chip pil, cincin skor, navigasi bawah pil gelap.
Skor adalah skor kelayakan (seberapa banyak syarat terukur terpenuhi), bukan peluang diterima.
"""
import math
import os
import subprocess

AQUA = os.path.dirname(os.path.abspath(__file__))
FC = r"C:\Program Files\ArtCraft\FigCraft\figcraft-cli.exe"

NAVY, DEEP, BLUE, MID, SKY, PALE = "#143F7C", "#1E5BA8", "#3E83D6", "#7FA8E0", "#BCD2F1", "#D6E3FF"
GOLD, BUTTER, MINT, MINT_T, PEACH, CORAL, INK, MUTED, LATAR = "#F5B73B", "#FFF1C9", "#CFEFE2", "#1B6B3A", "#FFE3D5", "#FF7A6B", "#1E2A3D", "#5E6C82", "#F4F8FF"


def t(x, y, s, size=14, weight=500, fill=INK, anchor="start"):
    return f'<text x="{x}" y="{y}" font-family="Inter" font-weight="{weight}" font-size="{size}" fill="{fill}" text-anchor="{anchor}">{s}</text>'


def kotak(x, y, w, h, r, fill, stroke=None, sw=1, op=1):
    st = f' stroke="{stroke}" stroke-width="{sw}"' if stroke else ""
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" opacity="{op}"{st}/>'


def bayang(x, y, w, h, r):
    return kotak(x + 2, y + 6, w, h, r, NAVY, op=0.07)


def cincin(cx, cy, r, persen, warna, latar=PALE, tebal=7, teks=None):
    """Cincin skor: lintasan penuh lalu busur sebesar persen dari atas searah jarum jam."""
    g = [f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{latar}" stroke-width="{tebal}"/>']
    if persen is not None and persen > 0:
        a = 2 * math.pi * min(persen, 99.99) / 100
        x1, y1 = cx, cy - r
        x2, y2 = cx + r * math.sin(a), cy - r * math.cos(a)
        besar = 1 if persen > 50 else 0
        g.append(f'<path d="M{x1:.2f},{y1:.2f} A{r},{r} 0 {besar} 1 {x2:.2f},{y2:.2f}" fill="none" stroke="{warna}" stroke-width="{tebal}" stroke-linecap="round"/>')
    isi = teks if teks is not None else (f"{persen}" if persen is not None else "-")
    g.append(t(cx, cy + 6, isi, 17 if persen is not None else 20, 700, NAVY if persen is not None else MUTED, "middle"))
    if persen is not None and teks is None:
        g.append(t(cx + 13, cy - 4, "%", 8, 700, MUTED, "start"))
    return "".join(g)


def chip(x, y, label, fill, warna, w=None):
    w = w or (len(label) * 6.6 + 22)
    return kotak(x, y, w, 24, 12, fill) + t(x + w / 2, y + 16, label, 11, 600, warna, "middle"), w


def titik_syarat(x, y, terpenuhi, total, warna):
    g = []
    for i in range(total):
        g.append(f'<circle cx="{x + i * 13}" cy="{y}" r="4.5" fill="{warna if i < terpenuhi else PALE}"/>')
    return "".join(g)


def kartu_hp(x, y, nama, penyelenggara, persen, warna_cincin, status, tenggat, terpenuhi, total, w=342, h=152):
    g = [bayang(x, y, w, h, 26), kotak(x, y, w, h, 26, "#FFFFFF")]
    g.append(cincin(x + 44, y + 48, 26, persen, warna_cincin))
    g.append(t(x + 88, y + 34, nama[0], 15, 700, NAVY))
    g.append(t(x + 88, y + 53, nama[1], 15, 700, NAVY))
    g.append(t(x + 88, y + 72, penyelenggara, 12, 500, MUTED))
    fill, warna = {"memenuhi": (MINT, MINT_T), "hampir": (BUTTER, "#8A5A00"), "belum": (PEACH, "#B03A1E"), "tak": (PALE, DEEP)}[status[0]]
    c1, w1 = chip(x + 20, y + 92, status[1], fill, warna)
    g.append(c1)
    c2, _ = chip(x + 20 + w1 + 8, y + 92, tenggat, PALE, DEEP)
    g.append(c2)
    if total:
        g.append(titik_syarat(x + 26, y + 136, terpenuhi, total, warna_cincin))
        g.append(t(x + 26 + total * 13 + 4, y + 140, f"Syarat terpenuhi {terpenuhi} dari {total}", 11.5, 600, MUTED))
    else:
        g.append(t(x + 22, y + 140, "Syarat belum tercatat, cek laman resmi", 11.5, 600, MUTED))
    g.append(f'<circle cx="{x + w - 36}" cy="{y + h - 32}" r="20" fill="{PALE}"/>')
    g.append(f'<path d="M{x + w - 44},{y + h - 32} H{x + w - 28} M{x + w - 34},{y + h - 39} L{x + w - 27},{y + h - 32} L{x + w - 34},{y + h - 25}" fill="none" stroke="{NAVY}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>')
    return "".join(g)


def nav_bawah(x, y, w, aktif):
    g = [kotak(x, y, w, 64, 32, NAVY)]
    nama = ["Beranda", "Rekom.", "Jelajah", "Kalender", "Profil"]
    sel = w / 5
    for i, n in enumerate(nama):
        cx = x + sel * i + sel / 2
        if i == aktif:
            g.append(f'<circle cx="{cx}" cy="{y + 32}" r="24" fill="{GOLD}"/>')
            g.append(f'<circle cx="{cx}" cy="{y + 32}" r="7" fill="{NAVY}"/>')
        else:
            g.append(f'<circle cx="{cx}" cy="{y + 32}" r="6" fill="none" stroke="{SKY}" stroke-width="2"/>')
    return "".join(g)


def hp_beranda(x, y):
    W, H = 390, 880
    g = [f'<g transform="translate({x} {y})">', kotak(0, 0, W, H, 40, LATAR), kotak(0, 0, W, H, 40, "none", stroke="#C9D6EC", sw=2)]
    g.append(kotak(24, 28, 40, 40, 14, NAVY))
    g.append(f'<polygon points="44,38 58,45 44,52 30,45" fill="#FFFFFF"/><path d="M36,49 V55 C40,58 48,58 52,55 V49 L44,52Z" fill="{SKY}"/>')
    g.append(t(76, 55, "SMART", 20, 800, NAVY))
    g.append(f'<circle cx="{W - 44}" cy="48" r="22" fill="#FFFFFF"/><path d="M{W - 52},52 C{W - 52},44 {W - 48},40 {W - 44},40 C{W - 40},40 {W - 36},44 {W - 36},52 Z M{W - 47},56 H{W - 41}" fill="none" stroke="{NAVY}" stroke-width="2"/>')
    g.append(f'<circle cx="{W - 32}" cy="34" r="8" fill="{CORAL}"/>' + t(W - 32, 38, "2", 10, 700, "#FFFFFF", "middle"))
    # ringkasan
    g.append(t(24, 112, "Halo, Mahasiswa", 24, 800, NAVY))
    g.append(t(24, 134, "Semester 5, S1, IPK 3,55", 13, 500, MUTED))
    for i, (n, lab, bg, fg) in enumerate([("39", "Terpenuhi", MINT, MINT_T), ("16", "Hampir", BUTTER, "#8A5A00"), ("41", "Belum", PEACH, "#B03A1E")]):
        xx = 24 + i * 114
        g.append(kotak(xx, 154, 106, 82, 24, bg))
        g.append(t(xx + 16, 196, n, 32, 800, fg))
        g.append(t(xx + 16, 219, lab, 12.5, 600, fg))
    # tab dalam/luar negeri
    g.append(kotak(24, 258, 150, 40, 20, NAVY) + t(99, 283, "Dalam negeri", 13.5, 700, "#FFFFFF", "middle"))
    g.append(kotak(184, 258, 150, 40, 20, "#FFFFFF", stroke=PALE, sw=1.5) + t(259, 283, "Luar negeri", 13.5, 700, DEEP, "middle"))
    g.append(t(24, 328, "Pilihan utama", 17, 800, NAVY) + t(W - 24, 328, "Lihat semua", 13, 700, BLUE, "end"))
    g.append(kartu_hp(24, 346, ("AWS AI Academy untuk", "Masyarakat Indonesia"), "Amazon Web Services", 82, "#2FA37A", ("memenuhi", "Memenuhi"), "Tenggat 38 hari", 5, 6))
    g.append(kartu_hp(24, 512, ("LPDP Reguler Magister", "dan Doktor"), "Kementerian Keuangan", 64, GOLD, ("hampir", "Hampir memenuhi"), "Tenggat 21 hari", 4, 7))
    g.append(kartu_hp(24, 678, ("Beasiswa Unggulan", "Kemdiktisaintek"), "Kemdiktisaintek", None, MID, ("tak", "Belum ada angka"), "Tenggat 13 hari", 0, 0, h=110))
    g.append(nav_bawah(24, H - 84, W - 48, 0))
    g.append("</g>")
    return "".join(g)


def hp_detail(x, y):
    W, H = 390, 840
    g = [f'<g transform="translate({x} {y})">', kotak(0, 0, W, H, 40, LATAR), kotak(0, 0, W, H, 40, "none", stroke="#C9D6EC", sw=2)]
    g.append(f'<circle cx="46" cy="52" r="22" fill="#FFFFFF"/><path d="M52,52 H40 M45,46 L39,52 L45,58" fill="none" stroke="{NAVY}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>')
    g.append(f'<circle cx="{W - 46}" cy="52" r="22" fill="#FFFFFF"/><path d="M{W - 53},44 H{W - 39} V60 L{W - 46},55 L{W - 53},60Z" fill="none" stroke="{NAVY}" stroke-width="2"/>')
    g.append(t(24, 112, "AWS AI Academy", 26, 800, NAVY) + t(24, 142, "Scholarship", 26, 800, NAVY))
    g.append(t(24, 166, "Amazon Web Services, Indonesia", 13, 500, MUTED))
    # kartu skor besar
    g.append(bayang(24, 186, 342, 190, 32) + kotak(24, 186, 342, 190, 32, "#FFFFFF"))
    g.append(cincin(120, 280, 58, 82, "#2FA37A", tebal=14, teks=None).replace('font-size="17"', 'font-size="34"').replace('y="286"', 'y="292"'))
    g.append(t(206, 250, "Skor kelayakan", 13, 600, MUTED))
    g.append(t(206, 286, "82%", 36, 800, NAVY))
    g.append(kotak(206, 298, 130, 28, 14, MINT) + t(271, 317, "Memenuhi", 12.5, 700, MINT_T, "middle"))
    g.append(t(206, 352, "Syarat terpenuhi 5 dari 6", 12.5, 600, MUTED))
    g.append(titik_syarat(210, 364, 5, 6, "#2FA37A").replace('cy="364"', 'cy="366"'))
    # syarat
    g.append(t(24, 410, "Syarat dan kelayakanmu", 17, 800, NAVY))
    baris = [("Jenjang D3, D4, S1", "Jenjang S1 sesuai", True), ("Kewarganegaraan Indonesia", "Sesuai profilmu", True), ("IPK minimal 3,00", "IPK 3,55 memenuhi", True), ("TOEFL ITP minimal 550", "Skor TOEFL 520, selisih kecil", False)]
    for i, (a, b, ok) in enumerate(baris):
        yy = 426 + i * 74
        g.append(kotak(24, yy, 342, 64, 22, "#FFFFFF"))
        g.append(f'<circle cx="52" cy="{yy + 32}" r="14" fill="{MINT if ok else BUTTER}"/>')
        if ok:
            g.append(f'<path d="M45,{yy + 32} L50,{yy + 37} L59,{yy + 27}" fill="none" stroke="{MINT_T}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>')
        else:
            g.append(t(52, yy + 38, "!", 16, 800, "#8A5A00", "middle"))
        g.append(t(76, yy + 28, a, 14, 700, NAVY) + t(76, yy + 47, b, 12, 500, MINT_T if ok else "#8A5A00"))
    g.append(kotak(24, H - 88, 56, 56, 28, "#FFFFFF", stroke=PALE, sw=1.5))
    g.append(kotak(92, H - 88, W - 116, 56, 28, BLUE) + t(92 + (W - 116) / 2, H - 53, "Buka laman resmi", 15, 700, "#FFFFFF", "middle"))
    g.append("</g>")
    return "".join(g)


def web_baris(x, y):
    W, H = 1240, 392
    g = [f'<g transform="translate({x} {y})">', kotak(0, 0, W, H, 32, LATAR), kotak(0, 0, W, H, 32, "none", stroke="#C9D6EC", sw=2)]
    g.append(t(32, 56, "Jelajah beasiswa", 24, 800, NAVY))
    g.append(kotak(32, 76, 164, 40, 20, NAVY) + t(114, 101, "Dalam negeri (39)", 13, 700, "#FFFFFF", "middle"))
    g.append(kotak(206, 76, 164, 40, 20, "#FFFFFF", stroke=PALE, sw=1.5) + t(288, 101, "Luar negeri (12)", 13, 700, DEEP, "middle"))
    g.append(kotak(W - 340, 76, 308, 40, 20, "#FFFFFF", stroke=PALE, sw=1.5) + t(W - 320, 101, "Cari beasiswa atau penyelenggara", 13, 500, MUTED))
    data = [(("AWS AI Academy Scholarship", "untuk Masyarakat Indonesia"), "Amazon Web Services", 82, "#2FA37A", ("memenuhi", "Memenuhi"), "Tenggat 38 hari", 5, 6),
            (("LPDP Reguler Magister", "dan Doktor"), "Kementerian Keuangan", 64, GOLD, ("hampir", "Hampir memenuhi"), "Tenggat 21 hari", 4, 7),
            (("Beasiswa Unggulan", "Kemdiktisaintek"), "Kemdiktisaintek", None, MID, ("tak", "Belum ada angka"), "Tenggat 13 hari", 0, 0)]
    for i, d in enumerate(data):
        g.append(kartu_hp(32 + i * 400, 144, *d, w=380, h=152 if d[2] is not None else 152))
    g.append("</g>")
    return "".join(g)


def svg_teks():
    W, H = 1480, 1380
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', f'<rect width="{W}" height="{H}" fill="#E9EFF8"/>']
    out.append(f'<g id="Mobile Beranda">{hp_beranda(40, 40)}</g>')
    out.append(f'<g id="Mobile Detail">{hp_detail(470, 40)}</g>')
    out.append(f'<g id="Web Jelajah">{web_baris(40, 960)}</g>')
    out.append(t(900, 80, "Skor kelayakan adalah seberapa banyak syarat terukur terpenuhi.", 15, 700, NAVY))
    out.append(t(900, 104, "Bukan peluang diterima. Beasiswa tanpa syarat terukur tidak diberi angka.", 14, 500, MUTED))
    out.append("</svg>")
    return "\n".join(out)


def main():
    out = svg_teks()
    svg = os.path.join(AQUA, "kartu-skor.svg")
    open(svg, "w", encoding="utf-8").write(out)
    fig = os.path.join(AQUA, "kartu-skor.figcraft")
    r = subprocess.run([FC, "convert", svg, fig], capture_output=True, text=True)
    print("convert:", (r.stdout or r.stderr).strip()[:200])
    os.makedirs(os.path.join(AQUA, "render"), exist_ok=True)
    r = subprocess.run([FC, "render", fig, "--out", os.path.join(AQUA, "render", "kartu-skor.png"), "--scale", "1"], capture_output=True, text=True)
    print("render:", (r.stdout or r.stderr).strip()[:200])


if __name__ == "__main__":
    main()
