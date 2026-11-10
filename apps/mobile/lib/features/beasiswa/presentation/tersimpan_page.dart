import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/dependensi.dart';
import '../../../core/widgets/kartu_beasiswa.dart';
import '../../../core/widgets/state_widgets.dart';
import '../domain/beasiswa.dart';
import 'tersimpan_controller.dart';

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

class TersimpanPage extends StatefulWidget {
  const TersimpanPage({super.key});

  @override
  State<TersimpanPage> createState() => _TersimpanPageState();
}

class _TersimpanPageState extends State<TersimpanPage> {
  final _c = Get.find<TersimpanController>();

  @override
  void initState() {
    super.initState();
    // Selalu muat ulang saat halaman dibuka agar daftar mengikuti perubahan terbaru.
    _c.daftar.muat();
  }

  Future<void> _hapus(BuildContext context, BeasiswaRingkas b) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await _c.hapus(b.id);
      pesan.hideCurrentSnackBar();
      pesan.showSnackBar(
        SnackBar(
          content: Text('${b.nama} dihapus dari tersimpan.'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () async {
              try {
                await _c.simpan(b.id);
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
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Future<void> muatUlang() => _c.daftar.muat();

    return Scaffold(
      appBar: AppBar(title: const Text('Beasiswa Tersimpan')),
      body: Obx(
        () => AsyncIsi<List<BeasiswaRingkas>>(
          nilai: _c.daftar.state.value,
          ulang: _c.daftar.muat,
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
                      onSimpan: () => _hapus(context, b),
                      onBuka: () => context.push('/beasiswa/${b.id}'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
