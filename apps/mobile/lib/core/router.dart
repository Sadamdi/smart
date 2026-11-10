import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'dependensi.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/auth_pages.dart';
import '../features/beasiswa/presentation/detail_page.dart';
import '../features/beasiswa/presentation/jelajah_page.dart';
import '../features/beasiswa/presentation/tersimpan_page.dart';
import '../features/beranda/presentation/beranda_page.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/dokumen/presentation/dokumen_page.dart';
import '../features/pengaturan/presentation/pengaturan_page.dart';
import '../features/profil/presentation/profil_lanjutan_page.dart';
import '../features/kalender/presentation/kalender_page.dart';
import '../features/notifikasi/presentation/notifikasi_page.dart';
import '../features/profil/presentation/profil_controller.dart';
import '../features/profil/presentation/profil_page.dart';
import '../features/rekomendasi/presentation/rekomendasi_page.dart';
import 'widgets/state_widgets.dart';

/// Penyegar router: dipicu setiap status auth berubah agar redirect dievaluasi ulang.
class SegarkanRouter extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Router mengikuti status masuk: belum masuk selalu ke layar masuk.
GoRouter buatRouter(SegarkanRouter segarkan) {
  final auth = Get.find<AuthController>();
  return GoRouter(
    navigatorKey: Get.find<NavigasiController>().kunci,
    initialLocation: '/',
    refreshListenable: segarkan,
    redirect: (context, state) {
      final status = auth.status;
      final lokasi = state.matchedLocation;
      final halamanAuth = lokasi == '/masuk' || lokasi == '/daftar';
      if (status == StatusAuth.memeriksa) {
        return lokasi == '/memuat' ? null : '/memuat';
      }
      if (status == StatusAuth.keluar) return halamanAuth ? null : '/masuk';
      if (halamanAuth || lokasi == '/memuat') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/memuat',
        builder: (_, _) => const Scaffold(body: MemuatState()),
      ),
      GoRoute(path: '/masuk', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/daftar', builder: (_, _) => const DaftarPage()),
      GoRoute(path: '/notifikasi', builder: (_, _) => const NotifikasiPage()),
      GoRoute(path: '/tersimpan', builder: (_, _) => const TersimpanPage()),
      GoRoute(path: '/dokumen', builder: (_, _) => const DokumenPage()),
      GoRoute(path: '/chat', builder: (_, _) => const ChatPage()),
      GoRoute(
        path: '/profil-lanjutan',
        builder: (_, _) => const ProfilLanjutanPage(),
      ),
      GoRoute(path: '/pengaturan', builder: (_, _) => const PengaturanPage()),
      GoRoute(
        path: '/beasiswa/:id',
        builder: (_, s) => DetailPage(id: s.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _Cangkang(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const BerandaPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/rekomendasi',
                builder: (_, _) => const RekomendasiPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/jelajah', builder: (_, _) => const JelajahPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kalender',
                builder: (_, _) => const KalenderPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profil', builder: (_, _) => const ProfilPage()),
            ],
          ),
        ],
      ),
    ],
  );
}

class _Cangkang extends StatelessWidget {
  const _Cangkang({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    // Back di tab selain Beranda kembali ke Beranda dulu; aplikasi baru tertutup dari Beranda.
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        // Formulir profil yang terbuka menangani Back sendiri.
        if (didPop || Get.find<ProfilController>().sedangDiubah.value) {
          return;
        }
        shell.goBranch(0);
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: Warna.kartu,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: Warna.gelap ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.0,
              child: NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: (i) =>
                    shell.goBranch(i, initialLocation: i == shell.currentIndex),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.space_dashboard_outlined),
                    selectedIcon: Icon(Icons.space_dashboard_rounded),
                    label: 'Beranda',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: 'Rekomendasi',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: 'Jelajah',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Kalender',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
