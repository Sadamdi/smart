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
    a.add({'jenis': jenis, 'path': salinan, 'nama': nama});
    await _tulisAntrean(a);
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
      if (a.isEmpty) return;
      final sisa = <Map<String, dynamic>>[];
      var putus = false;
      for (final x in a) {
        final f = File('${x['path']}');
        if (!f.existsSync()) continue;
        if (putus) {
          sisa.add(x);
          continue;
        }
        try {
          await unggah(jenis: '${x['jenis']}', path: f.path, nama: '${x['nama']}');
          f.deleteSync();
        } on ApiException catch (e) {
          sisa.add(x);
          if (e.galatJaringan) putus = true;
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
