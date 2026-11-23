import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import 'ekstrak_teks.dart';

class HasilEkstrak {
  const HasilEkstrak(this.teks, {this.catatan});

  final String teks;

  /// Keterangan untuk pengguna: dipotong, hasil OCR, atau hanya sebagian halaman.
  final String? catatan;
}

/// Membaca teks berkas di ponsel (tanpa jaringan): teks biasa, HTML, RTF, Word, PowerPoint, Excel, OpenDocument,
/// EPUB, PDF (halaman hasil pindai dibaca dengan OCR), dan gambar (OCR). Berkas .doc, .xls, .ppt lama tidak didukung.
class EkstrakDokumen {
  /// Halaman PDF yang dibaca dan halaman hasil pindai yang di-OCR (OCR lambat).
  static const halamanMaks = 40;
  static const ocrHalamanMaks = 6;

  static Future<HasilEkstrak> baca(String path, String nama) async {
    final ext = ekstensiDari(nama);
    String? catatan;
    String teks;
    if (adalahPdf(ext)) {
      (teks, catatan) = await _pdf(path);
    } else if (adalahGambar(ext)) {
      teks = await _ocrBerkas(path);
      catatan = 'Dibaca dengan OCR; huruf yang kabur bisa keliru.';
    } else {
      final bytes = await File(path).readAsBytes();
      teks = await compute(_dariBytes, (ext, bytes));
    }
    teks = teks.trim();
    if (teks.length < 20) {
      throw EkstrakGagal(
        adalahPdf(ext) || adalahGambar(ext)
            ? 'Tidak ada teks yang terbaca. Pastikan gambar atau pindaian cukup jelas.'
            : 'Berkas tidak memuat teks yang bisa dibaca.',
      );
    }
    if (teks.length > teksMaks) {
      teks = teks.substring(0, teksMaks);
      catatan = [catatan, 'Hanya bagian awal yang dibaca.'].whereType<String>().join(' ');
    }
    return HasilEkstrak(teks, catatan: catatan);
  }

  static Future<(String, String?)> _pdf(String path) async {
    await pdfrxFlutterInitialize();
    PdfDocument doc;
    try {
      doc = await PdfDocument.openFile(path);
    } on Object {
      throw EkstrakGagal('PDF tidak dapat dibuka (rusak atau dikunci kata sandi).');
    }
    try {
      final b = StringBuffer();
      final n = min(doc.pages.length, halamanMaks);
      var ocr = 0;
      var dipindai = 0;
      for (var i = 0; i < n && b.length < teksMaks; i++) {
        final t = (await doc.pages[i].loadText())?.fullText.trim() ?? '';
        if (t.length >= 20) {
          b.writeln(t);
          continue;
        }
        dipindai++;
        if (ocr < ocrHalamanMaks) {
          ocr++;
          b.writeln(await _ocrHalaman(doc.pages[i]));
        }
      }
      final catatan = <String>[
        if (doc.pages.length > n) 'Hanya $n halaman pertama yang dibaca.',
        if (ocr > 0) 'Halaman hasil pindai dibaca dengan OCR.',
        if (dipindai > ocr) 'Sebagian halaman pindaian tidak dibaca (batas $ocrHalamanMaks).',
      ];
      return (b.toString(), catatan.isEmpty ? null : catatan.join(' '));
    } finally {
      await doc.dispose();
    }
  }

  static Future<String> _ocrHalaman(PdfPage page) async {
    const lebar = 1500.0;
    final tinggi = lebar * page.height / page.width;
    final gambar = await page.render(
      width: lebar.toInt(),
      height: tinggi.toInt(),
      fullWidth: lebar,
      fullHeight: tinggi,
      backgroundColor: 0xFFFFFFFF,
    );
    if (gambar == null) return '';
    try {
      final png = img.encodePng(
        img.Image.fromBytes(
          width: gambar.width,
          height: gambar.height,
          bytes: gambar.pixels.buffer,
          order: img.ChannelOrder.bgra,
          numChannels: 4,
        ),
      );
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/ocr-${DateTime.now().microsecondsSinceEpoch}.png');
      await f.writeAsBytes(png);
      try {
        return await _ocrBerkas(f.path);
      } finally {
        if (f.existsSync()) f.deleteSync();
      }
    } finally {
      gambar.dispose();
    }
  }

  static Future<String> _ocrBerkas(String path) async {
    final pengenal = TextRecognizer();
    try {
      final r = await pengenal.processImage(InputImage.fromFilePath(path));
      return r.text;
    } on Object {
      throw EkstrakGagal('Gambar tidak dapat dibaca. Coba foto yang lebih jelas.');
    } finally {
      await pengenal.close();
    }
  }
}

String _dariBytes((String, Uint8List) a) => teksDariBytes(a.$1, a.$2);
