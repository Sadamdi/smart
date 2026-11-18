import 'dart:convert';

import 'package:dio/dio.dart';
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

/// Peristiwa jawaban chatbot yang mengalir: potongan teks, selesai, atau galat (dilempar sebagai exception).
sealed class KejadianChat {}

class TokenChat extends KejadianChat {
  TokenChat(this.t);

  final String t;
}

class SelesaiChat extends KejadianChat {
  SelesaiChat(this.pesan);

  final PesanChat pesan;
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

  bool get _modelSiap =>
      Get.find<MesinLokal>().siap && Get.find<PengelolaModelAi>().dipakai;

  /// Jawaban model AI di ponsel sebagai aliran token; di akhir disimpan ke riwayat lokal dan dikirim [SelesaiChat].
  Stream<KejadianChat> _alirModel(String pesan) async* {
    final lokal = Get.find<MesinLokal>();
    final ai = Get.find<PengelolaModelAi>();
    final jawaban = StringBuffer();
    await for (final t in ai.jawabAlir(pesan, lokal.konteksChat(pesan))) {
      jawaban.write(t);
      yield TokenChat(t);
    }
    final isi = jawaban.toString().trim();
    if (isi.isEmpty) throw StateError('Model tidak memberi jawaban');
    final rujukan = [
      for (final x in lokal.sumberTerakhir.take(4))
        {'id': x['id'], 'nama': x['nama'], 'tautan_resmi': x['tautan_resmi']},
    ];
    final akhir =
        '$isi\n\n(Dijawab model AI di ponsel. Estimasi hanya perkiraan, bukan jaminan diterima.)';
    final id = 'lokal-${DateTime.now().microsecondsSinceEpoch}';
    lokal.catatChat({
      'id': id,
      'pesan': pesan,
      'jawaban': akhir,
      'waktu': DateTime.now().toIso8601String(),
      'rujukan': rujukan,
      'sumber': 'ponsel',
    });
    yield SelesaiChat(
      PesanChat(
        id: id,
        pesan: pesan,
        jawaban: akhir,
        sumber: 'ponsel',
        rujukan: [
          for (final r in rujukan) (id: '${r['id']}', nama: '${r['nama']}'),
        ],
      ),
    );
  }

  /// Mengirim pesan dan mengalirkan jawaban per potongan. Membatalkan langganan (atau [batal]) menghentikan jawaban.
  /// Urutan: model AI di ponsel (mode luring atau dipilih pengguna), lalu server, lalu model ponsel bila jaringan putus.
  Stream<KejadianChat> kirimAlir(
    String pesan, {
    CancelToken? batal,
    List<String> dokumenIds = const [],
  }) async* {
    final lokal = Get.find<MesinLokal>();
    final pakaiModel = lokal.aktif.value || lokal.aiLokalAktif;
    if (dokumenIds.isNotEmpty && lokal.aktif.value) {
      throw ApiException(
        'LURING',
        'Lampiran dibaca oleh server, jadi butuh jaringan. Matikan mode luring lalu kirim lagi.',
        0,
      );
    }
    // Pertanyaan berlampiran dijawab server (dokumen dibaca di sana); model ponsel hanya bila jaringan putus.
    if (pakaiModel && _modelSiap && dokumenIds.isEmpty) {
      try {
        yield* _alirModel(pesan);
        return;
      } on Object {
        if (!lokal.aktif.value) {
          // model gagal dimuat: lanjut ke server bila online
        } else {
          rethrow;
        }
      }
    }
    if (lokal.aktif.value) {
      // tanpa model: jawaban berbasis data lokal (aturan)
      final r = await _api.post('/chat', body: {'pesan': pesan});
      yield SelesaiChat(PesanChat.fromJson(r.data as Map<String, dynamic>));
      return;
    }
    try {
      await for (final (ev, data) in _api.alirSse('/chat/stream', {
        'pesan': pesan,
      }, batal: batal)) {
        final j = jsonDecode(data) as Map<String, dynamic>;
        if (ev == 'token') {
          yield TokenChat(j['t'] as String);
        } else if (ev == 'selesai') {
          yield SelesaiChat(PesanChat.fromJson(j));
        } else if (ev == 'galat') {
          throw ApiException('AI', '${j['pesan']}', 503);
        }
      }
    } on ApiException catch (e) {
      // Otomatis: jaringan putus berarti model di ponsel. Mode Server murni tidak berpindah.
      if (e.galatJaringan && _modelSiap && lokal.modeAi.value != 'server') {
        yield* _alirModel(pesan);
        return;
      }
      rethrow;
    }
  }

  /// Versi sekali jadi (tanpa aliran), dipertahankan untuk pemanggil lama.
  Future<PesanChat> kirim(String pesan) async {
    PesanChat? akhir;
    await for (final k in kirimAlir(pesan)) {
      if (k is SelesaiChat) akhir = k.pesan;
    }
    return akhir ?? (throw StateError('Tidak ada jawaban'));
  }

  Future<void> hapusRiwayat() => _api.delete('/chat/riwayat');

  Future<Map<String, dynamic>> statistik() async =>
      (await _api.get('/chat/statistik')).data as Map<String, dynamic>;

  Future<List<dynamic>> ekspor() async =>
      (await _api.get('/chat/ekspor')).data as List<dynamic>;

  Future<int> impor(List<dynamic> butir) async {
    final r = await _api.post('/chat/impor', body: {'butir': butir});
    return (r.data as Map<String, dynamic>)['dipulihkan'] as int? ?? 0;
  }

}
