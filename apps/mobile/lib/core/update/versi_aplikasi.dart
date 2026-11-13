import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Baris "Versi aplikasi" di Pengaturan: nama versi dan nomor build terpasang.
class TileVersiAplikasi extends StatelessWidget {
  const TileVersiAplikasi({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final i = snap.data;
        final t = Theme.of(context).textTheme;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Versi aplikasi',
            style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            i == null ? '...' : '${i.version} (build ${i.buildNumber})',
            style: t.bodySmall?.copyWith(fontSize: 11),
          ),
        );
      },
    );
  }
}
