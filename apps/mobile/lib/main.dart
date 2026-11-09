import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'core/update/pemeriksa_pembaruan.dart';

void main() {
  runApp(
    // Galat dimuat ulang manual lewat tombol "Coba lagi", bukan otomatis.
    ProviderScope(retry: (_, _) => null, child: const SmartApp()),
  );
}

class SmartApp extends ConsumerWidget {
  const SmartApp({super.key, this.googleFonts = true});

  final bool googleFonts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SMART',
      debugShowCheckedModeBanner: false,
      theme: buatTema(googleFonts: googleFonts),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) =>
          PemeriksaPembaruan(child: child ?? const SizedBox.shrink()),
    );
  }
}
