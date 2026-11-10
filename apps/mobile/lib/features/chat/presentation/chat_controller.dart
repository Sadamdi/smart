import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../../../core/dependensi.dart';
import '../data/chat_repository.dart';

class ChatController extends GetxController {
  ChatRepository get _repo => Get.find<ChatRepository>();

  late final tersedia = Muatan<bool>(_repo.tersedia);
  late final riwayat = Muatan<List<PesanChat>>(_repo.riwayat);

  /// Sedang mengirim pesan, dan galat pengirimannya.
  final mengirim = false.obs;
  final galat = RxnString();

  /// Chatbot dianggap tersedia sampai terbukti sebaliknya.
  bool get bisaMenjawab => tersedia.value ?? true;

  Future<void> buka() => Future.wait([tersedia.muat(), riwayat.muat()]);

  /// Mengirim pesan. Mengembalikan true bila berhasil (kolom teks boleh dikosongkan).
  Future<bool> kirim(String teks) async {
    if (teks.isEmpty || mengirim.value) return false;
    mengirim.value = true;
    galat.value = null;
    try {
      await _repo.kirim(teks);
      await riwayat.muat();
      return true;
    } catch (e) {
      galat.value = pesanGalat(e);
      return false;
    } finally {
      mengirim.value = false;
    }
  }

  Future<void> hapusRiwayat() async {
    await _repo.hapusRiwayat();
    await riwayat.muat();
  }

  void bersihkan() {
    tersedia.reset();
    riwayat.reset();
    galat.value = null;
  }
}
