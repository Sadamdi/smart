import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../data/dokumen_repository.dart';
import '../domain/dokumen.dart';

class DokumenController extends GetxController {
  DokumenRepository get _repo => Get.find<DokumenRepository>();

  late final daftar = Muatan<List<Dokumen>>(_repo.daftar);

  /// Jenis dokumen yang dipilih sebelum mengunggah.
  final jenis = 'cv'.obs;

  /// Sedang mengunggah.
  final mengirim = false.obs;

  Future<void> unggah(String path, String nama) async {
    mengirim.value = true;
    try {
      await _repo.unggah(jenis: jenis.value, path: path, nama: nama);
      await daftar.muat();
    } finally {
      mengirim.value = false;
    }
  }

  Future<void> hapus(String id) async {
    await _repo.hapus(id);
    await daftar.muat();
  }

  void bersihkan() {
    daftar.reset();
    jenis.value = 'cv';
  }
}
