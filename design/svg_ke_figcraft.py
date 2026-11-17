"""Mengubah SVG sederhana (rect, circle, ellipse, polygon, path, line, text, g, linearGradient) menjadi
perintah FigCraft berlapis asli, agar logo, ilustrasi, dan komponen baru ikut berada di satu berkas desain utama
(smart-ui.figcraft) dan tetap dapat disunting. Hanya mendukung bagian SVG yang dipakai build_ilustrasi.py,
build_kartu.py, dan berkas logo."""
import re
import xml.etree.ElementTree as ET

NS = "{http://www.w3.org/2000/svg}"
BOBOT = {"400": "Regular", "500": "Medium", "600": "SemiBold", "700": "Bold", "800": "ExtraBold"}


def _tag(e):
    return e.tag.replace(NS, "")


def _num(v, d=0.0):
    try:
        return float(v)
    except (TypeError, ValueError):
        return d


def _gradien(root):
    hasil = {}
    for g in root.iter(NS + "linearGradient"):
        stops = [s.get("stop-color") for s in g.findall(NS + "stop")]
        hasil[g.get("id")] = {
            "type": "linearGradient",
            "stops": stops,
            "from": [_num(g.get("x1")), _num(g.get("y1"))],
            "to": [_num(g.get("x2")), _num(g.get("y2"), 1)],
        }
    return hasil


def _isi(e, grad, warisan=None):
    f = e.get("fill", None)
    if f is None:
        return {}
    if f == "none":
        return {"fill": "none"}
    m = re.match(r"url\(#(.+)\)", f)
    if m and m.group(1) in grad:
        return {"fills": [grad[m.group(1)]]}
    return {"fill": f}


def _gaya(e, grad):
    p = _isi(e, grad)
    if "fill" not in p and "fills" not in p:
        if _tag(e) in ("line",):
            p["fill"] = "none"
        elif e.get("stroke") and e.get("fill") is None:
            p["fill"] = "#000000"
    if e.get("stroke"):
        p["stroke"] = e.get("stroke")
        p["strokeWeight"] = _num(e.get("stroke-width"), 1)
        if e.get("stroke-linecap"):
            p["strokeCap"] = e.get("stroke-linecap")
        if e.get("stroke-linejoin"):
            p["strokeJoin"] = e.get("stroke-linejoin")
    if e.get("opacity") is not None:
        p["opacity"] = _num(e.get("opacity"), 1)
    if e.get("rx") and _tag(e) == "rect":
        p["cornerRadius"] = _num(e.get("rx"))
    return p


def _transform(t):
    """Mengembalikan (tx, ty, rotasi, pivot) untuk transform 'translate(x y) rotate(a [cx cy])'."""
    tx = ty = 0.0
    rot = 0.0
    pivot = None
    cxy = (0.0, 0.0)
    for nama, arg in re.findall(r"(\w+)\(([^)]*)\)", t or ""):
        v = [float(x) for x in re.split(r"[ ,]+", arg.strip()) if x]
        if nama == "translate":
            tx += v[0]
            ty += v[1] if len(v) > 1 else 0
        elif nama == "rotate":
            rot = v[0]
            cxy = (v[1] if len(v) > 1 else 0.0, v[2] if len(v) > 2 else 0.0)
            pivot = (tx + cxy[0], ty + cxy[1])
    return tx, ty, rot, pivot, cxy


def impor(svg_teks, add, parent, ox=0.0, oy=0.0):
    """Menambahkan isi SVG ke FigCraft lewat add(command, params) di dalam frame parent; ox dan oy menggeser semuanya."""
    root = ET.fromstring(svg_teks)
    grad = _gradien(root)
    _walk(root, grad, add, parent, ox, oy)


def _walk(node, grad, add, parent, ox, oy):
    for e in node:
        t = _tag(e)
        if t in ("defs", "style", "filter", "linearGradient", "clipPath"):
            continue
        if t == "g":
            tx, ty, rot, pivot, cxy = _transform(e.get("transform"))
            nama = e.get("id") or "Grup"
            if rot:
                px, py = pivot
                R = 260.0
                f = add("frame.create", {"parent": parent, "x": px - R + ox, "y": py - R + oy, "width": 2 * R, "height": 2 * R, "name": nama,
                                           "props": {"fill": "none", "clip": False, "rotation": rot}, "select": False})
                _walk(e, grad, add, f, R - cxy[0], R - cxy[1])
            elif tx or ty:
                f = add("frame.create", {"parent": parent, "x": tx + ox, "y": ty + oy, "width": 1, "height": 1, "name": nama,
                                           "props": {"fill": "none", "clip": False}, "select": False})
                _walk(e, grad, add, f, 0, 0)
            else:
                _walk(e, grad, add, parent, ox, oy)
            continue
        p = _gaya(e, grad)
        if t == "rect":
            add("shape.rectangle", {"parent": parent, "x": _num(e.get("x")) + ox, "y": _num(e.get("y")) + oy, "width": _num(e.get("width")),
                                     "height": _num(e.get("height")), "name": "Kotak", "props": p, "select": False})
        elif t in ("circle", "ellipse"):
            rx = _num(e.get("r")) if t == "circle" else _num(e.get("rx"))
            ry = rx if t == "circle" else _num(e.get("ry"))
            add("shape.ellipse", {"parent": parent, "x": _num(e.get("cx")) - rx + ox, "y": _num(e.get("cy")) - ry + oy, "width": 2 * rx, "height": 2 * ry,
                                   "name": "Lingkaran", "props": p, "select": False})
        elif t == "polygon":
            pts = [float(v) for v in re.split(r"[ ,]+", e.get("points").strip())]
            titik = [[pts[i] + ox, pts[i + 1] + oy] for i in range(0, len(pts), 2)]
            add("vector.create", {"parent": parent, "points": titik, "closed": True, "name": "Bentuk", "props": p, "select": False})
        elif t == "path":
            add("vector.create", {"parent": parent, "path": e.get("d"), "x": ox, "y": oy, "name": "Bentuk", "props": p, "select": False})
        elif t == "line":
            a = [_num(e.get("x1")) + ox, _num(e.get("y1")) + oy]
            b = [_num(e.get("x2")) + ox, _num(e.get("y2")) + oy]
            add("vector.create", {"parent": parent, "points": [a, b], "closed": False, "name": "Garis", "props": p, "select": False})
        elif t == "text":
            ukuran = _num(e.get("font-size"), 14)
            anchor = e.get("text-anchor", "start")
            lebar = max(40.0, len(e.text or "") * ukuran * 0.62 + 16)
            x = _num(e.get("x")) + ox
            y = _num(e.get("y")) + oy - ukuran * 0.82
            rata = "left"
            if anchor == "middle":
                x -= lebar / 2
                rata = "center"
            elif anchor == "end":
                x -= lebar
                rata = "right"
            props = {"fill": e.get("fill", "#000000"), "fontFamily": "Inter", "fontStyle": BOBOT.get(e.get("font-weight", "400"), "Regular"),
                     "fontSize": ukuran, "textAlign": rata, "textAutoResize": "height"}
            if e.get("letter-spacing"):
                props["letterSpacing"] = _num(e.get("letter-spacing"))
            add("text.create", {"parent": parent, "x": x, "y": y, "width": lebar, "text": e.text or "", "name": (e.text or "Teks")[:24], "props": props,
                                 "select": False})
