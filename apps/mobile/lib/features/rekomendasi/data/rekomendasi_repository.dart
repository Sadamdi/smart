import '../../../core/api_client.dart';
import '../domain/rekomendasi.dart';

class RekomendasiRepository {
  RekomendasiRepository(this._api);

  final ApiClient _api;

  Future<List<Rekomendasi>> daftar({
    Kategori? kategori,
    String? wilayah,
    int? batas,
    String urut = 'peluang',
    int minPeluang = 0,
  }) async {
    final r = await _api.get(
      '/rekomendasi',
      query: {
        'kategori': kategori?.kode,
        'wilayah': wilayah,
        'batas': batas,
        'urut': urut,
        'min_peluang': minPeluang == 0 ? null : minPeluang,
      },
    );
    return [
      for (final x in r.data as List)
        Rekomendasi.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<RingkasanRekomendasi> ringkasan({String? wilayah}) async {
    final r = await _api.get(
      '/rekomendasi/ringkasan',
      query: {'wilayah': wilayah},
    );
    return RingkasanRekomendasi.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> hitungUlang() => _api.post('/rekomendasi/hitung-ulang');
}
