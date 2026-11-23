import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/tombol_bulat.dart';
import '../data/chat_repository.dart';
import 'chat_controller.dart';

/// Daftar percakapan (sesi) seperti di ChatGPT: pilih untuk membuka, mulai yang baru, ganti nama, atau hapus.
class SesiPage extends StatefulWidget {
  const SesiPage({super.key});

  @override
  State<SesiPage> createState() => _SesiPageState();
}

class _SesiPageState extends State<SesiPage> {
  final _c = Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    _c.daftarSesi.muat();
  }

  static String _waktu(DateTime w) {
    final d = DateTime.now().difference(w);
    if (d.inMinutes < 1) return 'baru saja';
    if (d.inMinutes < 60) return '${d.inMinutes} menit lalu';
    if (d.inHours < 24) return '${d.inHours} jam lalu';
    if (d.inDays < 7) return '${d.inDays} hari lalu';
    return '${w.day}/${w.month}/${w.year}';
  }

  void _info(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _buka(SesiChat s) async {
    await _c.pilihSesi(s);
    if (mounted) context.pop();
  }

  Future<void> _baru() async {
    await _c.sesiBaru();
    if (mounted) context.pop();
  }

  Future<void> _ganti(SesiChat s) async {
    final c = TextEditingController(text: s.judul);
    final baru = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti nama percakapan'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 60,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (baru == null || baru.trim().isEmpty) return;
    try {
      await _c.ubahJudulSesi(s, baru);
    } catch (e) {
      _info(pesanGalat(e));
    }
  }

  Future<void> _hapus(SesiChat s) async {
    try {
      await _c.hapusSesi(s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Percakapan dihapus'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () async => _info(await _c.urungkanHapus()),
          ),
        ),
      );
    } catch (e) {
      _info(pesanGalat(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TombolBulat.kembali(context),
        ),
        title: Text('Percakapan', style: t.titleLarge?.copyWith(fontSize: 18)),
        actions: [
          TextButton.icon(
            onPressed: _baru,
            icon: const Icon(Icons.add_comment_outlined),
            label: const Text('Baru'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final aktif = _c.sesiId.value;
        return _c.daftarSesi.state.value.when(
          loading: () => const MemuatState(),
          error: (e, _) => Center(child: Text(pesanGalat(e))),
          data: (daftar) {
            if (daftar.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Belum ada percakapan. Mulai dengan menanyakan syarat, tenggat, atau berkas beasiswa.',
                    style: t.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: _c.daftarSesi.muat,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: daftar.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = daftar[i];
                  final dipilih = s.id == aktif;
                  return Material(
                    color: Warna.kartu,
                    borderRadius: BorderRadius.circular(Jari.kartu),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(Jari.kartu),
                      onTap: () => _buka(s),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Jari.kartu),
                          border: Border.all(
                            color: dipilih ? Warna.primary : Warna.container4,
                            width: dipilih ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              s.lokal
                                  ? Icons.smartphone_rounded
                                  : Icons.chat_bubble_outline_rounded,
                              color: dipilih ? Warna.primary : Warna.muted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.judul,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: t.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${s.jumlah} pesan · ${_waktu(s.diubah)}'
                                    '${s.lokal ? ' · belum tersalin ke server' : ''}',
                                    style: t.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Menu percakapan',
                              onSelected: (k) =>
                                  k == 'ganti' ? _ganti(s) : _hapus(s),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'ganti',
                                  child: Text('Ganti nama'),
                                ),
                                PopupMenuItem(
                                  value: 'hapus',
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}
