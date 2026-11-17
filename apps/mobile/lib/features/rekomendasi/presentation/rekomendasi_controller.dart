import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../data/rekomendasi_repository.dart';
import '../domain/rekomendasi.dart';

enum StatusPerbarui { diam, menghitung, selesai }

/// Daftar rekomendasi per kategori, ringkasan jumlah, dan filter kategori yang sedang dipilih.
class RekomendasiController extends GetxController {
  RekomendasiRepository get _repo => Get.find<RekomendasiRepository>();

  /// Wilayah yang sedang dipilih: dalam atau luar negeri. Dipakai Beranda, Rekomendasi, dan ringkasannya.
  final wilayah = 'dalam'.obs;

  /// Urutan daftar: peluang (bawaan, estimasi peluang tertinggi dulu), tenggat, atau kecocokan.
  final urut = 'peluang'.obs;

  /// Batas bawah estimasi peluang (0 berarti semua).
  final minPeluang = 0.obs;

  late final ringkasan = Muatan<RingkasanRekomendasi>(
    () => _repo.ringkasan(wilayah: wilayah.value),
  );

  /// Filter kategori pada layar Rekomendasi; null berarti semua.
  final kategori = Rxn<Kategori>();

  /// Sedang menghitung ulang di server.
  final menghitung = false.obs;

  /// Untuk spanduk Memperbarui rekomendasi: diam, menghitung, lalu selesai sebentar sebelum kembali diam.
  final statusPerbarui = StatusPerbarui.diam.obs;

  /// Beranda hanya menampilkan satu pilihan utama; mengambil satu butir mempercepat Beranda (bukan seluruh daftar).
  final _utama = <String, Muatan<List<Rekomendasi>>>{};

  Muatan<List<Rekomendasi>> get utamaBeranda => _utama.putIfAbsent(
    wilayah.value,
    () => Muatan<List<Rekomendasi>>(
      () => _repo.daftar(
        kategori: Kategori.memenuhi,
        wilayah: wilayah.value,
        batas: 1,
      ),
    ),
  );

  final _daftar = <String, Muatan<List<Rekomendasi>>>{};

  /// Daftar untuk satu kategori; dibuat saat pertama diminta. Isinya baru dimuat lewat [pastikan] atau [muatSemua].
  Muatan<List<Rekomendasi>> daftarUntuk(Kategori? k) {
    final w = wilayah.value;
    final u = urut.value;
    final m = minPeluang.value;
    return _daftar.putIfAbsent(
      '${k?.kode}|$w|$u|$m',
      () => Muatan<List<Rekomendasi>>(
        () => _repo.daftar(kategori: k, wilayah: w, urut: u, minPeluang: m),
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
    utamaBeranda.pastikan(); // Beranda menampilkan satu pilihan utama untuk wilayah yang dipilih
    return pastikan();
  }

  Future<void> pilihUrut(String u) {
    if (urut.value == u) return Future.value();
    urut.value = u;
    return pastikan();
  }

  Future<void> pilihMinPeluang(int m) {
    if (minPeluang.value == m) return Future.value();
    minPeluang.value = m;
    return pastikan();
  }

  Future<void> pilih(Kategori? k) {
    kategori.value = k;
    return daftarUntuk(k).pastikan();
  }

  /// Memuat ulang ringkasan dan semua daftar yang pernah dibuka.
  Future<void> muatSemua() => Future.wait([
    ringkasan.muat(),
    for (final d in _daftar.values) d.muat(),
    for (final d in _utama.values) d.muat(),
  ]);

  Future<void> hitungUlang() async {
    menghitung.value = true;
    statusPerbarui.value = StatusPerbarui.menghitung;
    try {
      await _repo.hitungUlang();
      await muatSemua();
      // Spanduk 'selesai' disembunyikan oleh BannerPerbarui sendiri (pewaktunya ikut mati bersama widget).
      statusPerbarui.value = StatusPerbarui.selesai;
    } catch (_) {
      statusPerbarui.value = StatusPerbarui.diam;
      rethrow;
    } finally {
      menghitung.value = false;
    }
  }

  /// Dipanggil setelah profil disimpan: hitung ulang di latar belakang dengan spanduk, tanpa mengganggu pengguna.
  void perbaruiSetelahProfil() {
    if (menghitung.value) return;
    // Bila hitung ulang gagal, tetap muat ulang: server menghitung sendiri saat hasil usang.
    hitungUlang().catchError((_) => muatSemua());
  }

  void bersihkan() {
    ringkasan.reset();
    for (final d in _daftar.values) {
      d.reset();
    }
    for (final d in _utama.values) {
      d.reset();
    }
    statusPerbarui.value = StatusPerbarui.diam;
    kategori.value = null;
  }
}
