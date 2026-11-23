import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get/get.dart' show Get, Inst;
import 'package:path_provider/path_provider.dart';

import '../../../core/api_client.dart';
import '../../../core/lokal/mesin_lokal.dart';
import '../domain/dokumen.dart';

class DokumenRepository {
  DokumenRepository(this._api);

  final ApiClient _api;

  /// Jenis berkas yang dibaca server. Yang lain dibaca di ponsel lalu diunggah sebagai teks.
  static const jenisServer = ['pdf', 'docx', 'txt', 'png', 'jpg', 'jpeg'];

  // ---------- antrean unggah saat tanpa jaringan ----------

  Future<File> _berkasAntrean() async {
    final d = Directory('${(await getApplicationSupportDirectory()).path}/antrean_dokumen');
    if (!d.existsSync()) d.createSync(recursive: true);
    return File('${d.path}/antrean.json');
  }

  Future<List<Map<String, dynamic>>> _bacaAntrean() async {
    try {
      final f = await _berkasAntrean();
      if (!f.existsSync()) return [];
      return [
        for (final x in jsonDecode(await f.readAsString()) as List)
          Map<String, dynamic>.from(x as Map),
      ];
    } on Object {
      return [];
    }
  }

  Future<void> _tulisAntrean(List<Map<String, dynamic>> a) async =>
      (await _berkasAntrean()).writeAsString(jsonEncode(a));

  /// Menyimpan salinan berkas dan mencatatnya agar diunggah otomatis saat ada jaringan.
  Future<void> antrekan({
    required String jenis,
    required String path,
    required String nama,
  }) async {
    final dir = (await _berkasAntrean()).parent.path;
    final salinan = '$dir/${DateTime.now().microsecondsSinceEpoch}-${nama.replaceAll(RegExp(r'[^\w.\- ]'), '_')}';
    await File(path).copy(salinan);
    final a = await _bacaAntrean();
    a.add({
      'jenis': jenis,
      'path': salinan,
      'nama': nama,
      'dibuat': DateTime.now().toIso8601String(),
    });
    await _tulisAntrean(a);
  }

  /// Membuang berkas di folder antrean yang tidak tercatat lagi (sisa dari kegagalan sebelumnya).
  Future<void> _bersihkanYatim(List<Map<String, dynamic>> a) async {
    final dir = (await _berkasAntrean()).parent;
    final dipakai = {for (final x in a) '${x['path']}'};
    for (final e in dir.listSync()) {
      if (e is File && !e.path.endsWith('antrean.json') && !dipakai.contains(e.path) &&
          DateTime.now().difference(e.lastModifiedSync()) > const Duration(minutes: 10)) {
        try {
          e.deleteSync();
        } on Object {
          // diabaikan
        }
      }
    }
  }

  Future<int> jumlahTertunda() async => (await _bacaAntrean()).length;

  bool _mengirimTertunda = false;

  /// Mengunggah berkas yang diantrekan saat luring. Berhenti diam-diam bila jaringan masih putus atau mode luring aktif.
  Future<void> kirimTertunda() async {
    if (_mengirimTertunda) return;
    if (Get.isRegistered<MesinLokal>() && Get.find<MesinLokal>().aktif.value) {
      return;
    }
    _mengirimTertunda = true;
    try {
      final a = await _bacaAntrean();
      await _bersihkanYatim(a);
      if (a.isEmpty) return;
      final sisa = <Map<String, dynamic>>[];
      var putus = false;
      for (final x in a) {
        final f = File('${x['path']}');
        if (!f.existsSync()) continue;
        final umur = DateTime.now().difference(
          DateTime.tryParse('${x['dibuat']}') ?? DateTime.now(),
        );
        if (umur > const Duration(days: 14)) {
          f.deleteSync(); // terlalu lama menunggu: dibuang agar tidak menumpuk
          continue;
        }
        if (putus) {
          sisa.add(x);
          continue;
        }
        try {
          await unggah(jenis: '${x['jenis']}', path: f.path, nama: '${x['nama']}');
          f.deleteSync();
        } on ApiException catch (e) {
          if (e.galatJaringan) {
            sisa.add(x);
            putus = true;
          } else if (e.status >= 400 && e.status < 500 && e.status != 401 && e.status != 408 && e.status != 429) {
            f.deleteSync(); // ditolak server (mis. terlalu besar atau jenis tak didukung): tak dicoba lagi
          } else {
            sisa.add(x);
          }
        } on Object {
          sisa.add(x);
        }
      }
      await _tulisAntrean(sisa);
    } finally {
      _mengirimTertunda = false;
    }
  }

  Future<List<Dokumen>> daftar() async {
    final r = await _api.get('/me/dokumen');
    return [
      for (final x in r.data as List)
        Dokumen.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<Dokumen> unggah({
    required String jenis,
    required String path,
    required String nama,
  }) async {
    final form = FormData.fromMap({
      'jenis': jenis,
      'berkas': await MultipartFile.fromFile(path, filename: nama),
    });
    final r = await _api.post('/me/dokumen', body: form);
    return Dokumen.fromJson(r.data as Map<String, dynamic>);
  }

  /// Mengunduh berkas asli ke folder sementara dan mengembalikan jalurnya.
  Future<String> unduhAsli(String id, String nama) async {
    final dir = await getTemporaryDirectory();
    final aman = nama.replaceAll(RegExp(r'[^\w.\- ]'), '_');
    final f = File('${dir.path}/$id-$aman');
    await _api.unduh('/me/dokumen/$id/berkas', f.path);
    return f.path;
  }

  Future<void> hapus(String id) => _api.delete('/me/dokumen/$id');
}
