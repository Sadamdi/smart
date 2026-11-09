import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/tema_provider.dart';
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
    final mode = ref.watch(temaProvider);
    return MaterialApp.router(
      title: 'SMART',
      debugShowCheckedModeBanner: false,
      theme: buatTema(googleFonts: googleFonts),
      darkTheme: buatTema(googleFonts: googleFonts, w: Palet.gelap),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Warna.* dibaca langsung oleh banyak widget, jadi set sebelum menggambar dan bangun ulang saat mode berganti.
        final gelap = Theme.of(context).brightness == Brightness.dark;
        Warna.pakai(gelap ? Palet.gelap : Palet.terang);
        return LayarPembuka(
          aktif: pembuka,
          child: KeyedSubtree(
            key: ValueKey(gelap),
            child: PemeriksaPembaruan(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}
