import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/kartu_beasiswa.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../kalender/presentation/kalender_providers.dart';
import '../domain/beasiswa.dart';
import 'beasiswa_providers.dart';

/// Tenggat terdekat lebih dulu; tanpa tenggat di belakangnya; yang sudah lewat paling akhir.
List<BeasiswaRingkas> urutkanTenggat(
  List<BeasiswaRingkas> daftar, {
  DateTime? sekarang,
}) {
  int kelompok(BeasiswaRingkas b) {
    final t = b.tenggat;
    if (t == null) return 1;
    return sisaHari(t, sekarang: sekarang) < 0 ? 2 : 0;
  }

  final hasil = [...daftar];
  hasil.sort((a, b) {
    final k = kelompok(a).compareTo(kelompok(b));
    if (k != 0) return k;
    if (a.tenggat == null || b.tenggat == null) return a.nama.compareTo(b.nama);
    return a.tenggat!.compareTo(b.tenggat!);
  });
  return hasil;
}

class TersimpanPage extends ConsumerWidget {
  const TersimpanPage({super.key});

  Future<void> _hapus(
    BuildContext context,
    WidgetRef ref,
    BeasiswaRingkas b,
  ) async {
    final repo = ref.read(beasiswaRepositoryProvider);
    final pesan = ScaffoldMessenger.of(context);
    void segarkan() {
      ref.invalidate(daftarTersimpanProvider);
      ref.invalidate(tersimpanProvider);
      ref.invalidate(checklistProvider);
    }

    try {
      await repo.hapusSimpan(b.id);
      segarkan();
      pesan.hideCurrentSnackBar();
      pesan.showSnackBar(
        SnackBar(
          content: Text('${b.nama} dihapus dari tersimpan.'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () async {
              try {
                await repo.simpan(b.id);
                segarkan();
              } catch (e) {
                pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
              }
            },
          ),
        ),
      );
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final nilai = ref.watch(daftarTersimpanProvider);
    Future<void> muatUlang() async {
      ref.invalidate(daftarTersimpanProvider);
      try {
        await ref.read(daftarTersimpanProvider.future);
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Beasiswa Tersimpan')),
      body: AsyncIsi<List<BeasiswaRingkas>>(
        nilai: nilai,
        ulang: () => ref.invalidate(daftarTersimpanProvider),
        bangun: (data) {
          if (data.isEmpty) {
            return RefreshIndicator(
              onRefresh: muatUlang,
              child: LayoutBuilder(
                builder: (context, c) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: KosongState(
                        ikon: Icons.bookmark_border_rounded,
                        judul: 'Belum ada beasiswa tersimpan',
                        pesan: 'Buka Jelajah, lalu ketuk ikon bookmark pada beasiswa yang ingin Anda pantau tenggatnya.',
                        aksi: () => context.go('/jelajah'),
                        labelAksi: 'Jelajahi beasiswa',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final urut = urutkanTenggat(data);
          final dekat = urut
              .where(
                (b) =>
                    b.tenggat != null &&
                    sisaHari(b.tenggat!) >= 0 &&
                    sisaHari(b.tenggat!) <= 7,
              )
              .length;
          return RefreshIndicator(
            onRefresh: muatUlang,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  dekat > 0
                      ? '${urut.length} beasiswa, $dekat bertenggat dalam 7 hari. Diurutkan dari tenggat terdekat.'
                      : '${urut.length} beasiswa. Diurutkan dari tenggat terdekat.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final b in urut) ...[
                  KartuBeasiswa(
                    key: ValueKey(b.id),
                    beasiswa: b,
                    tersimpan: true,
                    onSimpan: () => _hapus(context, ref, b),
                    onBuka: () => context.push('/beasiswa/${b.id}'),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
