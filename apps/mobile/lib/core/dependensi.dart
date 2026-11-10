import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/beasiswa/data/beasiswa_repository.dart';
import '../features/beasiswa/presentation/jelajah_controller.dart';
import '../features/beasiswa/presentation/tersimpan_controller.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/chat/presentation/chat_controller.dart';
import '../features/dokumen/data/dokumen_repository.dart';
import '../features/beranda/presentation/beranda_controller.dart';
import '../features/dokumen/presentation/dokumen_controller.dart';
import '../features/kalender/data/kalender_repository.dart';
import '../features/kalender/presentation/kalender_controller.dart';
import '../features/notifikasi/data/notifikasi_repository.dart';
import '../features/notifikasi/presentation/notifikasi_controller.dart';
import '../features/profil/presentation/profil_controller.dart';
import '../features/rekomendasi/data/rekomendasi_repository.dart';
import '../features/rekomendasi/presentation/rekomendasi_controller.dart';
import 'api_client.dart';
import 'tema_controller.dart';
import 'token_storage.dart';

/// Pemegang kunci navigator utama; dipakai pemeriksa pembaruan untuk menampilkan dialog di atas halaman mana pun.
class NavigasiController extends GetxService {
  final kunci = GlobalKey<NavigatorState>();
}

/// Pembuka tautan eksternal; dipisah agar bisa diganti di tes.
class PembukaTautan extends GetxService {
  PembukaTautan([Future<bool> Function(Uri)? buka])
    : buka =
          buka ?? ((u) => launchUrl(u, mode: LaunchMode.externalApplication));

  final Future<bool> Function(Uri) buka;
}

/// Mendaftarkan semua dependensi aplikasi ke GetX: infrastruktur (Dio, token, ApiClient), repository, lalu
/// controller per fitur. [dio] dan [storage] bisa disuntikkan (dipakai tes).
void pasangDependensi({
  Dio? dio,
  TokenStorage? storage,
  Future<bool> Function(Uri)? bukaTautan,
}) {
  Get.put<TokenStorage>(storage ?? SecureTokenStorage(), permanent: true);
  Get.put<Dio>(dio ?? buatDio(), permanent: true);
  Get.put<ApiClient>(
    ApiClient(
      dio: Get.find<Dio>(),
      storage: Get.find<TokenStorage>(),
      onSesiBerakhir: () => Get.find<AuthController>().sesiBerakhir(),
    ),
    permanent: true,
  );
  Get.put(NavigasiController(), permanent: true);
  Get.put(PembukaTautan(bukaTautan), permanent: true);

  Get.put(AuthRepository(Get.find(), Get.find()), permanent: true);
  Get.put(BeasiswaRepository(Get.find()), permanent: true);
  Get.put(RekomendasiRepository(Get.find()), permanent: true);
  Get.put(KalenderRepository(Get.find()), permanent: true);
  Get.put(NotifikasiRepository(Get.find()), permanent: true);
  Get.put(ChatRepository(Get.find()), permanent: true);
  Get.put(DokumenRepository(Get.find()), permanent: true);

  Get.put(TemaController(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(RekomendasiController(), permanent: true);
  Get.put(KalenderController(), permanent: true);
  Get.put(TersimpanController(), permanent: true);
  Get.put(NotifikasiController(), permanent: true);
  Get.put(BerandaController(), permanent: true);
  Get.put(ProfilController(), permanent: true);
  Get.lazyPut(() => JelajahController(), fenix: true);
  Get.lazyPut(() => DokumenController(), fenix: true);
  Get.lazyPut(() => ChatController(), fenix: true);
}

/// Teks galat yang aman ditampilkan ke pengguna.
String pesanGalat(Object e) {
  if (e is ApiException) return e.message;
  return 'Terjadi kesalahan yang tidak terduga. Coba lagi.';
}

/// Mengosongkan data milik akun yang baru keluar, agar akun berikutnya tidak melihat data lama.
void bersihkanDataSesi() {
  if (Get.isRegistered<RekomendasiController>()) {
    Get.find<RekomendasiController>().bersihkan();
  }
  if (Get.isRegistered<KalenderController>()) {
    Get.find<KalenderController>().bersihkan();
  }
  if (Get.isRegistered<TersimpanController>()) {
    Get.find<TersimpanController>().bersihkan();
  }
  if (Get.isRegistered<NotifikasiController>()) {
    Get.find<NotifikasiController>().bersihkan();
  }
  if (Get.isRegistered<JelajahController>()) {
    Get.find<JelajahController>().bersihkan();
  }
  if (Get.isRegistered<DokumenController>()) {
    Get.find<DokumenController>().bersihkan();
  }
  if (Get.isRegistered<ProfilController>()) {
    Get.find<ProfilController>().bersihkan();
  }
  if (Get.isRegistered<ChatController>()) {
    Get.find<ChatController>().bersihkan();
  }
}
