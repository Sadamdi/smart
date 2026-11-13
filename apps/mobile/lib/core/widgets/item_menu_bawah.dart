import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Satu tujuan pada menu bawah: ikon dalam kapsul penanda, label di bawahnya.
/// Label selalu satu baris; bila ruang sempit (layar 320 dp) huruf diperkecil lewat FittedBox,
/// tidak pernah turun ke baris kedua. Dipakai sebagai anak NavigationBar agar tata letak
/// dan animasi penanda tetap milik NavigationBar.
class ItemMenuBawah extends StatelessWidget {
  const ItemMenuBawah({
    super.key,
    required this.ikon,
    required this.ikonAktif,
    required this.label,
    required this.aktif,
    required this.onTap,
  });

  final IconData ikon;
  final IconData ikonAktif;
  final String label;
  final bool aktif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warna = aktif ? Warna.primary : Warna.muted;
    final gaya = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      letterSpacing: 0,
      fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
      color: warna,
    );
    return Semantics(
      button: true,
      selected: aktif,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 30,
              decoration: BoxDecoration(
                color: aktif ? Warna.container3 : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(aktif ? ikonAktif : ikon, size: 24, color: warna),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: gaya,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
