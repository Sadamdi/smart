import 'package:dio/dio.dart';

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

  Future<void> hapus(String id) => _api.delete('/me/dokumen/$id');
}
