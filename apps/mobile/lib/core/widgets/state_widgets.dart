import 'package:flutter/material.dart';

import '../async_state.dart';
import '../dependensi.dart';
import '../theme/app_theme.dart';

class KosongState extends StatelessWidget {
  const KosongState({
    super.key,
    required this.judul,
    required this.pesan,
    this.ikon = Icons.inbox_outlined,
    this.aksi,
    this.labelAksi,
  });

  final String judul;
  final String pesan;
  final IconData ikon;
  final VoidCallback? aksi;
  final String? labelAksi;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Warna.container2,
              child: Icon(ikon, size: 30, color: Warna.primary),
            ),
            const SizedBox(height: 16),
            Text(judul, style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(pesan, style: t.bodyMedium, textAlign: TextAlign.center),
            if (aksi != null && labelAksi != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: aksi,
                style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                child: Text(labelAksi!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MemuatState extends StatelessWidget {
  const MemuatState({super.key, this.pesan = 'Memuat data...'});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(pesan, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class GalatState extends StatelessWidget {
  const GalatState({super.key, required this.pesan, required this.cobaLagi});

  final String pesan;
  final VoidCallback cobaLagi;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Warna.errorSoft,
              child: Icon(Icons.cloud_off_outlined, color: Warna.error),
            ),
            const SizedBox(height: 16),
            Text('Data belum dapat dimuat', style: t.titleMedium),
            const SizedBox(height: 8),
            Text(pesan, style: t.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: cobaLagi,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
              style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Merangkum tiga keadaan layar untuk [AsyncState]: memuat, galat, dan data.
class AsyncIsi<T> extends StatelessWidget {
  const AsyncIsi({
    super.key,
    required this.nilai,
    required this.ulang,
    required this.bangun,
  });

  final AsyncState<T> nilai;
  final VoidCallback ulang;
  final Widget Function(T data) bangun;

  @override
  Widget build(BuildContext context) {
    return nilai.when(
      loading: () => const MemuatState(),
      error: (e, _) => GalatState(pesan: pesanGalat(e), cobaLagi: ulang),
      data: bangun,
    );
  }
}
