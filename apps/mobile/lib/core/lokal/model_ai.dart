/// Chatbot AI luring: model bahasa kecil yang berjalan di ponsel (LiteRT-LM lewat flutter_edge_ai), diunduh atas pilihan
/// pengguna. Memuat deteksi perangkat (RAM, arsitektur, SoC), daftar model dari ringan ke berat dengan rekomendasi
/// sesuai RAM, unduh dengan kemajuan, hapus, dan jawaban dengan konteks data beasiswa di ponsel.
library;

import 'dart:async';
import 'dart:io';

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
    this.papan = '',
    this.inti = 0,
    this.ramBebasMb = 0,
    this.diskBebasMb = 0,
    this.vulkan = false,
  });

  final String nama;
  final int ramMb;
  final bool arm64;
  final int sdk;
  final String soc;
  final String papan;
  final int inti;
  final int ramBebasMb;
  final int diskBebasMb;
  final bool vulkan;

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
        papan: a.board,
        inti: Platform.numberOfProcessors,
        ramBebasMb: a.availableRamSize,
        diskBebasMb: a.freeDiskSize ~/ (1024 * 1024),
        vulkan: a.systemFeatures.any(
          (f) => f.startsWith('android.hardware.vulkan.version'),
        ),
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
    required this.parameter,
    required this.konteks,
    required this.kecepatan,
    required this.mutuIndonesia,
    required this.untukSmart,
  });

  /// Spesifikasi yang ditampilkan ke pengguna.
  final String parameter;
  final String konteks;
  final String kecepatan;
  final String mutuIndonesia;
  final String untukSmart;

  /// Kemampuan model menurut katalog paket (gambar, suara, pemanggilan fungsi, mode berpikir).
  List<String> get kemampuan => [
    'Obrolan teks',
    if (varian.supportsFunctionCalls) 'Pemanggilan fungsi',
    if (varian.supportsThinking) 'Mode berpikir',
    if (varian.supportsImage) 'Membaca gambar',
    if (varian.supportsAudio) 'Mendengar suara',
  ];

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
    parameter: '0,6 miliar',
    konteks: '4.096 token',
    kecepatan: 'Sangat cepat',
    mutuIndonesia:
        'Cukup untuk kalimat sederhana; sering salah pada pertanyaan rumit.',
    untukSmart: 'Menjawab pertanyaan singkat: tenggat, syarat utama, dan beasiswa yang cocok dari data di ponsel.',
  ),
  ModelAi(
    id: 'qwen2.5-1.5b',
    nama: 'Qwen2.5 1.5B Instruct',
    kelas: Kelas.ringan,
    ramMinGb: 6,
    catatan: 'Seimbang antara kecepatan dan mutu jawaban. Pilihan awal yang baik untuk kebanyakan ponsel.',
    varian: LiteRtLmModels.qwen2_5_1_5bInstruct.q8Ekv4096,
    parameter: '1,5 miliar',
    konteks: '4.096 token',
    kecepatan: 'Cepat',
    mutuIndonesia: 'Baik untuk obrolan sehari-hari dalam bahasa Indonesia.',
    untukSmart: 'Menjelaskan syarat dan alasan rekomendasi, membandingkan dua beasiswa dengan singkat.',
  ),
  ModelAi(
    id: 'gemma4-e2b',
    nama: 'Gemma 4 E2B',
    kelas: Kelas.sedang,
    ramMinGb: 8,
    catatan: 'Jawaban lebih rapi dan paham konteks panjang. Butuh RAM 8 GB atau lebih.',
    varian: LiteRtLmModels.gemma4E2bIt.generic,
    parameter: '2 miliar efektif',
    konteks: 'hingga 32 ribu token',
    kecepatan: 'Sedang',
    mutuIndonesia: 'Baik; jawaban rapi dan paham konteks panjang.',
    untukSmart: 'Menjelaskan alasan rekomendasi, merangkum syarat, dan membantu menyusun rencana pendaftaran.',
  ),
  ModelAi(
    id: 'smollm3-3b',
    nama: 'SmolLM3 3B',
    kelas: Kelas.sedang,
    ramMinGb: 8,
    catatan: 'Model 3 miliar parameter, lebih teliti tetapi lebih lambat.',
    varian: LiteRtLmModels.smollm3_3b.q4Block32Ekv4096,
    parameter: '3 miliar',
    konteks: '4.096 token',
    kecepatan: 'Agak lambat',
    mutuIndonesia: 'Cukup; lebih kuat berbahasa Inggris dibanding Indonesia.',
    untukSmart: 'Penalaran lebih teliti pada pertanyaan syarat bertingkat, tetapi lebih lambat.',
  ),
  ModelAi(
    id: 'gemma4-e4b',
    nama: 'Gemma 4 E4B',
    kelas: Kelas.berat,
    ramMinGb: 12,
    catatan: 'Mutu tertinggi di daftar ini. Hanya untuk ponsel kelas atas (RAM 12 GB atau lebih) dan unduhan besar.',
    varian: LiteRtLmModels.gemma4E4bIt.generic,
    parameter: '4 miliar efektif',
    konteks: 'hingga 32 ribu token',
    kecepatan: 'Lambat',
    mutuIndonesia: 'Sangat baik di antara pilihan ini.',
    untukSmart: 'Jawaban paling lengkap untuk perencanaan studi dan perbandingan banyak beasiswa.',
  ),
];

/// Urutan pilihan saran, dari yang paling pas untuk proyek ini: jawaban bahasa Indonesia yang rapi dengan beban wajar.
const _urutanSaran = ['gemma4-e2b', 'qwen2.5-1.5b', 'qwen3-0.6b'];

/// Model yang disarankan untuk perangkat ini: yang pertama pada [_urutanSaran] dengan status disarankan; bila tidak ada,
/// yang masih muat di RAM; bila RAM sangat kecil, tidak ada saran.
ModelAi? modelDisarankan(PerangkatInfo p) {
  for (final id in _urutanSaran) {
    final m = katalogModelAi.firstWhere((e) => e.id == id);
    if (m.cocokUntuk(p) == Kecocokan.disarankan) return m;
  }
  for (final id in _urutanSaran) {
    final m = katalogModelAi.firstWhere((e) => e.id == id);
    if (m.cocokUntuk(p) == Kecocokan.bisa) return m;
  }
  return null;
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
  Timer? _timerLepas;
  Future<void>? _sedangMemuat;
  bool _sedangMenjawab = false;

  /// Model dilepas dari memori bila tidak dipakai selama ini, agar ponsel tidak terbebani.
  static const _diamMaks = Duration(minutes: 3);

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

  /// Tekanan memori dari sistem: lepas model segera (dipanggil dari pengamat siklus aplikasi).
  Future<void> tekananMemori() async {
    if (!_sedangMenjawab) await _lepas();
  }

  /// Memuat model aktif di latar belakang (dipanggil saat halaman chatbot dibuka, bukan saat aplikasi dibuka).
  void siapkanDiLatarBelakang() {
    if (!dipakai || _modelDimuat == aktifId.value || _sedangMemuat != null) {
      return;
    }
    _sedangMemuat = _muatModel()
        .whenComplete(() => _sedangMemuat = null)
        .catchError((Object _) {});
  }

  Future<void> _muatModel() async {
    final m = aktif;
    if (m == null || !await _inisialisasi() || _modelDimuat == m.id) return;
    // Jangan memaksa memuat bila RAM kosong jauh di bawah kebutuhan: cegah aplikasi tertutup sendiri.
    final hp = perangkat.value;
    if (hp != null &&
        hp.ramBebasMb > 0 &&
        hp.ramBebasMb < m.ramMinGb * 1024 * 0.25) {
      throw StateError(
        'RAM kosong terlalu kecil untuk memuat model. Tutup aplikasi lain lalu coba lagi.',
      );
    }
    await _lepas();
    await FlutterEdgeAi.installModelFromCatalog(m.varian).install();
    _model = await FlutterEdgeAi.getActiveModel(
      defaults: m.varian.runtimeDefaults,
      maxTokens: 2048,
    );
    _modelDimuat = m.id;
  }

  void _jadwalkanLepas() {
    _timerLepas?.cancel();
    _timerLepas = Timer(_diamMaks, () {
      if (!_sedangMenjawab) _lepas();
    });
  }

  Future<void> _lepas() async {
    _timerLepas?.cancel();
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
  /// Satu jawaban pada satu waktu, dengan batas waktu 5 menit agar ponsel tidak tergantung.
  Future<String> jawab(String pesan, String konteks) async {
    if (_sedangMenjawab) {
      throw StateError('Model masih menjawab pertanyaan sebelumnya');
    }
    _sedangMenjawab = true;
    try {
      await (_sedangMemuat ?? _muatModel());
      if (_model == null) throw StateError('Model belum termuat');
      final chat = await _model!.openChat(
        systemInstruction: instruksiSistem(konteks),
      );
      try {
        await chat.addQueryChunk(Message.text(text: pesan, isUser: true));
        final jawaban = StringBuffer();
        await for (final r in chat.generateChatResponseAsync().timeout(
          const Duration(seconds: 90),
        )) {
          if (r is TextResponse) jawaban.write(r.token);
        }
        return jawaban.toString().trim();
      } finally {
        await chat.close();
      }
    } finally {
      _sedangMenjawab = false;
      _jadwalkanLepas();
    }
  }

  static String instruksiSistem(String konteks) =>
      'Kamu adalah asisten SMART, pemandu beasiswa untuk mahasiswa Indonesia. Jawab dalam bahasa Indonesia yang singkat dan jelas. '
      'Gunakan hanya data di bawah ini; jika tidak ada di data, katakan belum tercatat dan sarankan memeriksa laman resmi. '
      'Jangan pernah menyatakan seseorang pasti diterima; angka peluang hanya perkiraan.\n\nDATA:\n$konteks';
}
