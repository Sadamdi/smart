import 'package:get/get.dart' hide Response;

import '../../../core/api_client.dart';
import '../../../core/lokal/mesin_lokal.dart';
import '../../../core/lokal/model_ai.dart';

class PesanChat {
  const PesanChat({
    required this.id,
    required this.pesan,
    this.jawaban,
    this.rujukan = const [],
    this.sumber = 'server',
  });

  /// Asal jawaban: server (layanan AI), ponsel (model AI di ponsel), atau data lokal (aturan tanpa model).
  final String sumber;

  /// Beasiswa yang menjadi sumber jawaban: pasangan id dan nama.
  final List<({String id, String nama})> rujukan;

  final String id;
  final String pesan;
  final String? jawaban;

  factory PesanChat.fromJson(Map<String, dynamic> j) => PesanChat(
    id: j['id'] as String,
    pesan: j['pesan'] as String,
    jawaban: j['jawaban'] as String?,
    sumber: (j['sumber'] as String?) ?? 'server',
    rujukan: [
      for (final x in (j['rujukan'] as List? ?? []))
        (
          id: (x as Map<String, dynamic>)['id'] as String,
          nama: x['nama'] as String,
        ),
    ],
  );
}

class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  Future<bool> tersedia() async {
    final r = await _api.get('/chat/status');
    return (r.data as Map<String, dynamic>)['tersedia'] as bool? ?? false;
  }

  Future<List<PesanChat>> riwayat() async {
    final r = await _api.get('/chat/riwayat');
    return [
      for (final x in r.data as List)
        PesanChat.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<PesanChat?> _lewatModelLokal(String pesan) async {
    final lokal = Get.find<MesinLokal>();
    final ai = Get.find<PengelolaModelAi>();
    if (!lokal.siap || !ai.dipakai) return null;
    try {
      final jawaban = await ai.jawab(pesan, lokal.konteksChat(pesan));
      if (jawaban.isEmpty) return null;
      final rujukan = [
        for (final x in lokal.sumberTerakhir.take(4))
          {'id': x['id'], 'nama': x['nama'], 'tautan_resmi': x['tautan_resmi']},
      ];
      final isi =
          '$jawaban\n\n(Dijawab model AI di ponsel. Estimasi hanya perkiraan, bukan jaminan diterima.)';
      lokal.catatChat({
        'id': 'lokal-${DateTime.now().microsecondsSinceEpoch}',
        'pesan': pesan,
        'jawaban': isi,
        'waktu': DateTime.now().toIso8601String(),
        'rujukan': rujukan,
        'sumber': 'ponsel',
      });
      return PesanChat(
        id: 'lokal-${DateTime.now().microsecondsSinceEpoch}',
        pesan: pesan,
        jawaban: isi,
        sumber: 'ponsel',
        rujukan: [
          for (final r in rujukan) (id: '${r['id']}', nama: '${r['nama']}'),
        ],
      );
    } on Object {
      return null;
    }
  }

  Future<PesanChat> kirim(String pesan) async {
    final lokal = Get.find<MesinLokal>();
    // Mode luring: model AI di ponsel lebih dulu; bila tidak ada atau gagal, jawaban berbasis data lokal.
    if (lokal.aktif.value || lokal.aiLokalAktif.value) {
      final p = await _lewatModelLokal(pesan);
      if (p != null) return p;
    }
    try {
      final r = await _api.post('/chat', body: {'pesan': pesan});
      return PesanChat.fromJson(r.data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.galatJaringan) {
        final p = await _lewatModelLokal(pesan);
        if (p != null) return p;
      }
      rethrow;
    }
  }

  Future<void> hapusRiwayat() => _api.delete('/chat/riwayat');
}
