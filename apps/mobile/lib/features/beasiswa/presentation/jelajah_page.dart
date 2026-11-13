import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/kartu_beasiswa.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../../../core/widgets/state_widgets.dart';
import 'jelajah_controller.dart';
import 'simpan_aksi.dart';
import 'tersimpan_controller.dart';

class JelajahPage extends StatefulWidget {
  const JelajahPage({super.key});

  @override
  State<JelajahPage> createState() => _JelajahPageState();
}

class _JelajahPageState extends State<JelajahPage> {
  final _c = Get.find<JelajahController>();
  final _simpan = Get.find<TersimpanController>();
  final _cari = TextEditingController();
  Timer? _tunda;

  static const _jenjang = ['S1', 'S2', 'S3', 'D3', 'D4'];

  @override
  void initState() {
    super.initState();
    _c.pastikan();
    _simpan.idTersimpan.pastikan();
  }

  @override
  void dispose() {
    _tunda?.cancel();
    _cari.dispose();
    super.dispose();
  }

  void _onCari(String v) {
    _tunda?.cancel();
    _tunda = Timer(const Duration(milliseconds: 400), () => _c.cari(v));
  }

  OutlineInputBorder _bulat(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final s = _c.state.value;
    final c = _c;
    final tersimpan = _simpan.ids;
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
              'Beasiswa terbit yang tenggatnya belum lewat.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cari,
              onChanged: _onCari,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama beasiswa atau penyelenggara',
                prefixIcon: const Icon(Icons.search),
                border: _bulat(Warna.outline),
                enabledBorder: _bulat(Warna.outline),
                focusedBorder: _bulat(Warna.primary, 2),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChipFilter(
                    label: 'Semua',
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
            const SizedBox(height: 8),
            if (s.memuat || s.galat != null || s.items.isEmpty)
              _BarisInfo(
                teks: '',
                onTersimpan: () => context.push('/tersimpan'),
              ),
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
              _BarisInfo(
                teks: 'Menampilkan ${s.items.length} beasiswa',
                onTersimpan: () => context.push('/tersimpan'),
              ),
              const SizedBox(height: 4),
              for (final b in s.items) ...[
                KartuBeasiswa(
                  key: ValueKey(b.id),
                  beasiswa: b,
                  tersimpan: tersimpan.contains(b.id),
                  onSimpan: () => ubahSimpan(
                    context,
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

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({required this.teks, required this.onTersimpan});

  final String teks;
  final VoidCallback onTersimpan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(teks, style: t.bodySmall)),
        TextButton.icon(
          onPressed: onTersimpan,
          icon: const Icon(Icons.bookmark_border_rounded, size: 18),
          label: const Text('Tersimpan'),
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            textStyle: t.labelLarge?.copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
