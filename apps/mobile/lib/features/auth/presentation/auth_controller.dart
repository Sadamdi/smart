import 'package:get/get.dart';

import '../../../core/api_client.dart';
import '../../../core/dependensi.dart';
import '../data/auth_repository.dart';
import '../domain/pengguna.dart';

enum StatusAuth { memeriksa, keluar, masuk }

class AuthState {
  const AuthState(this.status, [this.pengguna]);

  final StatusAuth status;
  final Pengguna? pengguna;
}

/// Status masuk dan data pengguna. Router mengikuti [state]; layar membaca [pengguna] di dalam Obx.
class AuthController extends GetxController {
  final state = const AuthState(StatusAuth.memeriksa).obs;

  /// Penanda proses kirim dan pesan galat untuk formulir masuk dan daftar.
  final mengirim = false.obs;
  final galatForm = RxnString();

  AuthRepository get _repo => Get.find<AuthRepository>();

  Pengguna? get pengguna => state.value.pengguna;
  StatusAuth get status => state.value.status;

  @override
  void onInit() {
    super.onInit();
    Future.microtask(_mulai);
  }

  Future<void> _mulai() async {
    if (!await _repo.adaToken()) {
      state.value = const AuthState(StatusAuth.keluar);
      return;
    }
    try {
      state.value = AuthState(StatusAuth.masuk, await _repo.saya());
    } on ApiException {
      // Token tidak valid atau server tidak terjangkau: minta masuk lagi.
      state.value = const AuthState(StatusAuth.keluar);
    }
  }

  /// Menjalankan [aksi] formulir dengan penanda kirim dan pesan galat.
  Future<void> _kirim(Future<Pengguna> Function() aksi) async {
    mengirim.value = true;
    galatForm.value = null;
    try {
      final p = await aksi();
      state.value = AuthState(StatusAuth.masuk, p);
    } catch (e) {
      galatForm.value = pesanGalat(e);
    } finally {
      mengirim.value = false;
    }
  }

  Future<void> masuk(String email, String sandi) =>
      _kirim(() => _repo.masuk(email, sandi));

  Future<void> daftar(String nama, String email, String sandi) =>
      _kirim(() => _repo.daftar(nama, email, sandi));

  /// Membersihkan pesan galat saat berpindah antara layar masuk dan daftar.
  void bersihkanForm() {
    galatForm.value = null;
    mengirim.value = false;
  }

  Future<void> ubahProfil(ProfilMasukan m) async {
    final p = await _repo.ubahProfil(m);
    state.value = AuthState(StatusAuth.masuk, p);
  }

  Future<void> ubahPreferensi({required bool email, required bool push}) async {
    final p = await _repo.ubahPreferensi(email: email, push: push);
    state.value = AuthState(StatusAuth.masuk, p);
  }

  Future<void> keluar() async {
    await _repo.keluar();
    state.value = const AuthState(StatusAuth.keluar);
    bersihkanDataSesi();
  }

  /// Dipanggil klien API ketika penyegaran token gagal.
  void sesiBerakhir() {
    if (status != StatusAuth.keluar) {
      state.value = const AuthState(StatusAuth.keluar);
      bersihkanDataSesi();
    }
  }
}
