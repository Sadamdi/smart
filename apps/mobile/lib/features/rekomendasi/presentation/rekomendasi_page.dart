import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/kartu_beasiswa.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../beasiswa/presentation/beasiswa_providers.dart';
import '../../beasiswa/presentation/simpan_aksi.dart';
import '../domain/rekomendasi.dart';
import 'rekomendasi_providers.dart';

class RekomendasiPage extends ConsumerStatefulWidget {
  const RekomendasiPage({super.key});

  @override
  ConsumerState<RekomendasiPage> createState() => _RekomendasiPageState();
}

class _RekomendasiPageState extends ConsumerState<RekomendasiPage> {
  Kategori? _kategori;
  bool _menghitung = false;

  Future<void> _hitungUlang() async {
    setState(() => _menghitung = true);
    final pesan = ScaffoldMessenger.of(context);
    try {
      await ref.read(rekomendasiRepositoryProvider).hitungUlang();
      ref.invalidate(rekomendasiProvider);
      ref.invalidate(ringkasanRekomendasiProvider);
      pesan.showSnackBar(
        const SnackBar(content: Text('Rekomendasi dihitung ulang.')),
      );
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    } finally {
      if (mounted) setState(() => _menghitung = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final nilai = ref.watch(rekomendasiProvider(_kategori));
    final ringkasan = ref.watch(ringkasanRekomendasiProvider).value;
    final tersimpan = ref.watch(tersimpanProvider).value ?? <String>{};

    String hitung(Kategori? k, String label) {
      if (ringkasan == null) return label;
      final n = switch (k) {
        null =>
          ringkasan.memenuhi +
              ringkasan.hampirMemenuhi +
              ringkasan.belumMemenuhi,
        Kategori.memenuhi => ringkasan.memenuhi,
        Kategori.hampirMemenuhi => ringkasan.hampirMemenuhi,
        Kategori.belumMemenuhi => ringkasan.belumMemenuhi,
      };
      return '$label ($n)';
    }

    return Scaffold(
      appBar: const SmartAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rekomendasiProvider);
          ref.invalidate(ringkasanRekomendasiProvider);
          await ref
              .read(rekomendasiProvider(_kategori).future)
              .catchError((_) => <Rekomendasi>[]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Rekomendasi Beasiswa', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Dihasilkan Mesin Rekomendasi dari profil akademikmu. Setiap hasil menyertakan alasan dan catatan kekurangan.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChipFilter(
                    label: hitung(null, 'Semua'),
                    terpilih: _kategori == null,
                    onTap: () => setState(() => _kategori = null),
                  ),
                  for (final k in Kategori.values) ...[
                    const SizedBox(width: 8),
                    ChipFilter(
                      label: hitung(k, k.label),
                      terpilih: _kategori == k,
                      onTap: () => setState(() => _kategori = k),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _menghitung ? null : _hitungUlang,
                icon: _menghitung
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('Hitung ulang'),
              ),
            ),
            nilai.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 60),
                child: MemuatState(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.only(top: 40),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: () =>
                      ref.invalidate(rekomendasiProvider(_kategori)),
                ),
              ),
              data: (daftar) {
                if (daftar.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: KosongState(
                      ikon: Icons.person_search_outlined,
                      judul: 'Belum ada rekomendasi',
                      pesan: 'Lengkapi profil akademik (kampus, jenjang, semester, IPK) agar Mesin Rekomendasi dapat bekerja, lalu hitung ulang.',
                      aksi: () => context.go('/profil'),
                      labelAksi: 'Lengkapi profil',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final r in daftar) ...[
                      KartuBeasiswa(
                        key: ValueKey('${r.beasiswa.id}-${r.kategori.kode}'),
                        beasiswa: r.beasiswa,
                        kategori: r.kategori,
                        alasan: r.alasan,
                        catatan: r.catatanKekurangan,
                        tersimpan: tersimpan.contains(r.beasiswa.id),
                        onSimpan: () => ubahSimpan(
                          context,
                          ref,
                          r.beasiswa.id,
                          tersimpan: tersimpan.contains(r.beasiswa.id),
                        ),
                        labelAksi: 'Lihat detail dan syarat',
                        onBuka: () =>
                            context.push('/beasiswa/${r.beasiswa.id}'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
