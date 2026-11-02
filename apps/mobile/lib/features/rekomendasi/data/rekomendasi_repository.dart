import '../../../core/api_client.dart';
import '../domain/rekomendasi.dart';

class RekomendasiRepository {
  RekomendasiRepository(this._api);

  final ApiClient _api;

  Future<List<Rekomendasi>> daftar({Kategori? kategori}) async {
    final r = await _api.get(
      '/rekomendasi',
      query: {'kategori': kategori?.kode},
    );
    return [
      for (final x in r.data as List)
        Rekomendasi.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<RingkasanRekomendasi> ringkasan() async {
    final r = await _api.get('/rekomendasi/ringkasan');
    return RingkasanRekomendasi.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> hitungUlang() => _api.post('/rekomendasi/hitung-ulang');
}
