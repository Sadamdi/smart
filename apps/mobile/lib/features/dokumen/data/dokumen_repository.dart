import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/api_client.dart';
import '../domain/dokumen.dart';

class DokumenRepository {
  DokumenRepository(this._api);

  final ApiClient _api;

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
