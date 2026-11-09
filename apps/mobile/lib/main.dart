import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/update/pemeriksa_pembaruan.dart';
import 'core/widgets/layar_pembuka.dart';

void main() {
  // Huruf Plus Jakarta Sans dibundel di assets/google_fonts: tanpa unduhan saat pertama dibuka.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(
    // Galat dimuat ulang manual lewat tombol "Coba lagi", bukan otomatis.
    ProviderScope(retry: (_, _) => null, child: const SmartApp()),
  );
}

class SmartApp extends ConsumerWidget {
  const SmartApp({super.key, this.googleFonts = true, this.pembuka = true});

  final bool googleFonts;
  final bool pembuka;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SMART',
      debugShowCheckedModeBanner: false,
      theme: buatTema(googleFonts: googleFonts),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => LayarPembuka(
        aktif: pembuka,
        child: PemeriksaPembaruan(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
