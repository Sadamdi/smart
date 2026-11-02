import '../../../core/api_client.dart';
import '../domain/notifikasi.dart';

class NotifikasiRepository {
  NotifikasiRepository(this._api);

  final ApiClient _api;

  Future<List<Notifikasi>> daftar() async {
    final r = await _api.get('/notifikasi');
    return [
      for (final x in r.data as List)
        Notifikasi.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<void> baca(String id) => _api.put('/notifikasi/$id/baca');

  Future<void> bacaSemua() => _api.put('/notifikasi/baca-semua');
}
