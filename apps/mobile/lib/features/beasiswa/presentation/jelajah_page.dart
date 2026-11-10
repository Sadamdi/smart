import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/kartu_beasiswa.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../../../core/widgets/state_widgets.dart';
import 'beasiswa_providers.dart';
import 'simpan_aksi.dart';

class JelajahPage extends ConsumerStatefulWidget {
  const JelajahPage({super.key});

  @override
  ConsumerState<JelajahPage> createState() => _JelajahPageState();
}

class _JelajahPageState extends ConsumerState<JelajahPage> {
  final _cari = TextEditingController();
  Timer? _tunda;

  static const _jenjang = ['D3', 'D4', 'S1', 'S2', 'S3'];

  @override
  void dispose() {
    _tunda?.cancel();
    _cari.dispose();
    super.dispose();
  }

  void _onCari(String v) {
    _tunda?.cancel();
    _tunda = Timer(
      const Duration(milliseconds: 400),
      () => ref.read(jelajahProvider.notifier).cari(v),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(jelajahProvider);
    final c = ref.read(jelajahProvider.notifier);
    final tersimpan = ref.watch(tersimpanProvider).value ?? <String>{};
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const SmartAppBar(),
      body: RefreshIndicator(
        onRefresh: c.muat,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text('Jelajah Beasiswa', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Beasiswa terbit yang tenggatnya belum lewat, dipantau dari laman resmi.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push('/tersimpan'),
                icon: const Icon(Icons.bookmark_border_rounded),
                label: const Text('Tersimpan'),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cari,
              onChanged: _onCari,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Cari beasiswa',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChipFilter(
                    label: 'Semua jenjang',
                    terpilih: s.jenjang == null,
                    onTap: () => c.pilihJenjang(null),
                  ),
                  for (final j in _jenjang) ...[
                    const SizedBox(width: 8),
                    ChipFilter(
                      label: j,
                      terpilih: s.jenjang == j,
                      onTap: () => c.pilihJenjang(j),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (s.memuat)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: MemuatState(),
              )
            else if (s.galat != null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: GalatState(pesan: s.galat!, cobaLagi: c.muat),
              )
            else if (s.items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: KosongState(
                  ikon: Icons.search_off,
                  judul: 'Belum ada beasiswa yang sesuai',
                  pesan: s.q.isEmpty && s.jenjang == null
                      ? 'Belum ada beasiswa terbit saat ini. Tarik layar ke bawah untuk memuat ulang.'
                      : 'Ubah kata kunci atau hapus filter jenjang untuk melihat lebih banyak.',
                  aksi: s.jenjang == null && s.q.isEmpty
                      ? null
                      : () {
                          _cari.clear();
                          c.cari('');
                          c.pilihJenjang(null);
                        },
                  labelAksi: 'Hapus pencarian dan filter',
                ),
              )
            else ...[
              Text(
                'Menampilkan ${s.items.length} beasiswa',
                style: t.bodySmall,
              ),
              const SizedBox(height: 10),
              for (final b in s.items) ...[
                KartuBeasiswa(
                  key: ValueKey(b.id),
                  beasiswa: b,
                  tersimpan: tersimpan.contains(b.id),
                  onSimpan: () => ubahSimpan(
                    context,
                    ref,
                    b.id,
                    tersimpan: tersimpan.contains(b.id),
                  ),
                  onBuka: () => context.push('/beasiswa/${b.id}'),
                ),
                const SizedBox(height: 12),
              ],
              if (s.galatLagi != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    s.galatLagi!,
                    style: TextStyle(color: Warna.error),
                  ),
                ),
              if (s.adaLagi)
                OutlinedButton(
                  onPressed: s.memuatLagi ? null : c.lagi,
                  child: s.memuatLagi
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          s.galatLagi != null
                              ? 'Coba lagi'
                              : 'Muat beasiswa lainnya',
                        ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
