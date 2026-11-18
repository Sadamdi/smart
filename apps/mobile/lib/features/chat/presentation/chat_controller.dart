import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import '../../../core/async_state.dart';
import '../../../core/dependensi.dart';
import '../data/chat_repository.dart';

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
    final selesai = Completer<void>();
    _langganan = _repo
        .kirimAlir(teks, batal: _batal)
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

  Future<void> hapusRiwayat() async {
    await batalkan();
    await _repo.hapusRiwayat();
    await riwayat.muat();
  }

  void bersihkan() {
    unawaited(batalkan());
    tersedia.reset();
    riwayat.reset();
    galat.value = null;
  }
}
