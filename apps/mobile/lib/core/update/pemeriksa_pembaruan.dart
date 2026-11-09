import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router.dart';
import 'app_update_checker.dart';

/// Memeriksa pembaruan sekali saat aplikasi dibuka dan setiap kembali ke latar depan (paling sering sekali per
/// enam jam). Tidak melakukan apa pun di luar Android atau pada build non-rilis.
class PemeriksaPembaruan extends ConsumerStatefulWidget {
  const PemeriksaPembaruan({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PemeriksaPembaruan> createState() => _PemeriksaPembaruanState();
}

class _PemeriksaPembaruanState extends ConsumerState<PemeriksaPembaruan>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _periksa());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _periksa();
  }

  void _periksa() {
    final kunci = ref.read(navigatorKeyProvider);
    AppUpdateChecker.otomatis(() => kunci.currentState?.overlay?.context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
