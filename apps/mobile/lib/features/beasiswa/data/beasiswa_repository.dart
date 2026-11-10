import '../../../core/api_client.dart';
import '../domain/beasiswa.dart';

class BeasiswaRepository {
  BeasiswaRepository(this._api);

  final ApiClient _api;

  Future<HalamanBeasiswa> daftar({
    String? q,
    String? jenjang,
    String? kursor,
    int batas = 10,
  }) async {
    final r = await _api.get(
      '/beasiswa',
      query: {'q': q, 'jenjang': jenjang, 'kursor': kursor, 'batas': batas},
    );
    return HalamanBeasiswa([
      for (final x in r.data as List)
        BeasiswaRingkas.fromJson(x as Map<String, dynamic>),
    ], r.meta?['kursor_berikut'] as String?);
  }

  Future<BeasiswaDetail> detail(String id) async {
    final r = await _api.get('/beasiswa/$id');
    return BeasiswaDetail.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> catatKlik(String id) =>
      _api.post('/beasiswa/$id/interaksi', body: {'aksi': 'klik'});

  Future<void> simpan(String id) =>
      _api.post('/beasiswa/$id/interaksi', body: {'aksi': 'simpan'});

  Future<void> hapusSimpan(String id) =>
      _api.delete('/beasiswa/$id/interaksi/simpan');

  Future<void> rencanaDaftar(String id, String status) => _api.post(
    '/beasiswa/$id/interaksi',
    body: {'aksi': 'rencana_daftar', 'status_rencana': status},
  );

  Future<Set<String>> idTersimpan() async {
    final r = await _api.get('/me/tersimpan');
    return {
      for (final x in r.data as List)
        ((x as Map<String, dynamic>)['beasiswa'] as Map<String, dynamic>)['id']
            as String,
    };
  }

  /// Beasiswa yang disimpan pengguna, sesuai urutan dari server.
  Future<List<BeasiswaRingkas>> daftarTersimpan() async {
    final r = await _api.get('/me/tersimpan');
    return [
      for (final x in r.data as List)
        BeasiswaRingkas.fromJson(
          (x as Map<String, dynamic>)['beasiswa'] as Map<String, dynamic>,
        ),
    ];
  }
}
