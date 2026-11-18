/// Chatbot AI luring: model bahasa kecil yang berjalan di ponsel (LiteRT-LM lewat flutter_edge_ai), diunduh atas pilihan
/// pengguna. Memuat deteksi perangkat (RAM, arsitektur, SoC), daftar model dari ringan ke berat dengan rekomendasi
/// sesuai RAM, unduh dengan kemajuan, hapus, dan jawaban dengan konteks data beasiswa di ponsel.
library;

import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';

/// Hasil deteksi perangkat yang dipakai untuk menyarankan model.
class PerangkatInfo {
  const PerangkatInfo({
    required this.nama,
    required this.ramMb,
    required this.arm64,
    required this.sdk,
    required this.soc,
  });

  final String nama;
  final int ramMb;
  final bool arm64;
  final int sdk;
  final String soc;

  double get ramGb => ramMb / 1024;

  /// Mesin AI luring butuh ponsel 64-bit dengan Android 11 ke atas.
  bool get didukung => arm64 && sdk >= 30;

  static Future<PerangkatInfo> deteksi() async {
    try {
      final a = await DeviceInfoPlugin().androidInfo;
      return PerangkatInfo(
        nama: '${a.manufacturer} ${a.model}',
        ramMb: a.physicalRamSize,
        arm64: a.supportedAbis.contains('arm64-v8a'),
        sdk: a.version.sdkInt,
        soc: a.hardware,
      );
    } on Object {
      return const PerangkatInfo(
        nama: 'Tidak diketahui',
        ramMb: 0,
        arm64: false,
        sdk: 0,
        soc: '',
      );
    }
  }
}

enum Kelas { sangatRingan, ringan, sedang, berat }

enum Kecocokan { disarankan, bisa, berat, takDidukung }

/// Satu pilihan model pada daftar. [ramMinGb] adalah RAM ponsel yang masih nyaman, bukan ukuran berkas.
class ModelAi {
  const ModelAi({
    required this.id,
    required this.nama,
    required this.kelas,
    required this.ramMinGb,
    required this.catatan,
    required this.varian,
  });

  final String id;
  final String nama;
  final Kelas kelas;
  final double ramMinGb;
  final String catatan;
  final LiteRtLmVariant varian;

  int get ukuranByte => varian.file.sizeBytes;
  String get berkas => varian.file.installFilename;
  double get ukuranGb => ukuranByte / (1024 * 1024 * 1024);

  String get labelKelas => switch (kelas) {
    Kelas.sangatRingan => 'Sangat ringan',
    Kelas.ringan => 'Ringan',
    Kelas.sedang => 'Sedang',
    Kelas.berat => 'Berat',
  };

  /// Disarankan bila RAM ponsel dua kali kebutuhan minimum model atau lebih, bisa bila memenuhi minimum.
  Kecocokan cocokUntuk(PerangkatInfo p) {
    if (!p.didukung) return Kecocokan.takDidukung;
    if (p.ramGb >= ramMinGb * 1.5) return Kecocokan.disarankan;
    if (p.ramGb >= ramMinGb) return Kecocokan.bisa;
    return Kecocokan.berat;
  }
}

/// Daftar model (semua publik, tanpa akun Hugging Face), dari yang paling ringan ke paling berat.
final List<ModelAi> katalogModelAi = [
  ModelAi(
    id: 'qwen3-0.6b',
    nama: 'Qwen3 0.6B',
    kelas: Kelas.sangatRingan,
    ramMinGb: 3,
    catatan: 'Paling cepat dan hemat. Cocok untuk pertanyaan singkat; bahasa Indonesia sederhana.',
    varian: LiteRtLmModels.qwen3_0_6b.dynamicInt4,
  ),
  ModelAi(
    id: 'qwen2.5-1.5b',
    nama: 'Qwen2.5 1.5B Instruct',
    kelas: Kelas.ringan,
    ramMinGb: 6,
    catatan: 'Seimbang antara kecepatan dan mutu jawaban. Pilihan awal yang baik untuk kebanyakan ponsel.',
    varian: LiteRtLmModels.qwen2_5_1_5bInstruct.q8Ekv4096,
  ),
  ModelAi(
    id: 'gemma4-e2b',
    nama: 'Gemma 4 E2B',
    kelas: Kelas.sedang,
    ramMinGb: 8,
    catatan: 'Jawaban lebih rapi dan paham konteks panjang. Butuh RAM 8 GB atau lebih.',
    varian: LiteRtLmModels.gemma4E2bIt.generic,
  ),
  ModelAi(
    id: 'smollm3-3b',
    nama: 'SmolLM3 3B',
    kelas: Kelas.sedang,
    ramMinGb: 8,
    catatan: 'Model 3 miliar parameter, lebih teliti tetapi lebih lambat.',
    varian: LiteRtLmModels.smollm3_3b.q4Block32Ekv4096,
  ),
  ModelAi(
    id: 'gemma4-e4b',
    nama: 'Gemma 4 E4B',
    kelas: Kelas.berat,
    ramMinGb: 12,
    catatan: 'Mutu tertinggi di daftar ini. Hanya untuk ponsel kelas atas (RAM 12 GB atau lebih) dan unduhan besar.',
    varian: LiteRtLmModels.gemma4E4bIt.generic,
  ),
];

/// Model yang disarankan untuk perangkat ini: yang paling mampu dengan status disarankan, bila ada.
ModelAi? modelDisarankan(PerangkatInfo p) {
  ModelAi? terbaik;
  for (final m in katalogModelAi) {
    if (m.cocokUntuk(p) == Kecocokan.disarankan) terbaik = m;
  }
  if (terbaik != null && terbaik.kelas == Kelas.berat) {
    // Unduhan terbesar tidak dijadikan saran otomatis; pilih yang sedang.
    terbaik = katalogModelAi.lastWhere(
      (m) => m.kelas != Kelas.berat && m.cocokUntuk(p) == Kecocokan.disarankan,
      orElse: () => terbaik!,
    );
  }
  return terbaik;
}

enum StatusModel { belum, mengunduh, terpasang }

/// Pengelola model AI: perangkat, status tiap model, unduh, hapus, pilih aktif, dan jawab.
class PengelolaModelAi {
  final perangkat = ValueNotifier<PerangkatInfo?>(null);
  final status = ValueNotifier<Map<String, StatusModel>>({});
  final kemajuan = ValueNotifier<Map<String, int>>({});
  final aktifId = ValueNotifier<String?>(null);
  final galat = ValueNotifier<String?>(null);

  bool _siap = false;
  InferenceModel? _model;
  String? _modelDimuat;

  bool siapDipakai() => dipakai;

  bool get dipakai =>
      aktifId.value != null &&
      status.value[aktifId.value] == StatusModel.terpasang;

  Future<bool> _inisialisasi() async {
    if (_siap) return true;
    try {
      await FlutterEdgeAi.initialize(inferenceEngines: [LiteRtLmEngine()]);
      _siap = true;
    } on Object catch (e) {
      galat.value = 'Mesin AI tidak dapat dimulai di perangkat ini: $e';
    }
    return _siap;
  }

  Future<void> muat() async {
    perangkat.value ??= await PerangkatInfo.deteksi();
    if (!(perangkat.value?.didukung ?? false)) return;
    if (!await _inisialisasi()) return;
    final baru = <String, StatusModel>{};
    for (final m in katalogModelAi) {
      final ada = await FlutterEdgeAi.isModelInstalled(m.berkas);
      baru[m.id] = ada ? StatusModel.terpasang : StatusModel.belum;
    }
    status.value = baru;
    aktifId.value ??= baru.entries
        .where((e) => e.value == StatusModel.terpasang)
        .map((e) => e.key)
        .firstOrNull;
  }

  Future<void> unduh(ModelAi m) async {
    galat.value = null;
    if (!await _inisialisasi()) return;
    _setStatus(m.id, StatusModel.mengunduh);
    kemajuan.value = {...kemajuan.value, m.id: 0};
    try {
      await FlutterEdgeAi.installModelFromCatalog(m.varian, foreground: true)
          .withProgress((p) => kemajuan.value = {...kemajuan.value, m.id: p})
          .install();
      _setStatus(m.id, StatusModel.terpasang);
      aktifId.value = m.id;
    } on Object catch (e) {
      galat.value = 'Unduhan gagal: $e';
      _setStatus(m.id, StatusModel.belum);
    }
  }

  Future<void> hapus(ModelAi m) async {
    if (_modelDimuat == m.id) await _lepas();
    try {
      await FlutterEdgeAi.uninstallModel(m.berkas);
    } on Object catch (e) {
      galat.value = 'Gagal menghapus: $e';
    }
    _setStatus(m.id, StatusModel.belum);
    if (aktifId.value == m.id) {
      aktifId.value = status.value.entries
          .where((e) => e.value == StatusModel.terpasang)
          .map((e) => e.key)
          .firstOrNull;
    }
  }

  void pakai(ModelAi m) => aktifId.value = m.id;

  void _setStatus(String id, StatusModel s) =>
      status.value = {...status.value, id: s};

  Future<void> _lepas() async {
    try {
      await _model?.close();
    } on Object {
      // sudah tertutup
    }
    _model = null;
    _modelDimuat = null;
  }

  ModelAi? get aktif =>
      katalogModelAi.where((m) => m.id == aktifId.value).firstOrNull;

  /// Menjawab [pesan] dengan model aktif; [konteks] berisi data beasiswa dan profil dari mesin luring.
  Future<String> jawab(String pesan, String konteks) async {
    final m = aktif;
    if (m == null || !await _inisialisasi()) {
      throw StateError('Belum ada model AI terpasang');
    }
    if (_modelDimuat != m.id) {
      await _lepas();
      await FlutterEdgeAi.installModelFromCatalog(m.varian)
          .install(); // memastikan model ini aktif (berkas sudah ada)
      _model = await FlutterEdgeAi.getActiveModel(
        defaults: m.varian.runtimeDefaults,
        maxTokens: 2048,
      );
      _modelDimuat = m.id;
    }
    final chat = await _model!.openChat(
      systemInstruction: instruksiSistem(konteks),
    );
    try {
      await chat.addQueryChunk(Message.text(text: pesan, isUser: true));
      final jawaban = StringBuffer();
      await for (final r in chat.generateChatResponseAsync()) {
        if (r is TextResponse) jawaban.write(r.token);
      }
      return jawaban.toString().trim();
    } finally {
      await chat.close();
    }
  }

  static String instruksiSistem(String konteks) =>
      'Kamu adalah asisten SMART, pemandu beasiswa untuk mahasiswa Indonesia. Jawab dalam bahasa Indonesia yang singkat dan jelas. '
      'Gunakan hanya data di bawah ini; jika tidak ada di data, katakan belum tercatat dan sarankan memeriksa laman resmi. '
      'Jangan pernah menyatakan seseorang pasti diterima; angka peluang hanya perkiraan.\n\nDATA:\n$konteks';
}
