import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/beasiswa/data/beasiswa_repository.dart';
import '../features/kalender/data/kalender_repository.dart';
import '../features/notifikasi/data/notifikasi_repository.dart';
import '../features/rekomendasi/data/rekomendasi_repository.dart';
import 'api_client.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final dioProvider = Provider<Dio>((ref) => buatDio());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    dio: ref.watch(dioProvider),
    storage: ref.watch(tokenStorageProvider),
    onSesiBerakhir: () =>
        ref.read(authControllerProvider.notifier).sesiBerakhir(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  ),
);

final beasiswaRepositoryProvider = Provider<BeasiswaRepository>(
  (ref) => BeasiswaRepository(ref.watch(apiClientProvider)),
);

final rekomendasiRepositoryProvider = Provider<RekomendasiRepository>(
  (ref) => RekomendasiRepository(ref.watch(apiClientProvider)),
);

final kalenderRepositoryProvider = Provider<KalenderRepository>(
  (ref) => KalenderRepository(ref.watch(apiClientProvider)),
);

final notifikasiRepositoryProvider = Provider<NotifikasiRepository>(
  (ref) => NotifikasiRepository(ref.watch(apiClientProvider)),
);

/// Teks galat yang aman ditampilkan ke pengguna.
String pesanGalat(Object e) {
  if (e is ApiException) return e.message;
  return 'Terjadi kesalahan yang tidak terduga. Coba lagi.';
}
