import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../data/kalender_repository.dart';
import '../domain/kalender.dart';

/// Acara kalender dan checklist berkas. Dipakai Beranda, Kalender, dan Detail.
class KalenderController extends GetxController {
  KalenderRepository get _repo => Get.find<KalenderRepository>();

  /// Acara dari awal bulan ini sampai 120 hari ke depan.
  late final acara = Muatan<List<Acara>>(() {
    final n = DateTime.now();
    return _repo.acara(
      dari: DateTime(n.year, n.month, 1),
      sampai: DateTime(n.year, n.month, n.day).add(const Duration(days: 120)),
    );
  });

  late final checklist = Muatan<List<ChecklistBeasiswa>>(_repo.checklist);

  Future<void> pastikanSemua() =>
      Future.wait([acara.pastikan(), checklist.pastikan()]);

  void bersihkan() {
    acara.reset();
    checklist.reset();
  }

  Future<void> muatSemua() => Future.wait([acara.muat(), checklist.muat()]);

  /// Menjalankan [aksi] ke server lalu memuat ulang acara dan checklist. Galat diteruskan ke pemanggil.
  Future<void> _lalu(Future<void> Function() aksi) async {
    await aksi();
    await muatSemua();
  }

  Future<void> tambahTugas(String judul, DateTime tanggal) =>
      _lalu(() => _repo.tambahTugas(judul, tanggal));

  Future<void> selesaikanTugas(String id, bool selesai) =>
      _lalu(() => _repo.selesaikanTugas(id, selesai));

  Future<void> hapusTugas(String id) => _lalu(() => _repo.hapusTugas(id));

  Future<void> centang(String berkasId, bool selesai) =>
      _lalu(() => _repo.centang(berkasId, selesai));
}
