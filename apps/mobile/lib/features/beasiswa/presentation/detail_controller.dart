import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../../../core/dependensi.dart';
import '../data/beasiswa_repository.dart';
import '../domain/beasiswa.dart';

/// Detail satu beasiswa. Satu instance per id (tag), dibuang saat halaman ditutup.
class DetailController extends GetxController {
  DetailController(this.id);

  final String id;

  Future<void> rencanaDaftar(String kode) =>
      Get.find<BeasiswaRepository>().rencanaDaftar(id, kode);

  late final detail = Muatan<BeasiswaDetail>(
    () => Get.find<BeasiswaRepository>().detail(id),
  );

  @override
  void onInit() {
    super.onInit();
    Future.microtask(detail.muat);
  }

  /// Mencatat klik lalu membuka tautan resmi. Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> bukaPortal(BeasiswaRingkas b) async {
    final uri = Uri.tryParse(b.tautanResmi);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http')) {
      return 'Tautan resmi tidak valid.';
    }
    try {
      await Get.find<BeasiswaRepository>().catatKlik(b.id);
    } catch (_) {
      // Pencatatan klik tidak boleh menghalangi pembukaan tautan.
    }
    final ok = await Get.find<PembukaTautan>().buka(uri);
    return ok ? null : 'Tautan tidak dapat dibuka.';
  }
}
