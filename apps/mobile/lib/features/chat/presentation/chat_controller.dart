import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart' hide Response;

import '../../../core/async_state.dart';
import '../../../core/dependensi.dart';
import '../../dokumen/data/dokumen_repository.dart';
import '../data/chat_repository.dart';

/// Dokumen yang dilampirkan pada pertanyaan berikutnya (sudah diunggah dan dibaca server).
class LampiranChat {
  const LampiranChat({required this.id, required this.nama});

  final String id;
  final String nama;
}

class ChatController extends GetxController {
  ChatRepository get _repo => Get.find<ChatRepository>();

  late final tersedia = Muatan<bool>(_repo.tersedia);
  late final riwayat = Muatan<List<PesanChat>>(_repo.riwayat);

  /// Sedang menerima jawaban (aliran), dan galat pengirimannya.
  final mengirim = false.obs;
  final galat = RxnString();

  /// Pertanyaan yang sedang dijawab dan jawaban yang baru sebagian (tampil bertahap).
  final pesanSementara = RxnString();
  final jawabanSementara = ''.obs;

  /// Lampiran (maksimal 3) dan status unggah.
  final lampiran = <LampiranChat>[].obs;
  final mengunggah = false.obs;

  static const lampiranMaks = 3;

  /// Jenis dokumen dari nama berkas: CV atau sertifikat (termasuk penghargaan dan piagam).
  static String jenisDari(String nama) {
    final n = nama.toLowerCase();
    if (n.contains('cv') || n.contains('resume') || n.contains('riwayat')) {
      return 'cv';
    }
    return 'sertifikat';
  }

  /// Memilih berkas (PDF, Word, teks, gambar), mengunggahnya ke server, lalu menampilkannya sebagai lampiran.
  Future<void> lampirkan() async {
    if (mengunggah.value || lampiran.length >= lampiranMaks) return;
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    final berkas = hasil.isEmpty ? null : hasil.first;
    if (berkas?.path == null) return;
    mengunggah.value = true;
    galat.value = null;
    try {
      final d = await Get.find<DokumenRepository>().unggah(
        jenis: jenisDari(berkas!.name),
        path: berkas.path!,
        nama: berkas.name,
      );
      lampiran.add(LampiranChat(id: d.id, nama: d.namaBerkas));
    } catch (e) {
      galat.value = pesanGalat(e);
    } finally {
      mengunggah.value = false;
    }
  }

  void lepas(LampiranChat l) => lampiran.remove(l);

  StreamSubscription<KejadianChat>? _langganan;
  CancelToken? _batal;
  final _penampung = StringBuffer();
  Timer? _penyiram;

  /// Chatbot dianggap tersedia sampai terbukti sebaliknya.
  bool get bisaMenjawab => tersedia.value ?? true;

  Future<void> buka() => Future.wait([tersedia.muat(), riwayat.muat()]);

  /// Menyalin potongan yang terkumpul ke layar paling sering 12 kali per detik agar tidak berat saat model cepat.
  void _jadwalkanSiram() {
    _penyiram ??= Timer(const Duration(milliseconds: 80), () {
      _penyiram = null;
      jawabanSementara.value = _penampung.toString();
    });
  }

  /// Mengirim pesan dan menampilkan jawaban bertahap. Mengembalikan true bila pengiriman dimulai
  /// (kolom teks boleh dikosongkan); jawaban masuk lewat [jawabanSementara] lalu riwayat dimuat ulang.
  Future<bool> kirim(String teks) async {
    if (teks.isEmpty || mengirim.value) return false;
    mengirim.value = true;
    galat.value = null;
    pesanSementara.value = teks;
    jawabanSementara.value = '';
    _penampung.clear();
    _batal = CancelToken();
    final ids = [for (final l in lampiran) l.id];
    lampiran.clear();
    final selesai = Completer<void>();
    _langganan = _repo
        .kirimAlir(teks, batal: _batal, dokumenIds: ids)
        .listen(
          (k) {
            if (k is TokenChat) {
              _penampung.write(k.t);
              _jadwalkanSiram();
            }
          },
          onError: (Object e) {
            galat.value = pesanGalat(e);
            if (!selesai.isCompleted) selesai.complete();
          },
          onDone: () {
            if (!selesai.isCompleted) selesai.complete();
          },
          cancelOnError: true,
        );
    unawaited(
      selesai.future.then((_) async {
        _penyiram?.cancel();
        _penyiram = null;
        final dibatalkan = _langganan == null;
        _langganan = null;
        if (!dibatalkan && galat.value == null) await riwayat.muat();
        _bersihkanAliran();
      }),
    );
    return true;
  }

  void _bersihkanAliran() {
    mengirim.value = false;
    pesanSementara.value = null;
    jawabanSementara.value = '';
    _penampung.clear();
  }

  /// Menghentikan jawaban yang sedang mengalir (koneksi server diputus dan model berhenti menghasilkan teks).
  Future<void> batalkan() async {
    if (!mengirim.value) return;
    _batal?.cancel();
    final l = _langganan;
    _langganan = null;
    await l?.cancel();
    _penyiram?.cancel();
    _penyiram = null;
    _bersihkanAliran();
  }

  /// Cadangan sesaat dari riwayat yang baru dihapus, agar dapat diurungkan.
  final cadanganHapus = Rxn<List<dynamic>>();

  Future<void> hapusRiwayat() async {
    await batalkan();
    try {
      cadanganHapus.value = await _repo.ekspor();
    } catch (_) {
      cadanganHapus.value = null;
    }
    await _repo.hapusRiwayat();
    await riwayat.muat();
  }

  Future<String> urungkanHapus() async {
    final c = cadanganHapus.value;
    if (c == null || c.isEmpty) return 'Tidak ada yang dipulihkan';
    final n = await _repo.impor(c);
    cadanganHapus.value = null;
    await riwayat.muat();
    return '$n percakapan dipulihkan';
  }

  Future<Map<String, dynamic>> statistik() => _repo.statistik();

  /// Menyimpan cadangan riwayat sebagai berkas JSON ke lokasi pilihan pengguna.
  Future<String> cadangkan() async {
    final butir = await _repo.ekspor();
    if (butir.isEmpty) return 'Belum ada riwayat untuk dicadangkan';
    final uri = await FilePicker.saveFile(
      fileName: 'cadangan-chat-smart.json',
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(butir))),
      mimeType: 'application/json',
    );
    return uri == null ? 'Dibatalkan' : 'Cadangan disimpan';
  }

  /// Memulihkan riwayat dari berkas cadangan JSON (butir yang sama tidak digandakan).
  Future<String> pulihkan() async {
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final berkas = hasil.isEmpty ? null : hasil.first;
    if (berkas?.path == null) return 'Dibatalkan';
    try {
      final butir = jsonDecode(await File(berkas!.path!).readAsString());
      if (butir is! List) return 'Berkas cadangan tidak valid';
      final n = await _repo.impor(butir);
      await riwayat.muat();
      return '$n percakapan dipulihkan';
    } catch (_) {
      return 'Berkas cadangan tidak valid';
    }
  }

  void bersihkan() {
    unawaited(batalkan());
    tersedia.reset();
    riwayat.reset();
    galat.value = null;
  }
}
