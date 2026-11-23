import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../../core/api_client.dart';
import '../../../core/lokal/chat_lokal.dart';
import '../../../core/lokal/ekstrak_teks.dart';
import '../../../core/lokal/mesin_lokal.dart';
import '../../../core/lokal/model_ai.dart';
import '../../dokumen/data/dokumen_repository.dart';

/// Penanda lampiran di akhir teks pesan: `[Lampiran: a.pdf; b.docx]`. Server dan ponsel sama-sama menulisnya.
final _penandaLampiran = RegExp(r'\n?\[Lampiran: ([^\]]+)\]\s*$');

({String teks, List<String> nama}) pisahLampiran(String pesan) {
  final m = _penandaLampiran.firstMatch(pesan);
  if (m == null) return (teks: pesan, nama: const []);
  return (
    teks: pesan.substring(0, m.start).trimRight(),
    nama: [
      for (final x in m.group(1)!.split(';'))
        if (x.trim().isNotEmpty) x.trim(),
    ],
  );
}

class PesanChat {
  const PesanChat({
    required this.id,
    required this.pesan,
    this.jawaban,
    this.rujukan = const [],
    this.sumber = 'server',
    this.lampiran = const [],
  });

  /// Lampiran pertanyaan ini; [teks] ada bila dibaca di ponsel (untuk pratinjau).
  final List<({String nama, String? teks, String? path})> lampiran;

  /// Asal jawaban: server (layanan AI), ponsel (model AI di ponsel), atau data lokal (aturan tanpa model).
  final String sumber;

  /// Beasiswa yang menjadi sumber jawaban: pasangan id dan nama.
  final List<({String id, String nama})> rujukan;

  final String id;
  final String pesan;
  final String? jawaban;

  factory PesanChat.fromJson(Map<String, dynamic> j) {
    final p = pisahLampiran(j['pesan'] as String);
    final simpan = <String, Map>{
      for (final x in (j['lampiran'] as List? ?? const []))
        '${(x as Map)['nama']}': x,
    };
    return PesanChat(
      id: j['id'] as String,
      pesan: p.teks,
      lampiran: [
        for (final n in p.nama)
          (
            nama: n,
            teks: simpan[n]?['teks'] as String?,
            path: simpan[n]?['path'] as String?,
          ),
      ],
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
}

/// Satu sesi (utas) percakapan, seperti daftar percakapan di ChatGPT.
class SesiChat {
  const SesiChat({
    required this.id,
    required this.judul,
    required this.diubah,
    this.jumlah = 0,
    this.lokal = false,
  });

  final String id;
  final String judul;
  final DateTime diubah;
  final int jumlah;

  /// Dibuat di ponsel dan belum tersalin ke server.
  final bool lokal;

  factory SesiChat.fromJson(Map<String, dynamic> j) => SesiChat(
    id: j['id'] as String,
    judul: (j['judul'] as String?) ?? judulBawaan,
    diubah:
        DateTime.tryParse('${j['diubah_pada']}') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    jumlah: (j['jumlah'] as num?)?.toInt() ?? 0,
    lokal: j['lokal'] == true,
  );
}

/// Peristiwa jawaban chatbot yang mengalir: potongan teks, selesai, judul sesi, atau galat (dilempar sebagai exception).
sealed class KejadianChat {}

class TokenChat extends KejadianChat {
  TokenChat(this.t);

  final String t;
}

class SelesaiChat extends KejadianChat {
  SelesaiChat(this.pesan);

  final PesanChat pesan;
}

/// Server memberi judul pada sesi dari topik percakapannya.
class JudulChat extends KejadianChat {
  JudulChat(this.sesiId, this.judul);

  final String sesiId;
  final String judul;
}

/// Sesi buatan ponsel baru mendapat id dari server (aktif diganti ke id ini).
class SesiBergantiChat extends KejadianChat {
  SesiBergantiChat(this.sesiLama, this.sesiBaru);

  final String sesiLama;
  final String sesiBaru;
}

class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  MesinLokal get _lokal => Get.find<MesinLokal>();

  Future<bool> tersedia() async {
    final r = await _api.get('/chat/status');
    return (r.data as Map<String, dynamic>)['tersedia'] as bool? ?? false;
  }

  // ---------- sesi ----------

  /// Daftar sesi: dari server bila ada jaringan (disalin ke ponsel), selain itu dari salinan di ponsel.
  /// Sesi dan pesan buatan ponsel ikut disalin ke server di latar belakang.
  Future<List<SesiChat>> daftarSesi() async {
    final r = await _api.get('/chat/sesi');
    _lokal.chat.cerminSesi(r.data as List);
    unawaited(sinkronkan());
    return [for (final x in _lokal.chat.daftarSesi()) SesiChat.fromJson(x)];
  }

  /// Membuat sesi baru; di server bila ada jaringan, atau di ponsel (disalin ke server nanti).
  Future<SesiChat> buatSesi() async {
    final r = await _api.post('/chat/sesi', body: <String, dynamic>{});
    final j = Map<String, dynamic>.from(r.data as Map);
    if (j['lokal'] != true) _lokal.chat.terimaSesi(j);
    return SesiChat.fromJson(j);
  }

  Future<void> ubahJudulSesi(String id, String judul) async {
    if (id.startsWith('lokal-')) {
      _lokal.chat.ubahJudul(id, judul);
      return;
    }
    await _api.patch('/chat/sesi/$id', body: {'judul': judul});
    _lokal.chat.ubahJudul(id, judul);
  }

  Future<void> hapusSesi(String id) async {
    if (!id.startsWith('lokal-')) await _api.delete('/chat/sesi/$id');
    _lokal.chat.hapusSesi(id);
  }

  // ---------- pesan ----------

  /// Isi satu sesi: salinan dari server digabung dengan jawaban model ponsel yang belum tersalin, sehingga jawaban
  /// tidak hilang saat riwayat dimuat ulang.
  Future<List<PesanChat>> riwayat(String? sesiId) async {
    if (sesiId == null) return const [];
    if (!sesiId.startsWith('lokal-')) {
      final r = await _api.get('/chat/riwayat', query: {'sesi_id': sesiId});
      _lokal.chat.cerminRiwayat(sesiId, r.data as List);
    }
    return [
      for (final m in _lokal.chat.pesanSesi(sesiId)) PesanChat.fromJson(m),
    ];
  }

  bool get _modelSiap => _lokal.siap && Get.find<PengelolaModelAi>().dipakai;

  /// Riwayat sesi untuk model ponsel: beberapa tanya jawab terakhir agar jawabannya nyambung.
  String _riwayatUntukModel(String? sesiId) {
    if (sesiId == null) return '';
    final p = _lokal.chat.pesanSesi(sesiId);
    final akhir = p.length > 3 ? p.sublist(p.length - 3) : p;
    if (akhir.isEmpty) return '';
    String potong(Object? x, int n) {
      final t = '${x ?? ''}';
      return t.length > n ? '${t.substring(0, n)}...' : t;
    }

    return 'Percakapan sebelumnya:\n${[for (final m in akhir) 'Pengguna: ${potong(m['pesan'], 300)}\nAsisten: ${potong(m['jawaban'], 400)}'].join('\n')}\n';
  }

  /// Jawaban model AI di ponsel sebagai aliran token; di akhir disimpan ke riwayat lokal dan dikirim [SelesaiChat].
  Stream<KejadianChat> _alirModel(
    String pesan,
    String? sesiId, {
    List<({String nama, String teks, String? path})> lampiran = const [],
  }) async* {
    final lokal = _lokal;
    final ai = Get.find<PengelolaModelAi>();
    final jawaban = StringBuffer();
    _batalSaran = true;
    await _saranModel;
    final dokumen = StringBuffer();
    if (lampiran.isNotEmpty) {
      final jatah = 5000 ~/ lampiran.length;
      dokumen.writeln(
        'Pengguna melampirkan dokumen di bawah ini. Bila pertanyaannya singkat atau tidak jelas (misalnya "ringkas" atau "apa isinya"), yang dimaksud adalah dokumen lampiran itu: jawab langsung berdasarkan isinya, jangan bertanya balik.\n',
      );
      for (final l in lampiran) {
        dokumen.writeln(
          'DOKUMEN LAMPIRAN "${l.nama}" (milik pengguna, dibaca di ponsel):\n${potongRelevan(l.teks, pesan, batas: jatah)}\n',
        );
      }
    }
    final konteks =
        '${_riwayatUntukModel(sesiId)}$dokumen${lokal.konteksChat(pesan)}';
    await for (final t in ai.jawabAlir(pesan, konteks)) {
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
    lokal.chat.catatChat({
      'id': id,
      'sesi_id': sesiId,
      'pesan': lampiran.isEmpty
          ? pesan
          : '$pesan\n[Lampiran: ${lampiran.map((l) => l.nama).join('; ')}]',
      if (lampiran.isNotEmpty)
        'lampiran': [
          for (final l in lampiran)
            {
              'nama': l.nama,
              'teks': l.teks.length > 6000 ? l.teks.substring(0, 6000) : l.teks,
              'path': ?l.path,
            },
        ],
      'jawaban': akhir,
      'waktu': DateTime.now().toIso8601String(),
      'rujukan': rujukan,
      'sumber': 'ponsel',
      'lokal': true,
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
    unawaited(sinkronkan());
  }

  /// Memastikan sesi [sesiId] dikenal server (sesi buatan ponsel disalin dulu). Mengembalikan id yang dipakai.
  Future<String> _sesiServer(String sesiId) async {
    if (!sesiId.startsWith('lokal-')) return sesiId;
    final s = _lokal.chat.daftarSesi().firstWhere(
      (x) => x['id'] == sesiId,
      orElse: () => <String, dynamic>{},
    );
    final otomatis = (s['judul_otomatis'] ?? true) == true;
    final r = await _api.post(
      '/chat/sesi',
      body: {'judul': otomatis ? null : s['judul'], 'klien_id': sesiId},
    );
    final baru = '${(r.data as Map)['id']}';
    if (baru.startsWith('lokal-')) {
      throw ApiException('JARINGAN', 'Tidak ada jaringan.', 0);
    }
    _lokal.chat.gantiIdSesi(sesiId, baru);
    penggantianSesi[sesiId] = baru;
    return baru;
  }

  /// Mengirim pesan dan mengalirkan jawaban per potongan. Membatalkan langganan (atau [batal]) menghentikan jawaban.
  /// Urutan: model AI di ponsel (mode luring atau dipilih pengguna), lalu server, lalu model ponsel bila jaringan putus.
  Stream<KejadianChat> kirimAlir(
    String pesan, {
    String? sesiId,
    CancelToken? batal,
    List<String> dokumenIds = const [],
    List<({String nama, String teks, String? path})> teksLampiran = const [],
  }) async* {
    final lokal = _lokal;
    final pakaiModel = lokal.aktif.value || lokal.aiLokalAktif;
    if (teksLampiran.isNotEmpty) {
      // Lampiran dibaca di ponsel: hanya model AI di ponsel yang bisa menjawabnya (server tidak menerima teksnya).
      if (!_modelSiap) {
        throw ApiException(
          'MODEL',
          'Membaca lampiran tanpa server butuh model AI di ponsel. Unduh di Pengaturan, Model AI di ponsel.',
          0,
        );
      }
      yield* _alirModel(pesan, sesiId, lampiran: teksLampiran);
      return;
    }
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
        yield* _alirModel(pesan, sesiId);
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
      final r = await _api.post(
        '/chat',
        body: {'pesan': pesan, 'sesi_id': sesiId},
      );
      yield SelesaiChat(PesanChat.fromJson(r.data as Map<String, dynamic>));
      return;
    }
    try {
      var sid = sesiId;
      if (sid != null && sid.startsWith('lokal-')) {
        sid = await _sesiServer(sid);
        yield SesiBergantiChat(sesiId!, sid);
      }
      await for (final (ev, data) in _api.alirSse('/chat/stream', {
        'pesan': pesan,
        'sesi_id': ?sid,
        if (dokumenIds.isNotEmpty) 'dokumen_ids': dokumenIds,
      }, batal: batal)) {
        final j = jsonDecode(data) as Map<String, dynamic>;
        if (ev == 'token') {
          yield TokenChat(j['t'] as String);
        } else if (ev == 'selesai') {
          yield SelesaiChat(PesanChat.fromJson(j));
        } else if (ev == 'judul') {
          final id = '${j['sesi_id']}';
          _lokal.chat.ubahJudul(id, '${j['judul']}', otomatis: true);
          yield JudulChat(id, '${j['judul']}');
        } else if (ev == 'galat') {
          throw ApiException('AI', '${j['pesan']}', 503);
        }
      }
    } on ApiException catch (e) {
      // Otomatis: jaringan putus berarti model di ponsel. Mode Server murni tidak berpindah.
      if (e.galatJaringan && _modelSiap && lokal.modeAi.value != 'server') {
        yield* _alirModel(pesan, sesiId);
        return;
      }
      if (e.galatJaringan && lokal.modeAi.value != 'server') {
        throw ApiException(
          'JARINGAN',
          'Tidak ada internet dan model AI ponsel belum siap. Unduh model di Pengaturan > Model AI, atau aktifkan mode luring untuk jawaban dari data di ponsel.',
          0,
        );
      }
      rethrow;
    }
  }

  /// Versi sekali jadi (tanpa aliran), dipertahankan untuk pemanggil lama.
  Future<PesanChat> kirim(String pesan, {String? sesiId}) async {
    PesanChat? akhir;
    await for (final k in kirimAlir(pesan, sesiId: sesiId)) {
      if (k is SelesaiChat) akhir = k.pesan;
    }
    return akhir ?? (throw StateError('Tidak ada jawaban'));
  }

  // ---------- sinkron ke server ----------

  bool _sinkron = false;

  /// Naik setiap kali sinkron mengubah sesi atau judul; pendengar memuat ulang daftar dan riwayatnya.
  final versiSinkron = 0.obs;

  /// Id sesi ponsel yang sudah diganti id server (lama ke baru), agar layar yang masih memegang id lama berpindah.
  final penggantianSesi = <String, String>{};

  /// Menyalin sesi dan jawaban buatan ponsel ke server (sekali jalan pada satu waktu). Server menyimpan riwayatnya,
  /// memberi judul dari topik, dan mempelajari memori dari pesan pengguna. Tidak berbuat apa pun di mode luring.
  Future<void> sinkronkan() async {
    if (Get.isRegistered<DokumenRepository>()) {
      unawaited(Get.find<DokumenRepository>().kirimTertunda());
    }
    final lokal = _lokal;
    if (_sinkron || lokal.aktif.value) return;
    _sinkron = true;
    var berubah = false;
    try {
      // Satu sesi atau pesan yang gagal tidak boleh menghentikan sisanya; dicoba lagi pada sinkron berikutnya.
      for (final s in lokal.chat.daftarSesi()) {
        final id = '${s['id']}';
        if (!id.startsWith('lokal-')) continue;
        final tertunda = lokal.chat
            .pesanSesi(id)
            .any((m) => m['lokal'] == true);
        if (!tertunda) continue; // sesi kosong tidak perlu disalin
        try {
          await _sesiServer(id);
          berubah = true;
        } on Object catch (e) {
          debugPrint('sinkron sesi $id gagal: $e');
        }
      }
      for (final m in lokal.chat.belumSinkron()) {
        final sid = '${m['sesi_id']}';
        if (sid.startsWith('lokal-')) continue;
        try {
          final waktu = DateTime.tryParse('${m['waktu']}')?.toUtc();
          final r = await _api.post(
            '/chat/catat-lokal',
            body: {
              'pesan': m['pesan'],
              'jawaban': m['jawaban'],
              'waktu': waktu?.toIso8601String(),
              'sesi_id': sid,
            },
          );
          lokal.chat.tandaiSinkron('${m['id']}');
          berubah = true;
          final d = r.data;
          if (d is Map && d['judul'] != null) {
            lokal.chat.ubahJudul(sid, '${d['judul']}', otomatis: true);
          }
        } on Object catch (e) {
          debugPrint('sinkron pesan ${m['id']} gagal: $e');
        }
      }
      await segarkanMemori();
    } on Object {
      // jaringan putus atau server menolak: dicoba lagi pada kesempatan berikutnya
    } finally {
      _sinkron = false;
      if (berubah) versiSinkron.value++;
    }
  }

  /// Menyalin Memori Pintar dari server ke ponsel agar model di ponsel juga mengenal pengguna.
  Future<void> segarkanMemori() async {
    if (_lokal.aktif.value) return;
    final daftar = await _api.get('/me/memori');
    final stat = await _api.get('/me/memori/statistik');
    _lokal.chat.catatMemori(
      daftar.data as List,
      aktif: (stat.data as Map)['memori_aktif'] as bool?,
    );
  }

  Future<void> hapusRiwayat() => _api.delete('/chat/riwayat');

  /// Saran dari basis data di ponsel (beasiswa paling cocok dan tenggat terdekat); selalu tersedia, juga saat luring.
  List<String> saranData() => _lokal.saranData();

  bool _batalSaran = false;
  Future<void>? _saranModel;

  /// Saran pertanyaan lanjutan. Online: model di server. Luring atau server gagal: model AI di ponsel bila sudah
  /// diunduh. Kosong bila tak satu pun tersedia; klien lalu memakai saran dari basis data dan aturan lokal.
  Future<List<String>> saran(String? sesiId) async {
    final lokalSaja = _lokal.aktif.value || (sesiId?.startsWith('lokal-') ?? false);
    if (!lokalSaja) {
      try {
        final r = await _api.get(
          '/chat/saran',
          query: {'sesi_id': ?sesiId},
        );
        final d = [for (final x in (r.data as List? ?? const [])) '$x'];
        if (d.isNotEmpty) return d;
      } catch (_) {
        // jatuh ke model di ponsel
      }
    }
    return _saranDariPonsel(sesiId);
  }

  Future<List<String>> _saranDariPonsel(String? sesiId) async {
    if (sesiId == null || !_modelSiap) return const [];
    final riwayat = _riwayatUntukModel(sesiId);
    if (riwayat.isEmpty) return const [];
    final hasil = <String>[];
    _batalSaran = false;
    final kerja = () async {
      try {
        final b = StringBuffer();
        await for (final t in Get.find<PengelolaModelAi>()
            .jawabAlir(
              'Tulis 4 pertanyaan lanjutan singkat (maksimal 8 kata, satu per baris, tanpa nomor) yang mungkin ingin saya tanyakan berikutnya.',
              riwayat,
            )
            .timeout(const Duration(seconds: 25))) {
          b.write(t);
          if (_batalSaran || b.length > 260) break;
        }
        for (final baris in b.toString().split('\n')) {
          final k = baris
              .replaceFirst(RegExp(r'^[\s\-*•0-9.)]+'), '')
              .replaceAll(RegExp(r'''["'*]'''), '')
              .trim();
          if (k.length >= 4 && k.length <= 80 && !hasil.contains(k)) hasil.add(k);
        }
      } catch (_) {
        // model sibuk atau gagal: klien memakai saran lain
      }
    }();
    _saranModel = kerja;
    await kerja;
    return _batalSaran ? const [] : hasil.take(4).toList();
  }

  /// Statistik dari riwayat di ponsel: seketika, tanpa jaringan. Dipakai sebagai tampilan awal sebelum data server tiba.
  Map<String, dynamic> statistikLokal() => _lokal.chat.statistik();

  Future<Map<String, dynamic>> statistik() async =>
      (await _api.get('/chat/statistik')).data as Map<String, dynamic>;

  Future<List<dynamic>> ekspor() async =>
      (await _api.get('/chat/ekspor')).data as List<dynamic>;

  Future<int> impor(List<dynamic> butir) async {
    final r = await _api.post('/chat/impor', body: {'butir': butir});
    return (r.data as Map<String, dynamic>)['dipulihkan'] as int? ?? 0;
  }
}
