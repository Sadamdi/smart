import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/dependensi.dart';
import 'core/router.dart';
import 'core/tema_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/update/pemeriksa_pembaruan.dart';
import 'core/widgets/layar_pembuka.dart';
import 'features/auth/presentation/auth_controller.dart';

void main() {
  // Huruf Plus Jakarta Sans dibundel di assets/google_fonts: tanpa unduhan saat pertama dibuka.
  GoogleFonts.config.allowRuntimeFetching = false;
  WidgetsFlutterBinding.ensureInitialized();
  // Semua controller dan repository didaftarkan ke GetX sebelum aplikasi digambar.
  pasangDependensi();
  runApp(const SmartApp());
}

class SmartApp extends StatefulWidget {
  const SmartApp({super.key, this.googleFonts = true, this.pembuka = true});

  final bool googleFonts;
  final bool pembuka;

  @override
  State<SmartApp> createState() => _SmartAppState();
}

class _SmartAppState extends State<SmartApp> {
  final _segarkan = SegarkanRouter();
  late final GoRouter _router;
  late final Worker _pantau;

  @override
  void initState() {
    super.initState();
    _router = buatRouter(_segarkan);
    _pantau = ever(Get.find<AuthController>().state, (_) => _segarkan.ping());
  }

  @override
  void dispose() {
    _pantau.dispose();
    _router.dispose();
    _segarkan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Get.find<TemaController>();
    // Obx membangun ulang MaterialApp saat pilihan tema berganti.
    return Obx(
      () => MaterialApp.router(
        title: 'SMART',
        debugShowCheckedModeBanner: false,
        theme: buatTema(googleFonts: widget.googleFonts),
        darkTheme: buatTema(googleFonts: widget.googleFonts, w: Palet.gelap),
        themeMode: tema.mode.value,
        routerConfig: _router,
        builder: (context, child) {
          // Warna.* dibaca langsung oleh banyak widget, jadi set sebelum menggambar dan bangun ulang saat mode berganti.
          final gelap = Theme.of(context).brightness == Brightness.dark;
          Warna.pakai(gelap ? Palet.gelap : Palet.terang);
          return LayarPembuka(
            aktif: widget.pembuka,
            child: KeyedSubtree(
              key: ValueKey(gelap),
              child: PemeriksaPembaruan(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
    );
  }
}
