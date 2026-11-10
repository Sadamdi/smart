import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../data/notifikasi_repository.dart';
import '../domain/notifikasi.dart';

class NotifikasiController extends GetxController {
  NotifikasiRepository get _repo => Get.find<NotifikasiRepository>();

  late final daftar = Muatan<List<Notifikasi>>(_repo.daftar);

  /// Jumlah yang belum dibaca, untuk lencana di kepala halaman.
  int get belumDibaca => daftar.value?.where((n) => !n.dibaca).length ?? 0;

  Future<void> baca(String id) async {
    await _repo.baca(id);
    await daftar.muat();
  }

  Future<void> bacaSemua() async {
    await _repo.bacaSemua();
    await daftar.muat();
  }

  void bersihkan() => daftar.reset();
}
