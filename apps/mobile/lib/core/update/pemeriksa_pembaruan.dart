import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../dependensi.dart';
import 'app_update_checker.dart';
import 'pembaruan_controller.dart';

/// Memeriksa pembaruan sekali saat aplikasi dibuka dan setiap kembali ke latar depan (paling sering sekali per
/// enam jam). Tidak melakukan apa pun di luar Android atau pada build non-rilis.
class PemeriksaPembaruan extends StatefulWidget {
  const PemeriksaPembaruan({super.key, required this.child});

  final Widget child;

  @override
  State<PemeriksaPembaruan> createState() => _PemeriksaPembaruanState();
}

class _PemeriksaPembaruanState extends State<PemeriksaPembaruan>
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
    if (state == AppLifecycleState.resumed) {
      PembaruanController.instance.lanjutkanBilaTerhenti();
      _periksa();
    }
  }

  void _periksa() {
    final kunci = Get.find<NavigasiController>().kunci;
    AppUpdateChecker.otomatis(() => kunci.currentState?.overlay?.context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.bottomCenter,
          child: ListenableBuilder(
            listenable: PembaruanController.instance,
            builder: (context, _) {
              final c = PembaruanController.instance;
              if (c.tahap == TahapPembaruan.siap || c.dialogTerbuka) {
                return const SizedBox.shrink();
              }
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _BannerPembaruan(c: c),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Kemajuan pembaruan yang tetap terlihat walau dialog ditutup, sehingga unduhan tidak terasa hilang.
class _BannerPembaruan extends StatelessWidget {
  const _BannerPembaruan({required this.c});

  final PembaruanController c;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final persen = c.kemajuan == null
        ? null
        : (c.kemajuan! * 100).clamp(0, 100).round();
    final String judul;
    final List<Widget> aksi;
    switch (c.tahap) {
      case TahapPembaruan.mengunduh:
        judul = c.menungguJaringan
            ? 'Menunggu internet, unduhan dilanjutkan otomatis'
            : persen == null
            ? 'Menyiapkan pembaruan...'
            : 'Mengunduh pembaruan $persen%';
        aksi = [TextButton(onPressed: c.batal, child: const Text('Batal'))];
      case TahapPembaruan.memasang:
        judul = 'Pembaruan siap dipasang';
        aksi = [
          TextButton(onPressed: c.tutup, child: const Text('Tutup')),
          FilledButton(onPressed: c.pasang, child: const Text('Pasang')),
        ];
      case TahapPembaruan.gagal:
        judul = c.galat ?? 'Pembaruan gagal';
        aksi = [
          TextButton(onPressed: c.tutup, child: const Text('Tutup')),
          FilledButton(
            onPressed: () {
              final h = c.hasil;
              if (h != null) c.mulai(h);
            },
            child: Text(c.bisaLanjut ? 'Lanjutkan' : 'Coba lagi'),
          ),
        ];
      case TahapPembaruan.siap:
        return const SizedBox.shrink();
    }
    return Material(
      elevation: 6,
      color: skema.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (c.tahap == TahapPembaruan.mengunduh) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: c.kemajuan),
            ],
            Row(mainAxisAlignment: MainAxisAlignment.end, children: aksi),
          ],
        ),
      ),
    );
  }
}
