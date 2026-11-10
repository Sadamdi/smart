import 'package:get/get.dart';

import '../../../core/dependensi.dart';
import '../../auth/domain/pengguna.dart';
import '../../auth/presentation/auth_controller.dart';

/// Keadaan penyuntingan profil: apakah formulir terbuka, sedang menyimpan, dan galat penyimpanan.
/// Nilai kolom formulir tetap di TextEditingController layar; controller ini memegang keadaan bersama.
class ProfilController extends GetxController {
  /// Benar selama formulir "Ubah profil" terbuka; dipakai cangkang navigasi agar Back menutup formulir lebih dulu.
  final sedangDiubah = false.obs;
  final mengirim = false.obs;
  final galat = RxnString();

  void bersihkanGalat() => galat.value = null;

  /// Menyimpan profil lewat [AuthController]. Mengembalikan true bila berhasil.
  Future<bool> simpan(ProfilMasukan masukan) async {
    mengirim.value = true;
    galat.value = null;
    try {
      await Get.find<AuthController>().ubahProfil(masukan);
      return true;
    } catch (e) {
      galat.value = pesanGalat(e);
      return false;
    } finally {
      mengirim.value = false;
    }
  }

  void bersihkan() {
    sedangDiubah.value = false;
    mengirim.value = false;
    galat.value = null;
  }
}
