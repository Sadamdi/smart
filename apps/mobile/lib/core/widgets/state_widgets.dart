import 'package:flutter/material.dart';

import '../async_state.dart';
import '../dependensi.dart';
import '../theme/app_theme.dart';
import 'ilustrasi_gerak.dart';

class KosongState extends StatelessWidget {
  const KosongState({
    super.key,
    required this.judul,
    required this.pesan,
    this.ikon = Icons.inbox_outlined,
    this.ilustrasi,
    this.aksi,
    this.labelAksi,
  });

  final String judul;
  final String pesan;
  final IconData ikon;

  /// Ilustrasi bergerak pengganti ikon (Gulungan, LembarTerakhir).
  final Widget? ilustrasi;
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
            ilustrasi ??
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

/// Skeleton berbentuk kartu, sama dengan versi web: bentuknya menahan tata letak agar tidak melompat.
class MemuatState extends StatelessWidget {
  const MemuatState({
    super.key,
    this.pesan = 'Memuat data',
    this.baris = 4,
    this.jam = false,
  });

  final String pesan;
  final int baris;

  /// Menampilkan jam pasir kecil di atas skeleton; untuk daftar penuh (Jelajah, Rekomendasi, Dokumen).
  final bool jam;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: pesan,
      liveRegion: true,
      child: ExcludeSemantics(
        // Bukan ListView: dipakai di dalam ListView lain dan di dalam kotak berukuran tetap.
        // SingleChildScrollView tak bisa digulir, mengikuti tinggi isi bila tak dibatasi,
        // dan terpotong tanpa galat bila ruangnya lebih kecil.
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (jam) ...[
                const JamPasir(ukuran: 52),
                const SizedBox(height: 4),
                Text(
                  pesan,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(decoration: TextDecoration.none),
                ),
                const SizedBox(height: 14),
              ],
              for (var i = 0; i < baris; i++) const _KartuSkeleton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuSkeleton extends StatefulWidget {
  const _KartuSkeleton();

  @override
  State<_KartuSkeleton> createState() => _KartuSkeletonState();
}

class _KartuSkeletonState extends State<_KartuSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _blok(double? w, double h, {double r = 8}) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) {
      final g = _c.value * 4 - 2;
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment(-1 + g, 0),
            end: Alignment(1 + g, 0),
            colors: [Warna.container2, Warna.container3, Warna.container2],
            stops: const [0.25, 0.5, 0.75],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Warna.container4.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _blok(44, 44, r: 14),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _blok(lebar * 0.45, 14),
                  const SizedBox(height: 8),
                  _blok(lebar * 0.25, 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _blok(double.infinity, 10),
          const SizedBox(height: 8),
          _blok(lebar * 0.6, 10),
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
