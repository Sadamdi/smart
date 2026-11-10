import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../../kalender/presentation/kalender_controller.dart';
import '../data/beasiswa_repository.dart';
import '../domain/beasiswa.dart';

/// Beasiswa yang disimpan pengguna: kumpulan id (untuk tanda bookmark) dan daftar lengkap (halaman Tersimpan).
class TersimpanController extends GetxController {
  BeasiswaRepository get _repo => Get.find<BeasiswaRepository>();

  late final idTersimpan = Muatan<Set<String>>(_repo.idTersimpan);
  late final daftar = Muatan<List<BeasiswaRingkas>>(_repo.daftarTersimpan);

  void bersihkan() {
    idTersimpan.reset();
    daftar.reset();
  }

  /// Id tersimpan terakhir yang diketahui (kosong bila belum dimuat).
  Set<String> get ids => idTersimpan.value ?? <String>{};

  bool apakahTersimpan(String id) => ids.contains(id);

  Future<void> muatSemua() => Future.wait([idTersimpan.muat(), daftar.muat()]);

  void _segarkan() {
    idTersimpan.muat();
    daftar.muat();
    Get.find<KalenderController>().checklist.muat();
  }

  Future<void> simpan(String id) async {
    await _repo.simpan(id);
    _segarkan();
  }

  Future<void> hapus(String id) async {
    await _repo.hapusSimpan(id);
    _segarkan();
  }
}
