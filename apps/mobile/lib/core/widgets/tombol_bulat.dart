import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Tombol bulat 40 dp berlatar lembut (kembali, simpan, lonceng) pada kepala halaman.
class TombolBulat extends StatelessWidget {
  const TombolBulat({
    super.key,
    required this.ikon,
    required this.tooltip,
    required this.onTap,
    this.lencana = 0,
  });

  /// Tombol kembali standar: kembali bila bisa, bila tidak ke Beranda.
  factory TombolBulat.kembali(BuildContext context) => TombolBulat(
    ikon: Icons.arrow_back_rounded,
    tooltip: 'Kembali',
    onTap: () => context.canPop() ? context.pop() : context.go('/'),
  );

  final IconData ikon;
  final String tooltip;
  final VoidCallback onTap;

  /// Jumlah belum dibaca; 0 menyembunyikan lencana.
  final int lencana;

  @override
  Widget build(BuildContext context) {
    // Lingkaran 40 dp seperti desain; area sentuhnya 48 dp.
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Warna.container2,
                  shape: BoxShape.circle,
                ),
                child: Badge(
                  isLabelVisible: lencana > 0,
                  label: Text('$lencana'),
                  child: Icon(ikon, size: 22, color: Warna.navy),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
