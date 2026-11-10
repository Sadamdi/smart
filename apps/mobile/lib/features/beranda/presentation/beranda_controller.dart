import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../../kalender/domain/kalender.dart';
import '../../kalender/presentation/kalender_controller.dart';
import '../../rekomendasi/domain/rekomendasi.dart';
import '../../rekomendasi/presentation/rekomendasi_controller.dart';

/// Menggabungkan data Beranda: ringkasan dan rekomendasi utama (dari RekomendasiController) serta acara kalender.
class BerandaController extends GetxController {
  RekomendasiController get _rekomendasi => Get.find<RekomendasiController>();
  KalenderController get _kalender => Get.find<KalenderController>();

  Muatan<RingkasanRekomendasi> get ringkasan => _rekomendasi.ringkasan;
  Muatan<List<Rekomendasi>> get utama =>
      _rekomendasi.daftarUntuk(Kategori.memenuhi);
  Muatan<List<Acara>> get acara => _kalender.acara;

  /// Memuat data yang belum pernah diminta saat Beranda dibuka.
  Future<void> buka() =>
      Future.wait([ringkasan.pastikan(), utama.pastikan(), acara.pastikan()]);

  /// Tarik untuk menyegarkan: memuat ulang semuanya.
  Future<void> segarkan() =>
      Future.wait([ringkasan.muat(), utama.muat(), acara.muat()]);
}
