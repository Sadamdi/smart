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
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Versi aplikasi'),
          subtitle: Text(
            i == null ? '...' : '${i.version} (build ${i.buildNumber})',
          ),
        );
      },
    );
  }
}
