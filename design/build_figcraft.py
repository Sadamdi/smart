"""Membangun desain UI SMART (web dan mobile) sebagai berkas FigCraft offline.

Keluaran: smart-ui.figcraft, render/*.png. Jalankan: python build_figcraft.py
Token warna sama dengan apps/web/src/app/globals.css dan apps/mobile/lib/core/theme/app_theme.dart.
Data di layar adalah contoh. Tata letak mengikuti pola umum aplikasi seluler (app bar, pencarian,
chip filter, kartu, navigasi bawah); tidak menyalin desain aplikasi mana pun.
"""
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

FC = r"C:\Program Files\ArtCraft\FigCraft\figcraft-cli.exe"
AQUA = os.path.dirname(os.path.abspath(__file__))

PRIMARY, SOFT, NAVY, INK, MUTED = "#225EAA", "#6C9FEF", "#051B38", "#424751", "#576676"
SURFACE, C1, C2, C3, C4 = "#F9F9FF", "#F0F3FF", "#E7EEFF", "#DFE8FF", "#D6E3FF"
ERR, ERR_SOFT, OUTLINE, OK, OK_SOFT, WHITE, GOLD = "#BA1A1A", "#FFDAD6", "#C2C6D3", "#1B6B3A", "#D9F2E0", "#FFFFFF", "#F5B73B"
KARTU = "#FFFFFF"
DEEP = "#1E4F94"
TERANG = dict(SURFACE="#F9F9FF", KARTU="#FFFFFF", NAVY="#051B38", INK="#424751", MUTED="#576676", C1="#F0F3FF", C2="#E7EEFF", C3="#DFE8FF", C4="#D6E3FF", PRIMARY="#225EAA", ERR="#BA1A1A", ERR_SOFT="#FFDAD6", OUTLINE="#C2C6D3", OK="#1B6B3A", OK_SOFT="#D9F2E0", DEEP="#1E4F94")
GELAP = dict(SURFACE="#0C1320", KARTU="#141E30", NAVY="#E8EEFA", INK="#C6CEDC", MUTED="#93A1B5", C1="#111A2A", C2="#18243A", C3="#203050", C4="#2A3D60", PRIMARY="#3F7FD4", ERR="#FF8F86", ERR_SOFT="#4A2224", OUTLINE="#384662", OK="#6FD39A", OK_SOFT="#173A28", DEEP="#143F7C")


def tema(gelap):
    g = globals()
    g.update(GELAP if gelap else TERANG)
    _GL[0] = gelap


FONT = "Inter"  # Plus Jakarta Sans dipakai di aplikasi; di berkas desain offline memakai Inter bawaan FigCraft

steps = []
_DY = [0]
_GL = [False]
_next = [2]  # id simpul pertama FigCraft adalah 2, naik satu per simpul yang dibuat


def _add(command, params):
    steps.append({"command": command, "params": params})
    nid = _next[0]
    _next[0] += 1
    return nid


def frame(x, y, w, h, name, fill=SURFACE, r=0, parent=None, stroke=None, clip=True):
    props = {"fill": fill, "cornerRadius": r, "clip": clip}
    if stroke:
        props["stroke"] = stroke
        props["strokeWeight"] = 1
    p = {"x": x, "y": y + (0 if parent else _DY[0]), "width": w, "height": h, "name": name + (" (gelap)" if _GL[0] and not parent else ""), "props": props, "select": False}
    if parent:
        p["parent"] = parent
    return _add("frame.create", p)
    if parent:
        p["parent"] = parent
    return _add("frame.create", p)


def rect(parent, x, y, w, h, fill, r=0, stroke=None, name="Kotak", shadow=False, op=None):
    props = {"fill": fill, "cornerRadius": r}
    if stroke:
        props["stroke"] = stroke
        props["strokeWeight"] = 1
    if shadow:
        props["effects"] = [{"type": "dropShadow", "offset": [0, 1], "radius": 2, "color": "#0000000D"}]
    if op is not None:
        props["opacity"] = op
    return _add("shape.rectangle", {"parent": parent, "x": x, "y": y, "width": w, "height": h, "name": name, "props": props, "select": False})


def oval(parent, x, y, w, h, fill, name="Lingkaran", stroke=None, sw=1):
    props = {"fill": fill}
    if stroke:
        props["stroke"] = stroke
        props["strokeWeight"] = sw
    return _add("shape.ellipse", {"parent": parent, "x": x, "y": y, "width": w, "height": h, "name": name, "props": props, "select": False})


def text(parent, x, y, s, size=14, weight="Regular", color=INK, width=None, align="left", spacing=None, line=None, name=None):
    props = {"fill": color, "fontFamily": FONT, "fontStyle": weight, "fontSize": size, "textAlign": align}
    if spacing is not None:
        props["letterSpacing"] = spacing
    if line:
        props["lineHeight"] = line
    p = {"parent": parent, "x": x, "y": y, "text": s, "name": name or s[:24], "props": props, "select": False}
    if width:
        p["width"] = width
        props["textAutoResize"] = "height"
    return _add("text.create", p)


def _norm(d):
    """Geser data path absolut (M L H V C Z) agar kotak pembatasnya mulai di 0,0."""
    tok = re.findall(r"[MLHVCZ]|-?\d*\.?\d+", d)
    out, pts, cx, cy, i, cmd = [], [], 0.0, 0.0, 0, None
    while i < len(tok):
        if tok[i] in "MLHVCZ":
            cmd = tok[i]; out.append([cmd]); i += 1
            if cmd == "Z":
                continue
        n = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6}[cmd]
        v = [float(t) for t in tok[i:i + n]]; i += n
        if cmd == "H":
            cx = v[0]; pts.append((cx, cy))
        elif cmd == "V":
            cy = v[0]; pts.append((cx, cy))
        else:
            for a in range(0, n, 2):
                pts.append((v[a], v[a + 1]))
            cx, cy = v[-2], v[-1]
        out[-1].append(v)
    mx = min(p[0] for p in pts); my = min(p[1] for p in pts)
    res = []
    for seg in out:
        c = seg[0]
        if c == "Z":
            res.append("Z"); continue
        for v in seg[1:]:
            if c == "H":
                res.append("H%g" % (v[0] - mx))
            elif c == "V":
                res.append("V%g" % (v[0] - my))
            else:
                nv = [v[a] - (mx if a % 2 == 0 else my) for a in range(len(v))]
                res.append(c + " ".join("%g" % q for q in nv))
    return "".join(res)


def path(parent, d, x, y, w, h, fill=None, stroke=None, sw=2, name="Ikon"):
    props = {}
    props["fill"] = fill if fill else "none"
    if stroke:
        props["stroke"] = stroke
        props["strokeWeight"] = sw
        props["strokeCap"] = "round"
        props["strokeJoin"] = "round"
    return _add("vector.create", {"parent": parent, "path": _norm(d), "x": x, "y": y, "width": w, "height": h, "name": name, "props": props, "select": False})


# ---------- ikon sederhana (kotak 24) ----------
def ikon(parent, jenis, x, y, warna, ukuran=24):
    s = ukuran
    if jenis == "beranda":
        path(parent, "M3 11L12 3L21 11V20H15V14H9V20H3Z", x, y, s, s, stroke=warna, name="ikon beranda")
    elif jenis == "jelajah":
        oval(parent, x + 3, y + 3, s * 0.62, s * 0.62, "none", "ikon jelajah", stroke=warna, sw=2)
        rect(parent, x + s * 0.7, y + s * 0.62, 3, s * 0.34, warna, 1.5, name="ikon jelajah gagang")
        steps[-1]["params"]["props"]["rotation"] = 45
    elif jenis == "rekomendasi":
        path(parent, "M12 2L14.8 8.6L22 9.3L16.6 14L18.2 21L12 17.3L5.8 21L7.4 14L2 9.3L9.2 8.6Z", x, y, s, s, stroke=warna, name="ikon rekomendasi")
    elif jenis == "kalender":
        rect(parent, x + 2, y + 4, s - 4, s - 6, "none", 3, stroke=warna, name="ikon kalender")
        rect(parent, x + 2, y + 9, s - 4, 2, warna, 1, name="ikon kalender garis")
        rect(parent, x + 7, y + 1, 2, 6, warna, 1, name="ikon kalender cincin 1")
        rect(parent, x + s - 9, y + 1, 2, 6, warna, 1, name="ikon kalender cincin 2")
    elif jenis == "profil":
        oval(parent, x + s * 0.3, y + 2, s * 0.4, s * 0.4, "none", "ikon profil kepala", stroke=warna, sw=2)
        rect(parent, x + s * 0.14, y + s * 0.55, s * 0.72, s * 0.38, "none", 0, stroke=warna, name="ikon profil badan")
        steps[-1]["params"]["props"]["cornerRadius"] = [s * 0.3, s * 0.3, 2, 2]
    elif jenis == "lonceng":
        path(parent, "M6 17V11C6 7 8.5 5 12 5C15.5 5 18 7 18 11V17L20 19H4Z", x, y, s, s, stroke=warna, name="ikon lonceng")
    elif jenis == "simpan":
        path(parent, "M6 3H18V21L12 17L6 21Z", x, y, s, s, stroke=warna, name="ikon simpan")
    elif jenis == "dokumen":
        path(parent, "M6 3H14L19 8V21H6Z", x, y, s, s, stroke=warna, name="ikon dokumen")
        path(parent, "M14 3V8H19", x + s * 0.58, y + s * 0.12, s * 0.25, s * 0.2, stroke=warna, name="ikon dokumen lipatan")
    elif jenis == "chat":
        path(parent, "M4 5H20V16H11L6 20V16H4Z", x, y, s, s, stroke=warna, name="ikon chat")
    elif jenis == "panah":
        path(parent, "M15 5L8 12L15 19", x, y, s, s, stroke=warna, name="ikon kembali")
    elif jenis == "centang":
        path(parent, "M5 12L10 17L19 7", x, y, s, s, stroke=warna, sw=2.4, name="ikon centang")


def logo(parent, x, y, ukuran):
    k = ukuran / 64.0
    rect(parent, x, y, ukuran, ukuran, PRIMARY, 15 * k, name="Logo SMART latar")
    path(parent, "M18 30.5L32 37L46 30.5V39.5C46 43.5 39.5 47.5 32 47.5C24.5 47.5 18 43.5 18 39.5Z", x + 18 * k, y + 30.5 * k, 28 * k, 17 * k, fill="#D4E0F0", name="Logo alas topi")
    path(parent, "M32 13L57 24.5L32 36L7 24.5Z", x + 7 * k, y + 13 * k, 50 * k, 23 * k, fill=WHITE, name="Logo topi")
    rect(parent, x + 48.8 * k, y + 27.6 * k, 2.4 * k, 13.4 * k, GOLD, 1.2 * k, name="Logo jumbai")
    path(parent, "M50 40.5L51.7 44.4L55.6 46.1L51.7 47.8L50 51.7L48.3 47.8L44.4 46.1L48.3 44.4Z", x + 44.4 * k, y + 40.5 * k, 11.2 * k, 11.2 * k, fill=GOLD, name="Logo bintang")
    path(parent, "M57.73 44.03L57.35 42.93L56.81 41.90L56.13 40.96L55.32 40.12L54.40 39.42L53.38 38.85", x + 53.4 * k, y + 38.9 * k, 4.3 * k, 5.1 * k, stroke=GOLD, sw=1.8 * k, name="Logo gelombang 1")
    path(parent, "M61.11 43.12L60.56 41.55L59.79 40.06L58.81 38.71L57.65 37.51L56.32 36.49L54.86 35.68", x + 54.9 * k, y + 35.7 * k, 6.2 * k, 7.4 * k, stroke=GOLD, sw=1.8 * k, name="Logo gelombang 2")


# ---------- komponen mobile ----------
def status_bar(f):
    text(f, 24, 14, "9:41", 14, "SemiBold", NAVY)
    rect(f, 330, 17, 28, 12, NAVY, 4, name="baterai")


def app_bar(f, judul=None):
    logo(f, 20, 44, 32)
    text(f, 62, 50, "SMART", 18, "Bold", NAVY, spacing=1)
    rect(f, 330, 46, 40, 40, C2, 20, name="tombol lonceng")
    ikon(f, "lonceng", 338, 54, NAVY)


NAV = [("beranda", "Beranda"), ("rekomendasi", "Rekomendasi"), ("jelajah", "Jelajah"), ("kalender", "Kalender"), ("profil", "Profil")]


def nav_bawah(f, aktif):
    rect(f, 0, 758, 390, 86, KARTU, 28, name="navigasi bawah kapsul")
    steps[-1]["params"]["props"]["cornerRadius"] = [28, 28, 0, 0]
    steps[-1]["params"]["props"]["effects"] = [{"type": "dropShadow", "offset": [0, -4], "radius": 16, "color": "#00000014"}]
    for i, (j, label) in enumerate(NAV):
        cx = 39 + i * 78
        on = j == aktif
        if on:
            rect(f, cx - 28, 772, 56, 30, C3, 15, name="penanda aktif")
        ikon(f, j, cx - 12, 775, PRIMARY if on else MUTED)
        text(f, cx - 39, 808, label, 11, "Bold" if on else "Medium", PRIMARY if on else MUTED, width=78, align="center")


def chip(f, x, y, label, on=False, w=None):
    w = w or (len(label) * 7.4 + 28)
    rect(f, x, y, w, 34, PRIMARY if on else KARTU, 17, stroke=None if on else OUTLINE, name="chip " + label)
    text(f, x, y + 8, label, 13, "SemiBold", WHITE if on else INK, width=w, align="center")
    return x + w + 8


def badge(f, x, y, label, bg, fg):
    w = len(label) * 6.6 + 20
    rect(f, x, y, w, 22, bg, 11, name="lencana " + label)
    text(f, x, y + 4, label, 11, "Bold", fg, width=w, align="center")
    return w


def kartu_beasiswa(f, x, y, w, judul, penyelenggara, tenggat, jenjang, status=None, alasan=None):
    tinggi = 168 if alasan else 140
    rect(f, x, y, w, tinggi, KARTU, 16, stroke=C4, name="kartu " + judul, shadow=True)
    rect(f, x + 16, y + 16, 44, 44, C2, 12, name="logo penyelenggara")
    ikon(f, "rekomendasi", x + 26, y + 26, PRIMARY)
    text(f, x + 70, y + 16, judul, 15, "Bold", NAVY, width=w - 120)
    text(f, x + 70, y + 38, penyelenggara, 12, "Regular", MUTED, width=w - 120)
    ikon(f, "simpan", x + w - 38, y + 16, MUTED, 22)
    bx = x + 16
    bx += badge(f, bx, y + 74, jenjang, C2, NAVY) + 6
    if status:
        badge(f, bx, y + 74, status[0], status[1], status[2])
    m_ = re.search(r"(\d+) hari", tenggat)
    dekat = bool(m_) and int(m_.group(1)) <= 7
    rect(f, x + 16, y + 104, 8, 8, ERR if dekat else SOFT, 4, name="titik tenggat")
    text(f, x + 30, y + 99, tenggat, 12, "SemiBold", ERR if dekat else INK)
    if alasan:
        text(f, x + 16, y + 126, alasan, 12, "Regular", MUTED, width=w - 32)


# ---------- layar mobile ----------
def layar_splash(x):
    f = frame(x, 0, 390, 844, "M1 Pembuka", SURFACE)
    logo(f, 147, 330, 96)
    text(f, 0, 448, "SMART", 28, "Bold", NAVY, width=390, align="center", spacing=2)
    text(f, 0, 486, "Beasiswa yang tepat untukmu", 13, "Regular", MUTED, width=390, align="center")
    return f


def layar_masuk(x):
    f = frame(x, 0, 390, 844, "M2 Masuk", SURFACE)
    status_bar(f)
    logo(f, 163, 90, 64)
    text(f, 0, 168, "SMART", 28, "Bold", NAVY, width=390, align="center")
    text(f, 0, 206, "Pemantauan dan rekomendasi beasiswa", 12, "Regular", MUTED, width=390, align="center")
    text(f, 20, 260, "Masuk ke Akun SMART", 22, "Bold", NAVY)
    text(f, 20, 294, "Akses rekomendasi beasiswa berdasarkan profilmu, pantau tenggat, dan siapkan berkas.", 14, "Regular", INK, width=350, line="150%")
    for i, h in enumerate(["Email", "Kata sandi"]):
        rect(f, 20, 372 + i * 68, 350, 52, KARTU, 8, stroke=OUTLINE, name="kolom " + h)
        text(f, 52, 388 + i * 68, h, 14, "Regular", OUTLINE)
    rect(f, 20, 520, 350, 52, PRIMARY, 12, name="tombol Masuk")
    text(f, 20, 536, "Masuk", 15, "Bold", WHITE, width=350, align="center")
    text(f, 0, 604, "Belum punya akun?  Daftar Akun Baru", 14, "SemiBold", PRIMARY, width=390, align="center")
    return f


def layar_beranda(x):
    f = frame(x, 0, 390, 844, "M3 Beranda", SURFACE)
    status_bar(f)
    app_bar(f)
    rect(f, 20, 100, 350, 300, DEEP, 24, name="hero")
    rect(f, 36, 116, 168, 26, "#FFFFFF", 13, name="chip info", op=0.16)
    text(f, 36, 121, "Semester 5 · S1 · IPK 3.80", 12, "SemiBold", WHITE, width=168, align="center")
    text(f, 36, 154, "Halo, Adam", 28, "Bold", WHITE)
    text(f, 36, 192, "Lihat beasiswa yang paling sesuai dengan profilmu dan tenggat yang perlu dikejar.", 13, "Regular", "#D5E2F6", width=318, line="145%")
    for i, (n, label, warna) in enumerate([("12", "Memenuhi", "#7BE0A4"), ("31", "Hampir memenuhi", "#FFD27A"), ("104", "Belum memenuhi", "#D5E2F6")]):
        cx = 36 + i * 106
        text(f, cx, 244, n, 30, "Bold", warna, width=100, align="center")
        text(f, cx, 284, label, 12, "Medium", WHITE, width=100, align="center")
        if i:
            rect(f, cx - 3, 250, 1, 40, "#FFFFFF", name="pemisah", op=0.25)
    rect(f, 36, 322, 318, 64, "#FFFFFF", 16, name="kartu kelengkapan", op=0.12)
    text(f, 50, 330, "Kelengkapan Profil", 13, "Bold", WHITE)
    rect(f, 50, 354, 230, 6, "#FFFFFF", 3, name="progres latar", op=0.25)
    rect(f, 50, 354, 190, 6, GOLD, 3, name="progres isi")
    text(f, 50, 366, "6 dari 7 data utama terisi", 11, "Regular", "#D5E2F6")
    text(f, 270, 340, "Lengkapi", 13, "Bold", WHITE, width=70, align="right")
    text(f, 20, 420, "Pilihan Utama", 18, "Bold", NAVY)
    text(f, 270, 424, "Lihat semua", 12, "SemiBold", PRIMARY, width=100, align="right")
    kartu_beasiswa(f, 20, 452, 350, "Beasiswa Unggulan", "Kemendikdasmen", "Tenggat 3 hari lagi", "S1", ("Memenuhi", OK_SOFT, OK), "IPK dan jenjangmu sesuai dengan persyaratan.")
    text(f, 20, 636, "Tenggat Terdekat", 18, "Bold", NAVY)
    rect(f, 20, 668, 350, 62, KARTU, 16, stroke=C4, name="baris tenggat", shadow=True)
    rect(f, 32, 680, 38, 38, ERR_SOFT, 12, name="penanda tenggat")
    ikon(f, "kalender", 39, 687, ERR, 24)
    text(f, 82, 680, "Beasiswa Unggulan", 14, "Bold", NAVY, width=270)
    text(f, 82, 702, "Tenggat 3 hari lagi", 12, "SemiBold", ERR)
    nav_bawah(f, "beranda")
    return f


def layar_jelajah(x):
    f = frame(x, 0, 390, 844, "M4 Jelajah", SURFACE)
    status_bar(f)
    app_bar(f)
    text(f, 20, 104, "Jelajah Beasiswa", 26, "Bold", NAVY)
    text(f, 20, 140, "Beasiswa terbit yang tenggatnya belum lewat.", 14, "Regular", INK)
    rect(f, 20, 172, 350, 48, KARTU, 24, stroke=OUTLINE, name="kolom cari")
    ikon(f, "jelajah", 36, 184, MUTED, 22)
    text(f, 68, 186, "Cari nama beasiswa atau penyelenggara", 14, "Regular", OUTLINE)
    cx = 20
    for i, l in enumerate(["Semua", "S1", "S2", "S3", "D3"]):
        cx = chip(f, cx, 232, l, i == 0)
    text(f, 20, 284, "Menampilkan 24 beasiswa", 12, "Regular", MUTED)
    kartu_beasiswa(f, 20, 308, 350, "Beasiswa Unggulan", "Kemendikdasmen", "Tenggat 3 hari lagi", "S1")
    kartu_beasiswa(f, 20, 464, 350, "Australia Awards", "Pemerintah Australia", "Tenggat 9 hari lagi", "S2")
    kartu_beasiswa(f, 20, 620, 350, "Tanoto Scholars", "Tanoto Foundation", "Tenggat 21 hari lagi", "S1")
    nav_bawah(f, "jelajah")
    return f


def layar_rekomendasi(x):
    f = frame(x, 0, 390, 844, "M5 Rekomendasi", SURFACE)
    status_bar(f)
    app_bar(f)
    text(f, 20, 104, "Rekomendasi Beasiswa", 26, "Bold", NAVY)
    text(f, 20, 140, "Dihasilkan Mesin Rekomendasi dari profil akademikmu, lengkap dengan alasan.", 14, "Regular", INK, width=350, line="150%")
    cx = 20
    for i, l in enumerate(["Semua (12)", "Memenuhi (5)", "Hampir (4)", "Belum (3)"]):
        cx = chip(f, cx, 200, l, i == 0)
    kartu_beasiswa(f, 20, 252, 350, "Beasiswa Unggulan", "Kemendikdasmen", "Tenggat 3 hari lagi", "S1", ("Memenuhi", OK_SOFT, OK), "IPK 3,60 memenuhi batas minimum 3,50. Jenjang S1 sesuai.")
    kartu_beasiswa(f, 20, 436, 350, "Australia Awards", "Pemerintah Australia", "Tenggat 9 hari lagi", "S1", ("Hampir memenuhi", C4, NAVY), "Semester 4 dari minimal 5. Syarat lain terpenuhi.")
    nav_bawah(f, "rekomendasi")
    rect(f, 314, 692, 56, 56, PRIMARY, 28, name="tombol chatbot")
    ikon(f, "chat", 330, 708, WHITE)
    return f


def layar_detail(x):
    f = frame(x, 0, 390, 844, "M6 Detail Beasiswa", SURFACE)
    status_bar(f)
    rect(f, 12, 44, 40, 40, C2, 20, name="tombol kembali")
    ikon(f, "panah", 20, 52, NAVY)
    text(f, 20, 100, "Beasiswa Unggulan", 24, "Bold", NAVY, width=350, line="130%")
    text(f, 20, 168, "Kemendikdasmen", 13, "Regular", MUTED)
    bx = 20
    bx += badge(f, bx, 198, "S1", C2, NAVY) + 6
    bx += badge(f, bx, 198, "Memenuhi", OK_SOFT, OK) + 6
    rect(f, 20, 236, 350, 64, ERR_SOFT, 14, name="kotak tenggat")
    text(f, 34, 248, "TENGGAT", 11, "Bold", ERR, spacing=0.5)
    text(f, 34, 268, "3 hari lagi", 16, "Bold", ERR)
    text(f, 20, 320, "Syarat dan kelayakanmu", 16, "Bold", NAVY)
    for i, (s, ok) in enumerate([("IPK minimal 3,50", True), ("Mahasiswa aktif jenjang S1", True), ("Dokumen transkrip nilai", False)]):
        yy = 354 + i * 52
        rect(f, 20, yy, 350, 44, KARTU, 12, stroke=C4, name="syarat " + s)
        rect(f, 32, yy + 11, 22, 22, OK if ok else KARTU, 11, stroke=None if ok else OUTLINE, name="penanda syarat")
        if ok:
            ikon(f, "centang", 33, yy + 12, WHITE, 20)
        text(f, 66, yy + 13, s, 14, "Medium", INK)
    text(f, 20, 524, "Alasan rekomendasi", 16, "Bold", NAVY)
    text(f, 20, 554, "IPK dan jenjangmu sesuai dengan persyaratan. Satu dokumen perlu kamu siapkan sebelum mendaftar. Hasil ini bantuan memilih, bukan jaminan diterima.", 13, "Regular", INK, width=350, line="150%")
    rect(f, 20, 690, 350, 52, PRIMARY, 12, name="tombol laman resmi")
    text(f, 20, 706, "Buka Laman Resmi", 15, "Bold", WHITE, width=350, align="center")
    rect(f, 20, 750, 350, 1, SURFACE, name="spasi")
    return f


def judul(f, t, sub=None):
    text(f, 20, 104, t, 26, "Bold", NAVY)
    if sub:
        text(f, 20, 140, sub, 14, "Regular", INK, width=350, line="150%")


def layar_kalender(x):
    f = frame(x, 0, 390, 844, "M7 Kalender", SURFACE)
    status_bar(f)
    app_bar(f)
    judul(f, "Kalender")
    rect(f, 20, 148, 350, 330, KARTU, 20, stroke=C4, name="kartu bulan", shadow=True)
    text(f, 20, 164, "November 2026", 16, "Bold", NAVY, width=350, align="center")
    ikon(f, "panah", 30, 160, MUTED, 24)
    for i, h in enumerate(["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]):
        text(f, 25 + i * 48, 200, h, 11, "Bold", MUTED, width=48, align="center")
    for d in range(1, 31):
        pos = d + 5  # 1 November 2026 jatuh pada hari Minggu
        r_, c = (pos - 1) // 7, (pos - 1) % 7
        cx, cy = 25 + c * 48, 224 + r_ * 44
        if d == 10:
            rect(f, cx + 6, cy, 36, 36, PRIMARY, 18, name="hari ini")
        text(f, cx, cy + 9, str(d), 14, "Bold" if d in (10, 16, 28) else "Medium", WHITE if d == 10 else (ERR if d in (16, 28) else INK), width=48, align="center")
        if d in (16, 28):
            rect(f, cx + 21, cy + 31, 6, 6, ERR, 3, name="titik tenggat")
    rect(f, 20, 494, 8, 8, ERR, 4, name="legenda")
    text(f, 34, 490, "Tenggat", 12, "Regular", MUTED)
    text(f, 20, 520, "16 November", 16, "Bold", NAVY)
    rect(f, 20, 552, 350, 62, KARTU, 16, stroke=C4, name="acara", shadow=True)
    rect(f, 32, 564, 38, 38, ERR_SOFT, 12, name="penanda")
    ikon(f, "kalender", 39, 571, ERR, 24)
    text(f, 82, 564, "Beasiswa Unggulan", 14, "Bold", NAVY, width=270)
    text(f, 82, 586, "Tenggat pendaftaran", 12, "SemiBold", ERR)
    text(f, 20, 636, "Checklist berkas", 16, "Bold", NAVY)
    for i, (s, ok) in enumerate([("Transkrip nilai", True), ("Surat rekomendasi", False)]):
        yy = 668 + i * 44
        rect(f, 20, yy, 350, 38, KARTU, 12, stroke=C4, name="berkas " + s)
        rect(f, 30, yy + 8, 22, 22, OK if ok else KARTU, 11, stroke=None if ok else OUTLINE, name="kotak centang")
        if ok:
            ikon(f, "centang", 31, yy + 9, WHITE, 20)
        text(f, 62, yy + 10, s, 14, "Medium", INK)
    nav_bawah(f, "kalender")
    return f


def layar_profil(x):
    f = frame(x, 0, 390, 844, "M8 Profil", SURFACE)
    status_bar(f)
    app_bar(f)
    judul(f, "Profil Saya")
    rect(f, 20, 148, 350, 132, DEEP, 24, name="kepala profil")
    oval(f, 36, 164, 56, 56, "#FFFFFF", "avatar")
    steps[-1]["params"]["props"]["opacity"] = 0.2
    text(f, 36, 178, "A", 22, "Bold", WHITE, width=56, align="center")
    text(f, 104, 168, "Adam Rahmadi", 18, "Bold", WHITE)
    text(f, 104, 194, "adam@kampus.ac.id", 13, "Regular", "#D5E2F6")
    text(f, 36, 232, "Kelengkapan data utama: 6 dari 7", 12, "Medium", WHITE)
    rect(f, 36, 254, 318, 8, "#FFFFFF", 4, name="progres latar", op=0.25)
    rect(f, 36, 254, 272, 8, GOLD, 4, name="progres isi")
    rect(f, 20, 296, 350, 252, KARTU, 20, stroke=C4, name="kartu data", shadow=True)
    text(f, 36, 310, "DATA UTAMA", 11, "Bold", MUTED, spacing=0.5)
    for i, (a_, b_) in enumerate([("Jenjang", "S1"), ("Semester", "5"), ("IPK", "3.80"), ("Jenis kampus", "negeri"), ("Kota domisili", "Malang")]):
        yy = 334 + i * 42
        if i:
            rect(f, 36, yy - 4, 318, 1, C4, name="garis")
        text(f, 36, yy + 6, a_, 13, "Regular", MUTED)
        text(f, 200, yy + 6, b_, 14, "SemiBold", NAVY, width=154, align="right")
    rect(f, 20, 564, 350, 168, KARTU, 20, stroke=C4, name="kartu menu", shadow=True)
    for i, (a_, ik) in enumerate([("Profil Lanjutan", "profil"), ("Dokumen Saya", "dokumen"), ("Chatbot AI", "chat"), ("Pengaturan", "lonceng")]):
        yy = 564 + i * 42
        rect(f, 32, yy + 5, 32, 32, C3, 10, name="ikon latar")
        ikon(f, ik, 36, yy + 9, PRIMARY, 24)
        text(f, 76, yy + 12, a_, 14, "Medium", INK)
    nav_bawah(f, "profil")
    return f


def layar_dokumen(x):
    f = frame(x, 0, 390, 844, "M9 Dokumen", SURFACE)
    status_bar(f)
    rect(f, 12, 44, 40, 40, C2, 20, name="tombol kembali")
    ikon(f, "panah", 20, 52, NAVY)
    judul(f, "Dokumen Saya", "Unggah transkrip, CV, atau sertifikat agar IPK dan skor bahasa terisi otomatis.")
    rect(f, 20, 204, 350, 52, PRIMARY, 14, name="tombol unggah")
    text(f, 20, 220, "Unggah Dokumen", 15, "Bold", WHITE, width=350, align="center")
    for i, (a_, b_, st) in enumerate([("Transkrip Nilai Semester 5.pdf", "Terbaca: IPK 3,80", ("Selesai", OK_SOFT, OK)), ("Sertifikat TOEFL.pdf", "Terbaca: skor 520", ("Selesai", OK_SOFT, OK)), ("CV Adam.pdf", "Sedang dibaca", ("Menunggu", C4, NAVY))]):
        yy = 280 + i * 92
        rect(f, 20, yy, 350, 80, KARTU, 16, stroke=C4, name="berkas " + a_, shadow=True)
        rect(f, 32, yy + 14, 44, 52, C2, 10, name="ikon berkas")
        text(f, 88, yy + 14, a_, 14, "Bold", NAVY, width=270)
        text(f, 88, yy + 38, b_, 12, "Regular", MUTED)
        badge(f, 88, yy + 54, st[0], st[1], st[2])
    return f


def layar_chat(x):
    f = frame(x, 0, 390, 844, "M10 Chatbot", SURFACE)
    status_bar(f)
    rect(f, 12, 44, 40, 40, C2, 20, name="tombol kembali")
    ikon(f, "panah", 20, 52, NAVY)
    text(f, 64, 54, "Chatbot Beasiswa", 18, "Bold", NAVY)
    rect(f, 20, 120, 270, 78, KARTU, 18, stroke=C4, name="gelembung bot")
    text(f, 34, 132, "Halo! Tanyakan syarat, tenggat, atau berkas beasiswa. Jawaban saya berdasarkan data di SMART.", 13, "Regular", INK, width=244, line="145%")
    rect(f, 160, 216, 210, 48, PRIMARY, 18, name="gelembung saya")
    text(f, 174, 230, "Beasiswa apa yang tenggatnya dekat?", 13, "Regular", WHITE, width=184)
    rect(f, 20, 282, 300, 130, KARTU, 18, stroke=C4, name="gelembung bot 2")
    text(f, 34, 294, "Ada 2 beasiswa dengan tenggat kurang dari 7 hari: Beasiswa Unggulan (3 hari) dan Beasiswa Riset (6 hari).", 13, "Regular", INK, width=274, line="145%")
    text(f, 34, 380, "Sumber: laman resmi penyelenggara", 11, "Medium", MUTED)
    cx = 20
    for l in ["Syarat IPK", "Berkas apa saja?", "Tenggat minggu ini"]:
        cx = chip(f, cx, 640, l)
    rect(f, 20, 696, 300, 52, KARTU, 26, stroke=OUTLINE, name="kolom pesan")
    text(f, 40, 712, "Tulis pertanyaanmu", 14, "Regular", OUTLINE)
    rect(f, 330, 696, 40, 52, PRIMARY, 20, name="tombol kirim")
    return f


def layar_pengaturan(x):
    f = frame(x, 0, 390, 844, "M11 Pengaturan", SURFACE)
    status_bar(f)
    rect(f, 12, 44, 40, 40, C2, 20, name="tombol kembali")
    ikon(f, "panah", 20, 52, NAVY)
    judul(f, "Pengaturan")
    text(f, 20, 160, "Tampilan", 16, "Bold", NAVY)
    rect(f, 20, 192, 350, 48, C2, 24, name="segmen latar")
    rect(f, 24, 196, 112, 40, PRIMARY, 20, name="segmen aktif")
    for i, l in enumerate(["Sistem", "Terang", "Gelap"]):
        text(f, 24 + i * 114, 207, l, 14, "Bold" if i == 0 else "Medium", WHITE if i == 0 else INK, width=112, align="center")
    text(f, 20, 268, "Pengingat tenggat", 16, "Bold", NAVY)
    for i, l in enumerate(["Pengingat lewat surel", "Pengingat push di ponsel"]):
        yy = 300 + i * 60
        rect(f, 20, yy, 350, 52, KARTU, 14, stroke=C4, name=l)
        text(f, 36, yy + 16, l, 14, "Medium", INK)
        rect(f, 316, yy + 14, 40, 24, PRIMARY, 12, name="sakelar")
        oval(f, 336, yy + 16, 20, 20, "#FFFFFF", "kenop")
    text(f, 20, 444, "Aplikasi", 16, "Bold", NAVY)
    for i, (l, s) in enumerate([("Versi aplikasi", "1.1.0 (4)"), ("Periksa pembaruan", "Unduh versi terbaru bila tersedia"), ("Catatan rilis", "")]):
        yy = 476 + i * 60
        rect(f, 20, yy, 350, 52, KARTU, 14, stroke=C4, name=l)
        text(f, 36, yy + 8 if s else yy + 16, l, 14, "Medium", INK)
        if s:
            text(f, 36, yy + 30, s, 11, "Regular", MUTED)
    return f


# ---------- layar web ----------
def sidebar(f, aktif, tinggi=800, admin=False):
    rect(f, 0, 0, 250, tinggi, KARTU, name="sidebar")
    rect(f, 249, 0, 1, tinggi, C4, name="garis sidebar")
    logo(f, 20, 18, 32)
    text(f, 60, 20, "SMART", 18, "Bold", NAVY, spacing=1)
    text(f, 60, 40, "Pantau beasiswa", 10, "Medium", MUTED)
    menu = [("beranda", "Dashboard"), ("rekomendasi", "Rekomendasi Beasiswa"), ("jelajah", "Jelajah Beasiswa"), ("simpan", "Beasiswa Tersimpan"), ("kalender", "Kalender dan Checklist"), ("dokumen", "Dokumen Saya"), ("chat", "Chatbot AI"), ("profil", "Profil Saya")]
    if admin:
        menu = [("beranda", "Dashboard Admin"), ("rekomendasi", "Antrean Validasi"), ("jelajah", "Kelola Sumber"), ("simpan", "Laporan Sistem")]
    for i, (j, l) in enumerate(menu):
        yy = 88 + i * 46
        on = l == aktif
        if on:
            rect(f, 12, yy, 226, 40, C3, 10, name="menu aktif")
        ikon(f, j, 24, yy + 8, PRIMARY if on else MUTED, 22)
        text(f, 58, yy + 11, l, 14, "Bold" if on else "Medium", PRIMARY if on else INK)


def header_web(f):
    rect(f, 250, 0, 1030, 64, KARTU, name="header")
    rect(f, 250, 63, 1030, 1, C4, name="garis header")
    rect(f, 298, 14, 420, 36, C1, 18, name="kolom cari web")
    ikon(f, "jelajah", 312, 20, MUTED, 22)
    text(f, 346, 23, "Cari nama beasiswa atau penyelenggara", 13, "Regular", MUTED)
    rect(f, 1180, 12, 40, 40, C2, 20, name="lonceng web")
    ikon(f, "lonceng", 1188, 20, NAVY)
    oval(f, 1232, 14, 36, 36, PRIMARY, "avatar")
    text(f, 1232, 22, "AD", 12, "Bold", WHITE, width=36, align="center")


def web_dashboard(y):
    f = frame(0, y, 1280, 800, "W1 Dashboard Web", SURFACE)
    sidebar(f, "Dashboard")
    header_web(f)
    text(f, 298, 92, "Halo, Adam", 28, "Bold", NAVY)
    text(f, 298, 132, "Berikut ringkasan beasiswa dan tenggat terdekat untukmu.", 14, "Regular", INK)
    for i, (n, label, warna) in enumerate([("12", "Rekomendasi", PRIMARY), ("4", "Beasiswa tersimpan", NAVY), ("2", "Tenggat 7 hari", ERR), ("3", "Berkas belum siap", MUTED)]):
        cx = 298 + i * 238
        rect(f, cx, 176, 222, 96, KARTU, 16, stroke=C4, name="metrik " + label, shadow=True)
        text(f, cx + 20, 190, n, 30, "Bold", warna)
        text(f, cx + 20, 236, label, 13, "Medium", MUTED)
    text(f, 298, 300, "Rekomendasi teratas", 18, "Bold", NAVY)
    for i, (a, b, c, d, e) in enumerate([("Beasiswa Unggulan", "Kemendikdasmen", "Tenggat 3 hari lagi", "S1", ("Memenuhi", OK_SOFT, OK)), ("Australia Awards", "Pemerintah Australia", "Tenggat 9 hari lagi", "S1", ("Hampir memenuhi", C4, NAVY))]):
        kartu_beasiswa(f, 298 + i * 358, 336, 340, a, b, c, d, e, "Alasan singkat dari Mesin Rekomendasi.")
    rect(f, 1014, 300, 234, 380, KARTU, 16, stroke=C4, name="panel tenggat", shadow=True)
    text(f, 1034, 318, "Tenggat terdekat", 16, "Bold", NAVY)
    for i, (j, t) in enumerate([("Beasiswa Unggulan", "3 hari lagi"), ("Australia Awards", "9 hari lagi"), ("Tanoto Scholars", "21 hari lagi")]):
        yy = 358 + i * 70
        rect(f, 1034, yy, 194, 58, C1, 12, name="baris tenggat")
        text(f, 1046, yy + 10, j, 13, "Bold", NAVY)
        text(f, 1046, yy + 32, t, 12, "SemiBold", ERR if i == 0 else MUTED)
    return f


def web_jelajah(y):
    f = frame(0, y, 1280, 800, "W2 Jelajah Web", SURFACE)
    sidebar(f, "Jelajah Beasiswa")
    header_web(f)
    text(f, 298, 92, "Jelajah Beasiswa", 28, "Bold", NAVY)
    text(f, 298, 132, "Beasiswa terbit yang tenggatnya belum lewat, dipantau dari laman resmi.", 14, "Regular", INK)
    cx = 298
    for i, l in enumerate(["Semua jenjang", "S1", "S2", "S3", "D3"]):
        cx = chip(f, cx, 172, l, i == 0)
    for r_ in range(2):
        for c in range(3):
            kartu_beasiswa(f, 298 + c * 322, 228 + r_ * 160, 306, ["Beasiswa Unggulan", "Australia Awards", "Tanoto Scholars", "Beasiswa Djarum Plus", "Bank Mega Syariah", "Türkiye Burslari"][r_ * 3 + c], "Kemendikdasmen", "Tenggat %d hari lagi" % (3 + 6 * (r_ * 3 + c)), "S1")
    return f


# ---------- komponen dan layar tambahan (web penuh, mobile Tersimpan dan Keadaan) ----------
def tombol(f, x, y, w, label, primer=True, h=44):
    rect(f, x, y, w, h, PRIMARY if primer else KARTU, 12, stroke=None if primer else OUTLINE, name="tombol " + label)
    text(f, x, y + (h - 18) // 2, label, 14, "Bold", WHITE if primer else PRIMARY, width=w, align="center")


def kolom_isi(f, x, y, w, label, nilai, h=58):
    rect(f, x, y, w, h, KARTU, 12, stroke=OUTLINE, name="kolom " + label)
    text(f, x + 14, y + 8, label, 11, "Medium", MUTED)
    text(f, x + 14, y + 28, nilai, 14, "SemiBold", NAVY, width=w - 28)


def kartu(f, x, y, w, h, nama="kartu"):
    rect(f, x, y, w, h, KARTU, 16, stroke=C4, name=nama, shadow=True)


def sidebar_adm(f, aktif):
    sidebar(f, aktif, admin=True)


def halaman(y, nama, aktif, tinggi=900, admin=False):
    f = frame(0, y, 1280, tinggi, nama, SURFACE)
    sidebar(f, aktif, tinggi, admin)
    header_web(f)
    return f


def web_rekomendasi(y):
    f = halaman(y, "W3 Rekomendasi Web", "Rekomendasi Beasiswa")
    text(f, 298, 92, "Rekomendasi Beasiswa", 28, "Bold", NAVY)
    text(f, 298, 132, "Dihasilkan dari profil akademikmu, lengkap dengan alasan. Hasil ini membantu memilih, bukan jaminan diterima.", 14, "Regular", INK, width=760)
    cx = 298
    for i, l in enumerate(["Semua (12)", "Memenuhi (5)", "Hampir memenuhi (4)", "Belum memenuhi (3)"]):
        cx = chip(f, cx, 176, l, i == 0)
    data = [
        ("Beasiswa Unggulan", "Kemendikdasmen", "Tenggat 3 hari lagi", "S1", ("Memenuhi", OK_SOFT, OK), "IPK 3,60 memenuhi batas 3,50. Jenjang S1 sesuai."),
        ("KIP Kuliah", "Kemdiktisaintek", "Tenggat 9 hari lagi", "S1", ("Memenuhi", OK_SOFT, OK), "Jenjang dan jenis kampus sesuai. Dokumen penghasilan belum diunggah."),
        ("Australia Awards", "Pemerintah Australia", "Tenggat 21 hari lagi", "S2", ("Hampir memenuhi", C4, NAVY), "Skor bahasa belum tercatat. Syarat lain terpenuhi."),
        ("Tanoto Scholars", "Tanoto Foundation", "Tenggat belum diumumkan", "S1", ("Hampir memenuhi", C4, NAVY), "Semester 4 dari minimal 5. Syarat lain terpenuhi."),
    ]
    for i, d in enumerate(data):
        kartu_beasiswa(f, 298 + (i % 2) * 484, 232 + (i // 2) * 188, 466, *d)
    return f


def web_detail(y):
    f = halaman(y, "W4 Detail Beasiswa Web", "Jelajah Beasiswa")
    text(f, 298, 90, "Kembali ke daftar", 13, "SemiBold", PRIMARY)
    text(f, 298, 122, "Beasiswa Unggulan", 30, "Bold", NAVY)
    text(f, 298, 164, "Kemendikdasmen", 14, "Regular", MUTED)
    bx = 298
    bx += badge(f, bx, 196, "S1", C2, NAVY) + 6
    badge(f, bx, 196, "Memenuhi", OK_SOFT, OK)
    text(f, 298, 248, "Syarat dan kelayakanmu", 18, "Bold", NAVY)
    for i, (s, ok) in enumerate([("IPK minimal 3,50 (IPK kamu 3,80)", True), ("Mahasiswa aktif jenjang S1", True), ("Surat keterangan penghasilan orang tua", False), ("Warga negara Indonesia", True)]):
        yy = 284 + i * 56
        rect(f, 298, yy, 580, 48, KARTU, 12, stroke=C4, name="syarat " + s)
        rect(f, 312, yy + 13, 22, 22, OK if ok else KARTU, 11, stroke=None if ok else OUTLINE, name="penanda syarat")
        if ok:
            ikon(f, "centang", 313, yy + 14, WHITE, 20)
        text(f, 348, yy + 15, s, 14, "Medium", INK)
    text(f, 298, 524, "Alasan rekomendasi", 18, "Bold", NAVY)
    text(f, 298, 558, "IPK dan jenjangmu sesuai dengan persyaratan. Satu dokumen perlu disiapkan sebelum mendaftar. Periksa laman resmi penyelenggara untuk syarat terbaru.", 14, "Regular", INK, width=580, line="155%")
    text(f, 298, 650, "Berkas yang diminta", 18, "Bold", NAVY)
    for i, s in enumerate(["Transkrip nilai", "Surat keterangan penghasilan orang tua", "Surat rekomendasi dosen"]):
        rect(f, 298, 686 + i * 44, 580, 38, C1, 10, name="berkas " + s)
        text(f, 314, 696 + i * 44, s, 14, "Medium", INK)
    kartu(f, 922, 92, 326, 330, "panel aksi")
    rect(f, 938, 108, 294, 72, ERR_SOFT, 14, name="kotak tenggat")
    text(f, 954, 120, "TENGGAT", 11, "Bold", ERR, spacing=0.5)
    text(f, 954, 142, "3 hari lagi", 20, "Bold", ERR)
    tombol(f, 938, 200, 294, "Buka Laman Resmi")
    tombol(f, 938, 256, 294, "Simpan Beasiswa", False)
    tombol(f, 938, 312, 294, "Tanya Chatbot", False)
    text(f, 938, 376, "Sumber: laman resmi penyelenggara, diperiksa 16 November 2026.", 12, "Regular", MUTED, width=294, line="145%")
    return f


def web_kalender(y):
    f = halaman(y, "W5 Kalender Web", "Kalender dan Checklist")
    text(f, 298, 92, "Kalender dan Checklist", 28, "Bold", NAVY)
    text(f, 298, 132, "Tenggat beasiswa yang kamu simpan dan berkas yang perlu disiapkan.", 14, "Regular", INK)
    kartu(f, 298, 176, 560, 440, "kartu bulan")
    text(f, 298, 196, "November 2026", 18, "Bold", NAVY, width=560, align="center")
    ikon(f, "panah", 320, 192, MUTED, 24)
    for i, h in enumerate(["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]):
        text(f, 314 + i * 76, 244, h, 12, "Bold", MUTED, width=76, align="center")
    for d in range(1, 31):
        pos = d + 5
        r_, c = (pos - 1) // 7, (pos - 1) % 7
        cx, cy = 314 + c * 76, 272 + r_ * 60
        if d == 16:
            rect(f, cx + 18, cy, 40, 40, PRIMARY, 20, name="hari ini")
        text(f, cx, cy + 11, str(d), 15, "Bold" if d in (16, 19, 25) else "Medium", WHITE if d == 16 else (ERR if d in (19, 25) else INK), width=76, align="center")
        if d in (19, 25):
            rect(f, cx + 35, cy + 42, 6, 6, ERR, 3, name="titik tenggat")
    kartu(f, 882, 176, 366, 210, "panel hari")
    text(f, 902, 194, "19 November", 18, "Bold", NAVY)
    for i, (a_, b_) in enumerate([("Beasiswa Unggulan", "Tenggat pendaftaran"), ("KIP Kuliah", "Tenggat verifikasi berkas")]):
        yy = 232 + i * 70
        rect(f, 902, yy, 326, 58, C1, 12, name="acara " + a_)
        text(f, 918, yy + 10, a_, 14, "Bold", NAVY)
        text(f, 918, yy + 32, b_, 12, "SemiBold", ERR)
    kartu(f, 882, 402, 366, 214, "panel checklist")
    text(f, 902, 420, "Checklist berkas", 16, "Bold", NAVY)
    for i, (s, ok) in enumerate([("Transkrip nilai", True), ("Surat keterangan penghasilan", False), ("Surat rekomendasi dosen", False)]):
        yy = 456 + i * 48
        rect(f, 902, yy, 22, 22, OK if ok else KARTU, 11, stroke=None if ok else OUTLINE, name="kotak centang")
        if ok:
            ikon(f, "centang", 903, yy + 1, WHITE, 20)
        text(f, 936, yy + 2, s, 14, "Medium", INK)
    return f


def web_profil(y):
    f = halaman(y, "W6 Profil Web", "Profil Saya")
    text(f, 298, 92, "Profil Saya", 28, "Bold", NAVY)
    text(f, 298, 132, "Data ini dipakai mesin rekomendasi. Perbarui bila ada perubahan.", 14, "Regular", INK)
    rect(f, 298, 176, 950, 112, DEEP, 24, name="kepala profil")
    oval(f, 322, 200, 64, 64, "#FFFFFF", "avatar")
    steps[-1]["params"]["props"]["opacity"] = 0.2
    text(f, 322, 218, "A", 26, "Bold", WHITE, width=64, align="center")
    text(f, 404, 204, "Adam Rahmadi", 22, "Bold", WHITE)
    text(f, 404, 236, "UIN Malang  ·  Teknik Informatika  ·  S1 semester 5", 13, "Regular", "#D5E2F6")
    text(f, 900, 204, "Data utama: 6 dari 7", 13, "SemiBold", WHITE, width=320, align="right")
    rect(f, 900, 236, 320, 8, "#FFFFFF", 4, name="progres latar", op=0.25)
    rect(f, 900, 236, 274, 8, GOLD, 4, name="progres isi")
    kartu(f, 298, 308, 466, 420, "kartu data utama")
    text(f, 318, 326, "DATA UTAMA", 11, "Bold", MUTED, spacing=0.5)
    for i, (a_, b_) in enumerate([("Jenjang", "S1"), ("Semester", "5"), ("IPK", "3,80"), ("Jenis kampus", "Negeri"), ("Kota domisili", "Malang"), ("Penghasilan orang tua", "Rp3.500.000")]):
        kolom_isi(f, 318 + (i % 2) * 222, 354 + (i // 2) * 72, 210, a_, b_)
    kartu(f, 782, 308, 466, 420, "kartu data lanjutan")
    text(f, 802, 326, "PROFIL LANJUTAN (OPSIONAL)", 11, "Bold", MUTED, spacing=0.5)
    for i, (a_, b_) in enumerate([("Program studi", "Teknik Informatika"), ("Minat", "Teknologi, riset"), ("Skor bahasa", "TOEFL 520"), ("Kewarganegaraan", "Indonesia")]):
        kolom_isi(f, 802 + (i % 2) * 222, 354 + (i // 2) * 72, 210, a_, b_)
    tombol(f, 802, 660, 200, "Simpan Perubahan")
    return f


def web_dokumen(y):
    f = halaman(y, "W7 Dokumen Web", "Dokumen Saya")
    text(f, 298, 92, "Dokumen Saya", 28, "Bold", NAVY)
    text(f, 298, 132, "Unggah transkrip, CV, atau sertifikat agar IPK dan skor bahasa terisi otomatis. Periksa hasil bacanya.", 14, "Regular", INK, width=760)
    rect(f, 298, 176, 950, 120, KARTU, 20, stroke=OUTLINE, name="area unggah")
    text(f, 298, 206, "Tarik berkas ke sini atau pilih dari komputer", 16, "Bold", NAVY, width=950, align="center")
    text(f, 298, 234, "PDF, DOCX, TXT, atau foto (PNG, JPG). Maksimal 5 MB per berkas.", 13, "Regular", MUTED, width=950, align="center")
    tombol(f, 708, 252, 130, "Pilih Berkas", True, 36)
    for i, (a_, b_, st) in enumerate([("Transkrip Nilai Semester 5.pdf", "Terbaca: IPK 3,80", ("Selesai", OK_SOFT, OK)), ("Sertifikat TOEFL.pdf", "Terbaca: skor 520", ("Selesai", OK_SOFT, OK)), ("CV Adam.pdf", "Sedang dibaca", ("Menunggu", C4, NAVY))]):
        yy = 320 + i * 96
        kartu(f, 298, yy, 950, 82, "berkas " + a_)
        rect(f, 316, yy + 14, 44, 54, C2, 10, name="ikon berkas")
        text(f, 376, yy + 16, a_, 15, "Bold", NAVY)
        text(f, 376, yy + 42, b_, 13, "Regular", MUTED)
        badge(f, 1110, yy + 30, st[0], st[1], st[2])
        text(f, 1170, yy + 31, "Koreksi", 13, "Bold", PRIMARY)
    return f


def web_chat(y):
    f = halaman(y, "W8 Chat Web", "Chatbot AI")
    text(f, 298, 92, "Chatbot Beasiswa", 28, "Bold", NAVY)
    text(f, 298, 132, "Jawaban disusun dari data beasiswa di SMART, bukan dari ingatan model.", 14, "Regular", INK)
    kartu(f, 298, 176, 700, 640, "area chat")
    rect(f, 318, 196, 420, 70, C1, 16, name="gelembung bot")
    text(f, 334, 208, "Halo! Tanyakan syarat, tenggat, atau berkas beasiswa. Saya menjawab dari data di SMART.", 14, "Regular", INK, width=388, line="145%")
    rect(f, 618, 290, 360, 48, PRIMARY, 16, name="gelembung saya")
    text(f, 634, 304, "Beasiswa apa yang tenggatnya dekat?", 14, "Regular", WHITE, width=330)
    rect(f, 318, 362, 520, 120, C1, 16, name="gelembung bot 2")
    text(f, 334, 374, "Ada 2 beasiswa dengan tenggat kurang dari 7 hari: Beasiswa Unggulan (3 hari) dan KIP Kuliah (6 hari).", 14, "Regular", INK, width=488, line="145%")
    text(f, 334, 448, "Sumber: laman resmi penyelenggara", 12, "Medium", MUTED)
    cx = 318
    for l in ["Syarat IPK", "Berkas apa saja?", "Tenggat minggu ini"]:
        cx = chip(f, cx, 700, l)
    rect(f, 318, 748, 590, 52, KARTU, 26, stroke=OUTLINE, name="kolom pesan")
    text(f, 342, 764, "Tulis pertanyaanmu", 14, "Regular", OUTLINE)
    rect(f, 920, 748, 58, 52, PRIMARY, 26, name="tombol kirim")
    kartu(f, 1022, 176, 226, 250, "panel sumber")
    text(f, 1040, 194, "Sumber jawaban", 15, "Bold", NAVY)
    for i, s in enumerate(["Beasiswa Unggulan", "KIP Kuliah"]):
        rect(f, 1040, 232 + i * 62, 190, 50, C1, 10, name="sumber " + s)
        text(f, 1052, 240 + i * 62, s, 13, "Bold", NAVY)
        text(f, 1052, 260 + i * 62, "Lihat laman resmi", 12, "SemiBold", PRIMARY)
    return f


def web_masuk(y):
    f = frame(0, y, 1280, 800, "W9 Masuk Web", SURFACE)
    rect(f, 0, 0, 560, 800, DEEP, name="panel kiri")
    logo(f, 64, 64, 48)
    text(f, 126, 74, "SMART", 24, "Bold", WHITE, spacing=1)
    text(f, 64, 250, "Temukan beasiswa yang layak kamu kejar.", 34, "Bold", WHITE, width=430, line="125%")
    for i, s in enumerate(["Dipantau dari laman resmi penyelenggara", "Rekomendasi lengkap dengan alasannya", "Pengingat tenggat dan checklist berkas"]):
        rect(f, 64, 420 + i * 52, 24, 24, GOLD, 12, name="penanda")
        ikon(f, "centang", 66, 422 + i * 52, DEEP, 20)
        text(f, 100, 422 + i * 52, s, 15, "Medium", "#D5E2F6")
    text(f, 64, 724, "Hasil rekomendasi membantu memilih, bukan jaminan diterima.", 12, "Regular", "#D5E2F6", width=430)
    text(f, 660, 190, "Masuk ke Akun SMART", 28, "Bold", NAVY)
    text(f, 660, 234, "Gunakan email yang kamu daftarkan.", 14, "Regular", INK)
    kolom_isi(f, 660, 290, 460, "Email", "adam@kampus.ac.id")
    kolom_isi(f, 660, 362, 460, "Kata sandi", "••••••••••")
    text(f, 1000, 440, "Lupa kata sandi?", 13, "SemiBold", PRIMARY, width=120, align="right")
    tombol(f, 660, 480, 460, "Masuk", True, 52)
    text(f, 660, 560, "Belum punya akun?  Daftar Akun Baru", 14, "SemiBold", PRIMARY, width=460, align="center")
    return f


def web_tersimpan(y):
    f = halaman(y, "W10 Tersimpan Web", "Beasiswa Tersimpan")
    text(f, 298, 92, "Beasiswa Tersimpan", 28, "Bold", NAVY)
    text(f, 298, 132, "Beasiswa yang kamu tandai. Lengkapi berkasnya sebelum tenggat.", 14, "Regular", INK)
    data = [("Beasiswa Unggulan", "Kemendikdasmen", "Tenggat 3 hari lagi", "S1", "2 dari 3 berkas siap"), ("KIP Kuliah", "Kemdiktisaintek", "Tenggat 9 hari lagi", "S1", "1 dari 4 berkas siap"), ("Australia Awards", "Pemerintah Australia", "Tenggat 21 hari lagi", "S2", "0 dari 5 berkas siap")]
    for i, (a_, b_, c_, d_, e_) in enumerate(data):
        x = 298 + i * 322
        kartu_beasiswa(f, x, 176, 306, a_, b_, c_, d_)
        kartu(f, x, 328, 306, 64, "progres berkas")
        text(f, x + 16, 340, e_, 12, "SemiBold", INK)
        rect(f, x + 16, 366, 274, 6, C3, 3, name="progres latar")
        rect(f, x + 16, 366, 274 * (2, 1, 0)[i] / (3, 4, 5)[i], 6, OK, 3, name="progres isi")
    return f


def web_admin(y):
    f = halaman(y, "W11 Antrean Validasi Admin", "Antrean Validasi", admin=True)
    text(f, 298, 92, "Antrean Validasi", 28, "Bold", NAVY)
    text(f, 298, 132, "Beasiswa yang belum terbit dan perlu diperiksa admin.", 14, "Regular", INK)
    cx = 298
    for i, l in enumerate(["Menunggu (87)", "Perlu diperiksa (12)", "Ditolak (94)"]):
        cx = chip(f, cx, 172, l, i == 0)
    kartu(f, 298, 224, 950, 460, "tabel antrean")
    for j, (h_, x_) in enumerate([("BEASISWA", 318), ("SUMBER", 640), ("ALASAN DITANDAI", 800), ("", 1130)]):
        text(f, x_, 242, h_, 11, "Bold", MUTED, spacing=0.5)
    rect(f, 298, 270, 950, 1, C4, name="garis")
    baris = [("Beasiswa Strata 1 Kab Gianyar", "INDBeasiswa", "Laman tidak menjelaskan beasiswa ini"), ("Community College Initiative", "AMINEF", "robots.txt melarang pengambilan"), ("Beasiswa Pendidikan Kota Blitar", "Kemahasiswaan UIN", "Isi laman terlalu sedikit"), ("Beasiswa Peduli Pendidikan", "INDBeasiswa", "Tenggat tidak tertulis"), ("Program Magang Mahasiswa", "Info Beasiswa", "Bukan untuk jenjang kuliah")]
    for i, (a_, b_, c_) in enumerate(baris):
        yy = 284 + i * 76
        text(f, 318, yy + 6, a_, 14, "Bold", NAVY, width=300)
        text(f, 640, yy + 6, b_, 13, "Regular", INK, width=150)
        text(f, 800, yy + 6, c_, 13, "Regular", INK, width=320)
        tombol(f, 1130, yy, 100, "Periksa", False, 36)
        rect(f, 318, yy + 62, 910, 1, C4, name="garis")
    return f


def web_keadaan(y):
    f = frame(0, y, 1280, 520, "W12 Keadaan Web", SURFACE)
    text(f, 40, 24, "Keadaan layar: memuat, kosong, galat", 20, "Bold", NAVY)
    for i, nama in enumerate(["Memuat", "Kosong", "Galat"]):
        x = 40 + i * 410
        kartu(f, x, 72, 390, 400, nama)
        text(f, x + 20, 88, nama.upper(), 11, "Bold", MUTED, spacing=0.5)
    for i in range(3):
        yy = 120 + i * 104
        rect(f, 60, yy, 350, 88, C1, 14, name="skeleton kartu")
        rect(f, 76, yy + 14, 44, 44, C3, 10, name="skeleton logo")
        rect(f, 132, yy + 16, 200, 12, C3, 6, name="skeleton judul")
        rect(f, 132, yy + 38, 130, 10, C2, 5, name="skeleton baris")
        rect(f, 76, yy + 68, 90, 10, C2, 5, name="skeleton lencana")
    rect(f, 530, 130, 120, 120, C2, 60, name="ilustrasi kosong")
    ikon(f, "simpan", 566, 166, PRIMARY, 48)
    text(f, 450, 270, "Belum ada beasiswa tersimpan", 17, "Bold", NAVY, width=350, align="center")
    text(f, 450, 302, "Simpan beasiswa dari halaman Jelajah atau Rekomendasi agar tenggatnya muncul di kalender.", 13, "Regular", INK, width=350, align="center", line="150%")
    tombol(f, 540, 376, 170, "Jelajah Beasiswa")
    rect(f, 940, 130, 120, 120, ERR_SOFT, 60, name="ilustrasi galat")
    text(f, 940, 160, "!", 56, "Bold", ERR, width=120, align="center")
    text(f, 860, 270, "Data belum bisa dimuat", 17, "Bold", NAVY, width=350, align="center")
    text(f, 860, 302, "Periksa koneksi internetmu, lalu coba lagi. Datamu aman dan tidak berubah.", 13, "Regular", INK, width=350, align="center", line="150%")
    tombol(f, 950, 376, 150, "Coba Lagi")
    return f


# ---------- mobile tambahan ----------
def layar_tersimpan(x):
    f = frame(x, 0, 390, 844, "M12 Tersimpan", SURFACE)
    status_bar(f)
    rect(f, 12, 44, 40, 40, C2, 20, name="tombol kembali")
    ikon(f, "panah", 20, 52, NAVY)
    judul(f, "Beasiswa Tersimpan", "Lengkapi berkasnya sebelum tenggat.")
    for i, (a_, b_, c_, d_, e_) in enumerate([("Beasiswa Unggulan", "Kemendikdasmen", "Tenggat 3 hari lagi", "S1", "2 dari 3 berkas siap"), ("KIP Kuliah", "Kemdiktisaintek", "Tenggat 9 hari lagi", "S1", "1 dari 4 berkas siap")]):
        yy = 188 + i * 216
        kartu_beasiswa(f, 20, yy, 350, a_, b_, c_, d_)
        text(f, 20, yy + 150, e_, 12, "SemiBold", INK)
        rect(f, 20, yy + 172, 350, 6, C3, 3, name="progres latar")
        rect(f, 20, yy + 172, 350 * (2 / 3, 1 / 4)[i], 6, OK, 3, name="progres isi")
    return f


def layar_keadaan(x):
    f = frame(x, 0, 390, 844, "M13 Keadaan", SURFACE)
    status_bar(f)
    judul(f, "Keadaan layar")
    text(f, 20, 140, "MEMUAT", 11, "Bold", MUTED, spacing=0.5)
    for i in range(2):
        yy = 160 + i * 78
        rect(f, 20, yy, 350, 68, C1, 14, name="skeleton kartu")
        rect(f, 34, yy + 14, 40, 40, C3, 10, name="skeleton logo")
        rect(f, 86, yy + 16, 180, 12, C3, 6, name="skeleton judul")
        rect(f, 86, yy + 38, 110, 10, C2, 5, name="skeleton baris")
    text(f, 20, 332, "KOSONG", 11, "Bold", MUTED, spacing=0.5)
    kartu(f, 20, 352, 350, 140, "keadaan kosong")
    text(f, 36, 368, "Belum ada beasiswa tersimpan", 15, "Bold", NAVY, width=318)
    text(f, 36, 394, "Simpan dari Jelajah atau Rekomendasi agar tenggatnya muncul di kalender.", 13, "Regular", INK, width=318, line="145%")
    tombol(f, 36, 440, 150, "Jelajah", True, 40)
    text(f, 20, 516, "GALAT", 11, "Bold", MUTED, spacing=0.5)
    rect(f, 20, 536, 350, 130, ERR_SOFT, 16, name="keadaan galat")
    text(f, 36, 552, "Data belum bisa dimuat", 15, "Bold", ERR, width=318)
    text(f, 36, 578, "Datamu aman. Coba lagi beberapa saat lagi.", 13, "Regular", INK, width=318)
    tombol(f, 36, 614, 120, "Coba Lagi", False, 40)
    text(f, 20, 690, "TANPA JARINGAN", 11, "Bold", MUTED, spacing=0.5)
    rect(f, 20, 710, 350, 52, C4, 14, name="pita tanpa jaringan")
    text(f, 36, 726, "Tidak ada koneksi. Menampilkan data terakhir.", 13, "Medium", NAVY, width=318)
    return f


# ---------- susun ----------
def bagian_identitas():
    """Logo, palet, ilustrasi, komponen skor, dan rancangan kartu: satu berkas desain bersama layar-layar di atas."""
    import build_identitas as BI
    import build_ilustrasi as BL
    import build_kartu as BK
    import svg_ke_figcraft as SK

    bagian = [
        ("Identitas: logo, palet, ilustrasi pendamping", BI.svg_identitas()[0], 1180, 900),
        ("Komponen: cincin skor, tab wilayah, chip", BI.svg_komponen()[0], 1180, 760),
        ("Ilustrasi gaya pastel", BL.svg_teks(), 1176, 792),
        ("Kartu skor: Beranda, Detail, Jelajah web", BK.svg_teks(), 1480, 1380),
    ]
    x, y = 0, 2400
    for nama, teks, w, h in bagian:
        f = _add("frame.create", {"x": x, "y": y, "width": w, "height": h, "name": nama, "props": {"fill": "#F3F6FB", "clip": True}, "select": False})
        SK.impor(teks, _add, f, 0, 0)
        x += w + 120


def main():
    ids = {}
    mobile = [layar_splash, layar_masuk, layar_beranda, layar_jelajah, layar_rekomendasi, layar_detail, layar_kalender, layar_profil, layar_dokumen, layar_chat, layar_pengaturan, layar_tersimpan, layar_keadaan]
    web = [web_dashboard, web_jelajah, web_rekomendasi, web_detail, web_kalender, web_profil, web_dokumen, web_chat, web_masuk, web_tersimpan, web_admin, web_keadaan]
    for baris, gelap in enumerate([False, True]):
        tema(gelap)
        _DY[0] = baris * 1000
        for i, fn in enumerate(mobile):
            ids[("G" if gelap else "T") + "M%d" % (i + 1)] = fn(i * 430)
        _DY[0] = 0
        for i, fn in enumerate(web):
            ids[("G" if gelap else "T") + "W%d" % (i + 1)] = fn(2000 + baris * 12500 + i * 1000)
    tema(False)
    _DY[0] = 0
    bagian_identitas()
    script = os.path.join(AQUA, "out", "smart-ui.script.json")
    os.makedirs(os.path.dirname(script), exist_ok=True)
    json.dump(steps, open(script, "w", encoding="utf-8"))
    out = os.path.join(AQUA, "smart-ui.figcraft")
    r = subprocess.run([FC, "run", script, "--out", out], capture_output=True, text=True)
    gagal = [l for l in r.stdout.splitlines() if '"ok":false' in l]
    print("langkah:", len(steps), "gagal:", len(gagal))
    for l in gagal[:5]:
        print(l[:300])
    if r.stderr.strip():
        print(r.stderr[:400])
    # cek id simpul yang diprediksi sesuai hasil sebenarnya
    sesuai = True
    for l in r.stdout.splitlines():
        j = json.loads(l)
        if j["command"] == "frame.create" and j["result"]["id"] not in ids.values():
            sesuai = False
    print("id sesuai prediksi:", sesuai)
    rdir = os.path.join(AQUA, "render")
    os.makedirs(rdir, exist_ok=True)
    e = subprocess.run([FC, "export", out, "--out", rdir, "--format", "png", "--scale", "1"], capture_output=True, text=True)
    print("ekspor:", (e.stdout or e.stderr)[:200].strip())
    return ids


if __name__ == "__main__":
    print(json.dumps(main()))
