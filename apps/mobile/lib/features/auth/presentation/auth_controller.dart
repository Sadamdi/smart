import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/providers.dart';
import '../domain/pengguna.dart';

enum StatusAuth { memeriksa, keluar, masuk }

class AuthState {
  const AuthState(this.status, [this.pengguna]);

  final StatusAuth status;
  final Pengguna? pengguna;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_mulai);
    return const AuthState(StatusAuth.memeriksa);
  }

  Future<void> _mulai() async {
    final repo = ref.read(authRepositoryProvider);
    if (!await repo.adaToken()) {
      state = const AuthState(StatusAuth.keluar);
      return;
    }
    try {
      state = AuthState(StatusAuth.masuk, await repo.saya());
    } on ApiException {
      // Token tidak valid atau server tidak terjangkau: minta masuk lagi.
      state = const AuthState(StatusAuth.keluar);
    }
  }

  Future<void> masuk(String email, String sandi) async {
    final p = await ref.read(authRepositoryProvider).masuk(email, sandi);
    state = AuthState(StatusAuth.masuk, p);
  }

  Future<void> daftar(String nama, String email, String sandi) async {
    final p = await ref.read(authRepositoryProvider).daftar(nama, email, sandi);
    state = AuthState(StatusAuth.masuk, p);
  }

  Future<void> ubahProfil(ProfilMasukan m) async {
    final p = await ref.read(authRepositoryProvider).ubahProfil(m);
    state = AuthState(StatusAuth.masuk, p);
  }

  Future<void> ubahPreferensi({required bool email, required bool push}) async {
    final p = await ref
        .read(authRepositoryProvider)
        .ubahPreferensi(email: email, push: push);
    state = AuthState(StatusAuth.masuk, p);
  }

  Future<void> keluar() async {
    await ref.read(authRepositoryProvider).keluar();
    state = const AuthState(StatusAuth.keluar);
  }

  /// Dipanggil klien API ketika penyegaran token gagal.
  void sesiBerakhir() {
    if (state.status != StatusAuth.keluar) {
      state = const AuthState(StatusAuth.keluar);
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
