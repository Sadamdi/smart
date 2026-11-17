import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../data/rekomendasi_repository.dart';
import '../domain/rekomendasi.dart';

/// Daftar rekomendasi per kategori, ringkasan jumlah, dan filter kategori yang sedang dipilih.
class RekomendasiController extends GetxController {
  RekomendasiRepository get _repo => Get.find<RekomendasiRepository>();

  /// Wilayah yang sedang dipilih: dalam atau luar negeri. Dipakai Beranda, Rekomendasi, dan ringkasannya.
  final wilayah = 'dalam'.obs;

  late final ringkasan = Muatan<RingkasanRekomendasi>(
    () => _repo.ringkasan(wilayah: wilayah.value),
  );

  /// Filter kategori pada layar Rekomendasi; null berarti semua.
  final kategori = Rxn<Kategori>();

  /// Sedang menghitung ulang di server.
  final menghitung = false.obs;

  final _daftar = <String, Muatan<List<Rekomendasi>>>{};

  /// Daftar untuk satu kategori; dibuat saat pertama diminta. Isinya baru dimuat lewat [pastikan] atau [muatSemua].
  Muatan<List<Rekomendasi>> daftarUntuk(Kategori? k) {
    final w = wilayah.value;
    return _daftar.putIfAbsent(
      '${k?.kode}|$w',
      () => Muatan<List<Rekomendasi>>(
        () => _repo.daftar(kategori: k, wilayah: w),
      ),
    );
  }

  Muatan<List<Rekomendasi>> get terpilih => daftarUntuk(kategori.value);

  Future<void> pastikan() =>
      Future.wait([ringkasan.pastikan(), terpilih.pastikan()]);

  /// Berganti dalam atau luar negeri: ringkasan dan daftar untuk wilayah itu dimuat bila belum ada.
  Future<void> pilihWilayah(String w) {
    if (wilayah.value == w) return Future.value();
    wilayah.value = w;
    ringkasan.muat();
    return pastikan();
  }

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
