"""Ilustrasi SMART bergaya lembut-pastel (acuan: aplikasi belajar bergaya 3D datar yang dikirim pengguna).

Keluaran: ilustrasi-smart.svg, ilustrasi-smart.figcraft (dapat dibuka di FigCraft), render/ilustrasi-smart.png.
Jalankan: python build_ilustrasi.py
Palet biru SMART dengan mint, mentega, dan persik sebagai penyegar; emas hanya untuk satu bagian utama tiap ilustrasi.
"""
import os
import subprocess

AQUA = os.path.dirname(os.path.abspath(__file__))
FC = r"C:\Program Files\ArtCraft\FigCraft\figcraft-cli.exe"

NAVY, DEEP, BLUE, MID, SKY, PALE = "#143F7C", "#1E5BA8", "#3E83D6", "#7FA8E0", "#BCD2F1", "#D6E3FF"
GOLD, GOLD2, BUTTER, MINT, MINT2, PEACH, CORAL = "#F5B73B", "#FFD366", "#FFE7A3", "#8FD3B8", "#CFEFE2", "#FFD9C7", "#FF7A6B"

CELL = 360
GAP = 24


def sparkle(x, y, s, fill="#FFFFFF", op=1.0):
    k = s * 0.22
    d = (f"M{x},{y - s} C{x},{y - k} {x + k},{y} {x + s},{y} C{x + k},{y} {x},{y + k} {x},{y + s} "
         f"C{x},{y + k} {x - k},{y} {x - s},{y} C{x - k},{y} {x},{y - k} {x},{y - s}Z")
    return f'<path d="{d}" fill="{fill}" opacity="{op}"/>'


def sombra(cx, cy, rx, ry):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry}" fill="{NAVY}" opacity=".14"/>'


def grad(i, a, b, vertikal=True):
    x2, y2 = ("0", "1") if vertikal else ("1", "0")
    return f'<linearGradient id="{i}" x1="0" y1="0" x2="{x2}" y2="{y2}"><stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>'


DEFS = "".join([
    grad("gBiru", "#5B9BEA", BLUE), grad("gDeep", DEEP, NAVY), grad("gMid", "#9DBDEB", MID), grad("gEmas", GOLD2, GOLD),
    grad("gPutih", "#FFFFFF", PALE), grad("gMint", "#A9E4CD", MINT2), grad("gKaca", "#9FD4FF", "#4C9BE8"),
    grad("gLatarA", "#E3EEFF", "#F4F8FF"), grad("gLatarB", "#DDF3EA", "#F1FBF6"), grad("gLatarC", "#FFF1C9", "#FFF9E6"),
    grad("gLatarD", "#E3EEFF", "#F4F8FF"), grad("gLatarE", "#FFE3D5", "#FFF1EA"), grad("gLatarF", "#E8EEFF", "#F6F8FF"),
])


def buku_sisi(y, lebar, rot, tutup, warna_halaman="#FFFFFF"):
    """Buku tampak samping: sampul atas, halaman bergaris, sampul bawah, punggung di kiri."""
    h = 54
    x0 = -lebar / 2
    g = [f'<g transform="translate(180 {y}) rotate({rot})">']
    g.append(f'<rect x="{x0}" y="{-h/2}" width="{lebar}" height="{h}" rx="12" fill="{tutup}"/>')
    g.append(f'<rect x="{x0 + 16}" y="{-h/2 + 11}" width="{lebar - 26}" height="{h - 22}" rx="5" fill="{warna_halaman}"/>')
    for k in (-6, 0, 6):
        g.append(f'<line x1="{x0 + 26}" y1="{k}" x2="{x0 + lebar - 20}" y2="{k}" stroke="{PALE}" stroke-width="2.2"/>')
    g.append(f'<rect x="{x0}" y="{-h/2}" width="22" height="{h}" rx="12" fill="{NAVY}" opacity=".16"/>')
    g.append("</g>")
    return "".join(g)


def ilus_buku():
    s = [sombra(180, 302, 128, 14)]
    s.append(buku_sisi(262, 232, -1.5, "url(#gBiru)"))
    s.append(buku_sisi(208, 206, 3, "url(#gMid)"))
    s.append(buku_sisi(156, 178, -3, "url(#gDeep)"))
    # pita penanda emas yang menjuntai dari buku tengah
    s.append(f'<path d="M262 214 V262 L272 254 L282 262 V214Z" fill="url(#gEmas)"/>')
    s += [sparkle(78, 96, 22), sparkle(292, 78, 16, GOLD), sparkle(300, 196, 12), sparkle(60, 198, 10, GOLD, .9), sparkle(240, 118, 8)]
    return "".join(s)


def ilus_toga():
    s = [sombra(180, 296, 120, 13)]
    s.append(f'<path d="M108 192 V240 C128 268 232 268 252 240 V192 L180 218Z" fill="url(#gMid)"/>')
    s.append(f'<polygon points="180,104 304,156 180,208 56,156" fill="url(#gDeep)"/>')
    s.append(f'<polygon points="180,104 304,156 180,156" fill="#FFFFFF" opacity=".13"/>')
    s.append(f'<polygon points="56,156 180,208 180,156" fill="#000000" opacity=".1"/>')
    s.append(f'<circle cx="180" cy="156" r="7" fill="{GOLD}"/>')
    s.append(f'<path d="M180 156 L278 168 V232" fill="none" stroke="{GOLD}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')
    s.append(f'<rect x="270" y="228" width="16" height="32" rx="6" fill="url(#gEmas)"/>')
    s += [sparkle(84, 84, 20), sparkle(296, 88, 14, GOLD), sparkle(70, 226, 10), sparkle(312, 232, 11), sparkle(220, 70, 8, GOLD)]
    return "".join(s)


def ilus_kalender():
    s = [sombra(180, 302, 104, 12)]
    s.append(f'<rect x="84" y="102" width="200" height="190" rx="28" fill="{NAVY}" opacity=".12"/>')
    s.append(f'<rect x="80" y="92" width="200" height="190" rx="28" fill="#FFFFFF"/>')
    s.append(f'<rect x="80" y="92" width="200" height="58" rx="28" fill="url(#gDeep)"/>')
    s.append(f'<rect x="80" y="122" width="200" height="28" fill="{DEEP}"/>')
    for x in (122, 224):
        s.append(f'<rect x="{x}" y="74" width="14" height="38" rx="7" fill="{SKY}" stroke="#FFFFFF" stroke-width="3"/>')
    for j, y in enumerate((184, 214, 244)):
        for i, x in enumerate((114, 147, 180, 213, 246)):
            if (i, j) == (2, 1):
                continue
            col = PALE
            if (i, j) == (4, 2):
                col = MINT2
            s.append(f'<circle cx="{x}" cy="{y}" r="9.5" fill="{col}"/>')
    s.append(f'<circle cx="180" cy="214" r="17" fill="url(#gEmas)"/>')
    s.append(f'<path d="M171 214 L178 221 L190 207" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>')
    s += [sparkle(300, 100, 18, GOLD), sparkle(62, 128, 13), sparkle(310, 230, 10), sparkle(56, 250, 8, GOLD)]
    return "".join(s)


def ilus_roket():
    s = [sombra(180, 306, 112, 12)]
    # awan di dasar
    for cx, cy, r in ((120, 282, 30), (160, 290, 34), (206, 288, 32), (244, 280, 28), (180, 270, 30)):
        s.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#FFFFFF"/>')
    s.append('<g transform="rotate(26 180 170)">')
    s.append(f'<path d="M165 244 Q180 316 195 244Z" fill="url(#gEmas)"/><path d="M172 244 Q180 288 188 244Z" fill="{PEACH}"/>')
    s.append(f'<path d="M136 196 L100 252 L140 240Z" fill="{BLUE}"/><path d="M224 196 L260 252 L220 240Z" fill="{BLUE}"/>')
    s.append(f'<path d="M180 52 C232 92 242 170 226 240 H134 C118 170 128 92 180 52Z" fill="url(#gPutih)"/>')
    s.append(f'<path d="M180 52 C202 70 216 96 224 128 H136 C144 96 158 70 180 52Z" fill="url(#gEmas)"/>')
    s.append(f'<circle cx="180" cy="168" r="26" fill="{NAVY}"/><circle cx="180" cy="168" r="19" fill="url(#gKaca)"/><ellipse cx="173" cy="161" rx="6" ry="4" fill="#FFFFFF" opacity=".7"/>')
    s.append(f'<rect x="150" y="236" width="60" height="14" rx="6" fill="{NAVY}"/>')
    s.append("</g>")
    s += [sparkle(66, 80, 20), sparkle(304, 70, 12, GOLD), sparkle(60, 190, 10, GOLD), sparkle(310, 200, 14)]
    return "".join(s)


def ilus_piala():
    s = [sombra(180, 304, 100, 12)]
    s.append(f'<rect x="128" y="262" width="104" height="24" rx="9" fill="url(#gDeep)"/>')
    s.append(f'<rect x="164" y="228" width="32" height="38" rx="6" fill="{GOLD}"/>')
    s.append(f'<path d="M116 108 C64 108 64 176 124 182" fill="none" stroke="{GOLD}" stroke-width="15" stroke-linecap="round"/>')
    s.append(f'<path d="M244 108 C296 108 296 176 236 182" fill="none" stroke="{GOLD}" stroke-width="15" stroke-linecap="round"/>')
    s.append(f'<path d="M110 92 H250 V150 C250 198 218 230 180 230 C142 230 110 198 110 150Z" fill="url(#gEmas)"/>')
    s.append(f'<path d="M126 100 H146 V152 C146 184 160 206 176 214 C146 206 126 184 126 150Z" fill="#FFFFFF" opacity=".35"/>')
    s.append(f'<polygon points="180,128 189,148 211,150 194,164 200,185 180,174 160,185 166,164 149,150 171,148" fill="#FFFFFF"/>')
    s += [sparkle(74, 70, 18), sparkle(300, 66, 14, GOLD), sparkle(318, 206, 11), sparkle(52, 224, 9, GOLD)]
    return "".join(s)


def ilus_lonceng():
    s = [sombra(180, 304, 96, 11)]
    s.append(f'<path d="M180 70 C128 70 112 122 112 172 L98 216 H262 L248 172 C248 122 232 70 180 70Z" fill="url(#gEmas)"/>')
    s.append(f'<path d="M126 110 C140 84 160 76 176 76 C150 90 140 126 140 172 L128 212 H106 L120 170 C118 148 120 128 126 110Z" fill="#FFFFFF" opacity=".35"/>')
    s.append(f'<circle cx="180" cy="62" r="12" fill="{GOLD}"/>')
    s.append(f'<rect x="92" y="212" width="176" height="16" rx="8" fill="{GOLD}"/>')
    s.append(f'<circle cx="180" cy="244" r="17" fill="url(#gDeep)"/>')
    s.append(f'<path d="M72 130 C58 146 58 178 72 194" fill="none" stroke="{MID}" stroke-width="6" stroke-linecap="round"/>')
    s.append(f'<path d="M288 130 C302 146 302 178 288 194" fill="none" stroke="{MID}" stroke-width="6" stroke-linecap="round"/>')
    s.append(f'<circle cx="244" cy="96" r="24" fill="{CORAL}"/><circle cx="244" cy="96" r="24" fill="none" stroke="#FFFFFF" stroke-width="5"/>')
    s.append(f'<text x="244" y="104" text-anchor="middle" font-family="Inter" font-weight="700" font-size="22" fill="#FFFFFF">2</text>')
    s += [sparkle(70, 80, 16), sparkle(296, 252, 12, GOLD), sparkle(60, 252, 10)]
    return "".join(s)


CELLS = [
    ("Tumpukan buku: pembuka dan Beranda", "gLatarA", ilus_buku),
    ("Topi toga: profil dan pencapaian", "gLatarB", ilus_toga),
    ("Kalender: tenggat dan agenda", "gLatarC", ilus_kalender),
    ("Roket: rekomendasi dan mulai", "gLatarD", ilus_roket),
    ("Piala: skor kelayakan dan terpenuhi", "gLatarE", ilus_piala),
    ("Lonceng: notifikasi dan pengingat", "gLatarF", ilus_lonceng),
]


def svg_teks():
    kolom = 3
    baris = 2
    w = kolom * CELL + (kolom + 1) * GAP
    h = baris * CELL + (baris + 1) * GAP
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">', f"<defs>{DEFS}</defs>", f'<rect width="{w}" height="{h}" fill="#F3F6FB"/>']
    for i, (nama, bg, fn) in enumerate(CELLS):
        x = GAP + (i % kolom) * (CELL + GAP)
        y = GAP + (i // kolom) * (CELL + GAP)
        out.append(f'<g id="{nama}" transform="translate({x} {y})"><rect width="{CELL}" height="{CELL}" rx="44" fill="url(#{bg})"/>{fn()}</g>')
    out.append("</svg>")
    return "\n".join(out)


def main():
    out = svg_teks()
    svg = os.path.join(AQUA, "ilustrasi-smart.svg")
    open(svg, "w", encoding="utf-8").write(out)
    fig = os.path.join(AQUA, "ilustrasi-smart.figcraft")
    r = subprocess.run([FC, "convert", svg, fig], capture_output=True, text=True)
    print("convert:", (r.stdout or r.stderr).strip()[:300])
    rdir = os.path.join(AQUA, "render")
    os.makedirs(rdir, exist_ok=True)
    r = subprocess.run([FC, "render", fig, "--out", os.path.join(rdir, "ilustrasi-smart.png"), "--scale", "1"], capture_output=True, text=True)
    print("render:", (r.stdout or r.stderr).strip()[:300])


if __name__ == "__main__":
    main()
