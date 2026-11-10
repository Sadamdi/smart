import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../data/rekomendasi_repository.dart';
import '../domain/rekomendasi.dart';

/// Daftar rekomendasi per kategori, ringkasan jumlah, dan filter kategori yang sedang dipilih.
class RekomendasiController extends GetxController {
  RekomendasiRepository get _repo => Get.find<RekomendasiRepository>();

  late final ringkasan = Muatan<RingkasanRekomendasi>(_repo.ringkasan);

  /// Filter kategori pada layar Rekomendasi; null berarti semua.
  final kategori = Rxn<Kategori>();

  /// Sedang menghitung ulang di server.
  final menghitung = false.obs;

  final _daftar = <Kategori?, Muatan<List<Rekomendasi>>>{};

  /// Daftar untuk satu kategori; dibuat saat pertama diminta. Isinya baru dimuat lewat [pastikan] atau [muatSemua].
  Muatan<List<Rekomendasi>> daftarUntuk(Kategori? k) => _daftar.putIfAbsent(
    k,
    () => Muatan<List<Rekomendasi>>(() => _repo.daftar(kategori: k)),
  );

  Muatan<List<Rekomendasi>> get terpilih => daftarUntuk(kategori.value);

  Future<void> pastikan() =>
      Future.wait([ringkasan.pastikan(), terpilih.pastikan()]);

  Future<void> pilih(Kategori? k) {
    kategori.value = k;
    return daftarUntuk(k).pastikan();
  }

  /// Memuat ulang ringkasan dan semua daftar yang pernah dibuka.
  Future<void> muatSemua() =>
      Future.wait([ringkasan.muat(), for (final d in _daftar.values) d.muat()]);

  Future<void> hitungUlang() async {
    menghitung.value = true;
    try {
      await _repo.hitungUlang();
      await muatSemua();
    } finally {
      menghitung.value = false;
    }
  }

  void bersihkan() {
    ringkasan.reset();
    for (final d in _daftar.values) {
      d.reset();
    }
    kategori.value = null;
  }
}
