import 'package:get/get.dart';

import '../../../core/dependensi.dart';
import '../../auth/presentation/auth_controller.dart';

/// Pengaturan akun: preferensi pengingat. Pilihan tema ada di TemaController.
class PengaturanController extends GetxController {
  final menyimpan = false.obs;

  /// Menyimpan preferensi notifikasi. Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> ubahPreferensi({
    required bool email,
    required bool push,
  }) async {
    menyimpan.value = true;
    try {
      await Get.find<AuthController>().ubahPreferensi(email: email, push: push);
      return null;
    } catch (e) {
      return pesanGalat(e);
    } finally {
      menyimpan.value = false;
    }
  }
}
