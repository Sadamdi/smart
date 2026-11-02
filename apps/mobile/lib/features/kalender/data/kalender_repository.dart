import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../domain/kalender.dart';

class KalenderRepository {
  KalenderRepository(this._api);

  final ApiClient _api;

  Future<List<Acara>> acara({DateTime? dari, DateTime? sampai}) async {
    final r = await _api.get(
      '/me/kalender',
      query: {
        'dari': dari == null ? null : tanggalApi(dari),
        'sampai': sampai == null ? null : tanggalApi(sampai),
      },
    );
    return [
      for (final x in r.data as List) Acara.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<List<ChecklistBeasiswa>> checklist() async {
    final r = await _api.get('/me/checklist');
    return [
      for (final x in r.data as List)
        ChecklistBeasiswa.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<void> centang(String berkasId, bool selesai) =>
      _api.put('/me/checklist/$berkasId', body: {'selesai': selesai});

  Future<Tugas> tambahTugas(String judul, DateTime tanggal) async {
    final r = await _api.post(
      '/me/tugas',
      body: {'judul': judul, 'tanggal': tanggalApi(tanggal)},
    );
    return Tugas.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> selesaikanTugas(String id, bool selesai) =>
      _api.put('/me/tugas/$id', body: {'selesai': selesai});

  Future<void> hapusTugas(String id) => _api.delete('/me/tugas/$id');
}
