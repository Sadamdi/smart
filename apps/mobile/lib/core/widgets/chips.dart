import 'package:flutter/material.dart';

import '../../features/rekomendasi/domain/rekomendasi.dart';
import '../theme/app_theme.dart';

/// Chip filter yang dapat dipilih (Semua, S1, tab kategori).
class ChipFilter extends StatelessWidget {
  const ChipFilter({
    super.key,
    required this.label,
    required this.terpilih,
    required this.onTap,
  });

  final String label;
  final bool terpilih;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: terpilih,
      child: InkWell(
        borderRadius: BorderRadius.circular(Jari.bulat),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: terpilih ? Warna.primary : Warna.container2,
            borderRadius: BorderRadius.circular(Jari.bulat),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: terpilih ? Warna.putih : Warna.navy,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip status kecil: kategori rekomendasi, sisa hari, jenjang.
class ChipStatus extends StatelessWidget {
  const ChipStatus({
    super.key,
    required this.label,
    this.ikon,
    this.latar = Warna.container2,
    this.warna = Warna.navy,
  });

  final String label;
  final IconData? ikon;
  final Color latar;
  final Color warna;

  factory ChipStatus.kategori(Kategori k) {
    switch (k) {
      case Kategori.memenuhi:
        return const ChipStatus(
          label: 'Memenuhi syarat',
          ikon: Icons.check_circle,
          latar: Warna.suksesSoft,
          warna: Warna.sukses,
        );
      case Kategori.hampirMemenuhi:
        return const ChipStatus(
          label: 'Hampir memenuhi',
          ikon: Icons.timelapse,
          latar: Warna.container3,
          warna: Warna.primary,
        );
      case Kategori.belumMemenuhi:
        return const ChipStatus(
          label: 'Belum memenuhi',
          ikon: Icons.lock_outline,
          latar: Warna.container2,
          warna: Warna.muted,
        );
    }
  }

  factory ChipStatus.tenggat(String label, {required bool dekat}) => ChipStatus(
    label: label,
    ikon: Icons.timer_outlined,
    latar: dekat ? Warna.errorSoft : Warna.container2,
    warna: dekat ? Warna.error : Warna.navy,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(Jari.bulat),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 14, color: warna),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: warna, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
