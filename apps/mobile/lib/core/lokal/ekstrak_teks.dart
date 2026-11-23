import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Pembaca teks berkas di ponsel tanpa jaringan: bagian Dart murni (zip dan XML), tanpa plugin.
/// PDF dan gambar ada di `ekstrak_dokumen.dart` karena butuh PDFium dan OCR.

/// Batas teks hasil ekstraksi (karakter). Lebih dari ini dipotong.
const int teksMaks = 120000;

class EkstrakGagal implements Exception {
  EkstrakGagal(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

const _teksBiasa = {
  'txt', 'md', 'markdown', 'csv', 'tsv', 'json', 'jsonl', 'xml', 'yaml', 'yml', //
  'log', 'ini', 'cfg', 'toml', 'srt', 'vtt', 'tex', 'sql', 'py', 'js', 'ts',
  'dart', 'kt', 'java', 'c', 'cpp', 'h', 'cs', 'go', 'rs', 'rb', 'php', 'sh',
  'bat', 'ps1', 'css', 'gradle', 'properties', 'env', 'rst', 'org',
};
const _gambar = {'png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif', 'heic', 'heif'};

String ekstensiDari(String nama) {
  final i = nama.lastIndexOf('.');
  return i < 0 ? '' : nama.substring(i + 1).toLowerCase();
}

bool adalahGambar(String ext) => _gambar.contains(ext);
bool adalahPdf(String ext) => ext == 'pdf';

/// Apakah [ext] dibaca tanpa plugin (teks biasa atau zip XML)?
bool didukungMurni(String ext) =>
    _teksBiasa.contains(ext) ||
    const {
      'html', 'htm', 'xhtml', 'rtf', 'docx', 'docm', 'pptx', 'xlsx', 'xlsm', //
      'odt', 'ods', 'odp', 'epub',
    }.contains(ext);

/// Mengekstrak teks dari [bytes] berdasarkan ekstensi. Dipanggil di isolat (`compute`) agar UI tidak tersendat.
String teksDariBytes(String ext, Uint8List bytes) {
  final String teks;
  if (_teksBiasa.contains(ext)) {
    teks = utf8.decode(bytes, allowMalformed: true);
  } else {
    switch (ext) {
      case 'html' || 'htm' || 'xhtml':
        teks = teksDariHtml(utf8.decode(bytes, allowMalformed: true));
      case 'rtf':
        teks = teksDariRtf(latin1.decode(bytes));
      case 'docx' || 'docm':
        teks = teksDariDocx(bytes);
      case 'pptx':
        teks = teksDariPptx(bytes);
      case 'xlsx' || 'xlsm':
        teks = teksDariXlsx(bytes);
      case 'odt' || 'ods' || 'odp':
        teks = teksDariOdf(bytes);
      case 'epub':
        teks = teksDariEpub(bytes);
      case 'doc' || 'xls' || 'ppt':
        throw EkstrakGagal(
          'Format lama (.$ext) belum bisa dibaca di ponsel. Simpan ulang sebagai .${ext}x atau PDF.',
        );
      default:
        throw EkstrakGagal('Jenis berkas .$ext belum didukung di ponsel.');
    }
  }
  return rapikan(teks);
}

String rapikan(String s) => s
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n')
    .replaceAll(RegExp(r'[ \t\u00a0]+\n'), '\n')
    .replaceAll(RegExp(r'[ \t\u00a0]{3,}'), '  ')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

Archive _zip(Uint8List b) {
  try {
    return ZipDecoder().decodeBytes(b);
  } on Object {
    throw EkstrakGagal('Berkas rusak atau bukan format Office yang benar.');
  }
}

String _isi(ArchiveFile f) =>
    utf8.decode(f.readBytes() ?? Uint8List(0), allowMalformed: true);

XmlDocument _xml(String s) {
  try {
    return XmlDocument.parse(s);
  } on Object {
    throw EkstrakGagal('Isi berkas tidak dapat dibaca.');
  }
}

/// Menelusuri XML: teks di elemen [teks] ditulis, [baris] mengakhiri baris, [sel] memberi tab antar sel.
/// [semua]: seluruh simpul teks ditulis (ODF menaruh teks langsung di elemen paragraf).
void _jalan(
  XmlNode n,
  StringBuffer b, {
  Set<String> teks = const {},
  Set<String> baris = const {},
  Set<String> sel = const {},
  bool semua = false,
}) {
  if (b.length > teksMaks * 2) return;
  if (n is XmlText) {
    if (semua) b.write(n.value);
    return;
  }
  if (n is! XmlElement) return;
  final nama = n.name.local;
  if (nama == 'tab') b.write('\t');
  if (nama == 'br' || nama == 'line-break') b.write('\n');
  if (nama == 's' && semua) b.write(' ');
  if (teks.contains(nama)) {
    b.write(n.innerText);
    return;
  }
  for (final c in n.children) {
    _jalan(c, b, teks: teks, baris: baris, sel: sel, semua: semua);
  }
  if (sel.contains(nama)) b.write('\t');
  if (baris.contains(nama)) b.write('\n');
}

String teksDariDocx(Uint8List bytes) {
  final z = _zip(bytes);
  final utama = z.findFile('word/document.xml');
  if (utama == null) throw EkstrakGagal('Bukan berkas Word (.docx) yang valid.');
  final b = StringBuffer();
  _jalan(
    _xml(_isi(utama)).rootElement,
    b,
    teks: const {'t'},
    baris: const {'p', 'tr'},
    sel: const {'tc'},
  );
  return b.toString();
}

int _angka(String nama) =>
    int.tryParse(RegExp(r'(\d+)\.xml$').firstMatch(nama)?.group(1) ?? '') ?? 0;

String teksDariPptx(Uint8List bytes) {
  final z = _zip(bytes);
  final slide = [
    for (final f in z)
      if (f.isFile && RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(f.name)) f,
  ]..sort((a, b) => _angka(a.name).compareTo(_angka(b.name)));
  if (slide.isEmpty) throw EkstrakGagal('Bukan berkas PowerPoint (.pptx) yang valid.');
  final b = StringBuffer();
  for (final f in slide) {
    b.writeln('--- Slide ${_angka(f.name)} ---');
    _jalan(
      _xml(_isi(f)).rootElement,
      b,
      teks: const {'t'},
      baris: const {'p'},
    );
    b.writeln();
  }
  return b.toString();
}

String teksDariXlsx(Uint8List bytes) {
  final z = _zip(bytes);
  final bersama = <String>[];
  final ss = z.findFile('xl/sharedStrings.xml');
  if (ss != null) {
    for (final si in _xml(_isi(ss)).findAllElements('si')) {
      bersama.add(
        si.descendantElements
            .where((e) => e.name.local == 't' && e.parentElement?.name.local != 'rPh')
            .map((e) => e.innerText)
            .join(),
      );
    }
  }
  final nama = <String>[];
  final wb = z.findFile('xl/workbook.xml');
  if (wb != null) {
    for (final s in _xml(_isi(wb)).findAllElements('sheet')) {
      nama.add(s.getAttribute('name') ?? '');
    }
  }
  final lembar = [
    for (final f in z)
      if (f.isFile && RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(f.name)) f,
  ]..sort((a, b) => _angka(a.name).compareTo(_angka(b.name)));
  if (lembar.isEmpty) throw EkstrakGagal('Bukan berkas Excel (.xlsx) yang valid.');
  final b = StringBuffer();
  for (var i = 0; i < lembar.length; i++) {
    b.writeln('--- Lembar ${i < nama.length && nama[i].isNotEmpty ? nama[i] : i + 1} ---');
    var jumlah = 0;
    for (final r in _xml(_isi(lembar[i])).findAllElements('row')) {
      final sel = <String>[];
      for (final c in r.findElements('c')) {
        final tipe = c.getAttribute('t');
        final v = c.getElement('v')?.innerText;
        String isi;
        if (tipe == 's') {
          final k = int.tryParse(v ?? '');
          isi = k != null && k < bersama.length ? bersama[k] : '';
        } else if (tipe == 'inlineStr') {
          isi = c.getElement('is')?.innerText ?? '';
        } else if (tipe == 'b') {
          isi = v == '1' ? 'TRUE' : 'FALSE';
        } else {
          isi = v ?? '';
        }
        sel.add(isi.trim());
      }
      if (sel.any((x) => x.isNotEmpty)) {
        b.writeln(sel.join('\t').trimRight());
        if (++jumlah >= 1000 || b.length > teksMaks * 2) break;
      }
    }
    b.writeln();
  }
  return b.toString();
}

String teksDariOdf(Uint8List bytes) {
  final z = _zip(bytes);
  final isi = z.findFile('content.xml');
  if (isi == null) throw EkstrakGagal('Bukan berkas OpenDocument yang valid.');
  final b = StringBuffer();
  _jalan(
    _xml(_isi(isi)).rootElement,
    b,
    baris: const {'p', 'h', 'table-row'},
    sel: const {'table-cell'},
    semua: true,
  );
  return b.toString();
}

String teksDariEpub(Uint8List bytes) {
  final z = _zip(bytes);
  final bab = [
    for (final f in z)
      if (f.isFile && RegExp(r'\.(x?html?)$', caseSensitive: false).hasMatch(f.name)) f,
  ]..sort((a, b) => a.name.compareTo(b.name));
  if (bab.isEmpty) throw EkstrakGagal('Bukan berkas EPUB yang valid.');
  final b = StringBuffer();
  for (final f in bab) {
    b.writeln(teksDariHtml(_isi(f)));
    b.writeln();
    if (b.length > teksMaks * 2) break;
  }
  return b.toString();
}

const _entitas = {
  'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' ', //
  'ndash': '-', 'mdash': '-', 'hellip': '...',
};

String teksDariHtml(String html) {
  var s = html
      .replaceAll(RegExp(r'<(script|style|head|noscript)\b[\s\S]*?</\1>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<!--[\s\S]*?-->'), ' ')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</(p|div|li|tr|h\d|section|article|table)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</t[dh]>', caseSensitive: false), '\t')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  s = s.replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z]+);'), (m) {
    final k = m.group(1)!;
    if (k.startsWith('#')) {
      final kode = k.startsWith('#x') || k.startsWith('#X')
          ? int.tryParse(k.substring(2), radix: 16)
          : int.tryParse(k.substring(1));
      return kode == null ? '' : String.fromCharCode(kode);
    }
    return _entitas[k.toLowerCase()] ?? '';
  });
  return s;
}

String teksDariRtf(String rtf) {
  var s = rtf
      .replaceAll(RegExp(r'\{\\\*[^{}]*\}'), '')
      .replaceAll(RegExp(r'\\par[d]?\b ?'), '\n')
      .replaceAll(RegExp(r'\\(line|tab)\b ?'), '\t')
      .replaceAllMapped(
        RegExp(r"\\'([0-9a-fA-F]{2})"),
        (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
      )
      .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), '')
      .replaceAll(RegExp(r'\\([\\{}])'), r'$1')
      .replaceAll(RegExp(r'[{}]'), '');
  s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s;
}

/// Memilih bagian [teks] yang paling berkaitan dengan [pertanyaan] agar muat di konteks model kecil:
/// awal dokumen selalu ikut (CV biasanya memuat identitas di atas), sisanya potongan dengan kata kunci terbanyak.
String potongRelevan(String teks, String pertanyaan, {int batas = 6000}) {
  if (teks.length <= batas) return teks;
  final awal = teks.substring(0, batas ~/ 4);
  final sisa = teks.substring(batas ~/ 4);
  final potong = <String>[];
  for (var i = 0; i < sisa.length; i += 700) {
    potong.add(sisa.substring(i, i + 700 > sisa.length ? sisa.length : i + 700));
  }
  final kata = RegExp(r'[a-zA-Z]{4,}')
      .allMatches(pertanyaan.toLowerCase())
      .map((m) => m.group(0)!)
      .toSet();
  final skor = [
    for (var i = 0; i < potong.length; i++)
      (
        i,
        kata.where((k) => potong[i].toLowerCase().contains(k)).length,
      ),
  ]..sort((a, b) => b.$2 != a.$2 ? b.$2 - a.$2 : a.$1 - b.$1);
  final dipilih = <int>[];
  var sisaBatas = batas - awal.length;
  for (final (i, _) in skor) {
    if (sisaBatas < potong[i].length) break;
    dipilih.add(i);
    sisaBatas -= potong[i].length;
  }
  dipilih.sort();
  return '$awal\n[...]\n${dipilih.map((i) => potong[i]).join('\n[...]\n')}';
}
