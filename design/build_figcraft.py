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


FONT = "Inter"  # Plus Jakarta Sans dipakai di aplikasi; di berkas desain offline memakai Inter bawaan FigCraft

steps = []
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
    p = {"x": x, "y": y, "width": w, "height": h, "name": name, "props": props, "select": False}
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
    dekat = "tenggat" in tenggat.lower() and "hari" in tenggat.lower()
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
    text(f, 0, 206, "Scholarship Monitoring & Recommendation Tool", 12, "Regular", MUTED, width=390, align="center")
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
    kartu_beasiswa(f, 20, 452, 350, "Beasiswa Prestasi Akademik", "Penyelenggara Contoh", "Tenggat 3 hari lagi", "S1", ("Memenuhi", OK_SOFT, OK), "IPK dan jenjangmu sesuai dengan persyaratan.")
    text(f, 20, 636, "Tenggat Terdekat", 18, "Bold", NAVY)
    rect(f, 20, 668, 350, 62, KARTU, 16, stroke=C4, name="baris tenggat", shadow=True)
    rect(f, 32, 680, 38, 38, ERR_SOFT, 12, name="penanda tenggat")
    ikon(f, "kalender", 39, 687, ERR, 24)
    text(f, 82, 680, "Beasiswa Prestasi Akademik", 14, "Bold", NAVY, width=270)
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
    kartu_beasiswa(f, 20, 308, 350, "Beasiswa Prestasi Akademik", "Penyelenggara Contoh", "Tenggat 3 hari lagi", "S1")
    kartu_beasiswa(f, 20, 464, 350, "Beasiswa Riset Mahasiswa", "Lembaga Contoh", "Tenggat 9 hari lagi", "S2")
    kartu_beasiswa(f, 20, 620, 350, "Beasiswa Kepemimpinan", "Yayasan Contoh", "Tenggat 21 hari lagi", "S1")
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
    kartu_beasiswa(f, 20, 252, 350, "Beasiswa Prestasi Akademik", "Penyelenggara Contoh", "Tenggat 3 hari lagi", "S1", ("Memenuhi", OK_SOFT, OK), "IPK 3,60 memenuhi batas minimum 3,50. Jenjang S1 sesuai.")
    kartu_beasiswa(f, 20, 436, 350, "Beasiswa Riset Mahasiswa", "Lembaga Contoh", "Tenggat 9 hari lagi", "S1", ("Hampir memenuhi", C4, NAVY), "Semester 4 dari minimal 5. Syarat lain terpenuhi.")
    nav_bawah(f, "rekomendasi")
    rect(f, 314, 692, 56, 56, PRIMARY, 28, name="tombol chatbot")
    ikon(f, "chat", 330, 708, WHITE)
    return f


def layar_detail(x):
    f = frame(x, 0, 390, 844, "M6 Detail Beasiswa", SURFACE)
    status_bar(f)
    rect(f, 12, 44, 40, 40, C2, 20, name="tombol kembali")
    ikon(f, "panah", 20, 52, NAVY)
    text(f, 20, 100, "Beasiswa Prestasi Akademik", 24, "Bold", NAVY, width=350, line="130%")
    text(f, 20, 168, "Penyelenggara Contoh", 13, "Regular", MUTED)
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
    text(f, 82, 564, "Beasiswa Prestasi Akademik", 14, "Bold", NAVY, width=270)
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
    for i, (a_, ik) in enumerate([("Profil Lanjutan", "profil"), ("Dokumen Saya", "simpan"), ("Chatbot AI", "chat"), ("Pengaturan", "lonceng")]):
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
    text(f, 34, 294, "Ada 2 beasiswa dengan tenggat kurang dari 7 hari: Beasiswa Prestasi Akademik (3 hari) dan Beasiswa Riset (6 hari).", 13, "Regular", INK, width=274, line="145%")
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
def sidebar(f, aktif):
    rect(f, 0, 0, 250, 800, KARTU, name="sidebar")
    rect(f, 249, 0, 1, 800, C4, name="garis sidebar")
    logo(f, 20, 18, 32)
    text(f, 60, 20, "SMART", 18, "Bold", NAVY, spacing=1)
    text(f, 60, 40, "Scholarship Assistant", 10, "Medium", MUTED)
    menu = [("beranda", "Dashboard"), ("rekomendasi", "Rekomendasi Beasiswa"), ("jelajah", "Jelajah Beasiswa"), ("kalender", "Kalender dan Checklist"), ("simpan", "Dokumen Saya"), ("chat", "Chatbot AI"), ("profil", "Profil Saya")]
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
    text(f, 298, 22, "Portal Akademik  >  Mahasiswa", 13, "Medium", MUTED)
    rect(f, 700, 14, 300, 36, C1, 18, name="kolom cari web")
    text(f, 746, 22, "Cari beasiswa", 13, "Regular", MUTED)
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
    for i, (a, b, c, d, e) in enumerate([("Beasiswa Prestasi Akademik", "Penyelenggara Contoh", "Tenggat 3 hari lagi", "S1", ("Memenuhi", OK_SOFT, OK)), ("Beasiswa Riset Mahasiswa", "Lembaga Contoh", "Tenggat 9 hari lagi", "S1", ("Hampir memenuhi", C4, NAVY))]):
        kartu_beasiswa(f, 298 + i * 358, 336, 340, a, b, c, d, e, "Alasan singkat dari Mesin Rekomendasi.")
    rect(f, 1014, 300, 234, 380, KARTU, 16, stroke=C4, name="panel tenggat", shadow=True)
    text(f, 1034, 318, "Tenggat terdekat", 16, "Bold", NAVY)
    for i, (j, t) in enumerate([("Prestasi Akademik", "3 hari lagi"), ("Riset Mahasiswa", "9 hari lagi"), ("Kepemimpinan", "21 hari lagi")]):
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
            kartu_beasiswa(f, 298 + c * 322, 228 + r_ * 160, 306, ["Beasiswa Prestasi Akademik", "Beasiswa Riset Mahasiswa", "Beasiswa Kepemimpinan", "Beasiswa Seni dan Budaya", "Beasiswa Wirausaha", "Beasiswa Daerah"][r_ * 3 + c], "Penyelenggara Contoh", "Tenggat %d hari lagi" % (3 + 6 * (r_ * 3 + c)), "S1")
    return f


# ---------- susun ----------
def main():
    ids = {}
    mobile = [layar_splash, layar_masuk, layar_beranda, layar_jelajah, layar_rekomendasi, layar_detail, layar_kalender, layar_profil, layar_dokumen, layar_chat, layar_pengaturan]
    ids_all = {}
    for baris, gelap in enumerate([False, True]):
        tema(gelap)
        for i, fn in enumerate(mobile):
            fid = fn(i * 430)
            if gelap:
                steps[-len(steps) + 0:]  # no-op
            ids_all[("G" if gelap else "T") + "M%d" % (i + 1)] = fid
        if not gelap:
            # geser baris gelap ke bawah: simpan indeks langkah awal
            awal_gelap = len(steps)
    # geser frame tingkat atas pada baris gelap
    for st in steps[awal_gelap:]:
        if st["command"] == "frame.create" and "parent" not in st["params"]:
            st["params"]["y"] = 1000
    tema(False)
    ids["W1"] = web_dashboard(2000)
    ids["W2"] = web_jelajah(2900)
    ids.update(ids_all)
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
