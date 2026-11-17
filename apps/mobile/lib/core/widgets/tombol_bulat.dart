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
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Warna.container2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(ikon, size: 22, color: Warna.navy),
                ),
                if (lencana > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Warna.error,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Warna.surface, width: 1.5),
                      ),
                      child: Text(
                        lencana > 99 ? '99+' : '$lencana',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
