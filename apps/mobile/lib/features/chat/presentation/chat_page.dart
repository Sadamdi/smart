import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/tombol_bulat.dart';
import 'chat_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _c = Get.find<ChatController>();
  final _isi = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c.buka();
  }

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirimPesan() async {
    final ok = await _c.kirim(_isi.text.trim());
    if (ok) _isi.clear();
  }

  Widget _gelembung(
    String teks, {
    required bool saya,
    TextStyle? gaya,
    List<({String id, String nama})> rujukan = const [],
  }) {
    return Align(
      alignment: saya ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: saya ? Warna.primary : Warna.kartu,
          borderRadius: BorderRadius.circular(18),
          border: saya ? null : Border.all(color: Warna.container4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              teks,
              style: (gaya ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
                fontSize: 13,
                height: 1.45,
                color: saya ? Colors.white : null,
              ),
            ),
            if (rujukan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Sumber: data beasiswa SMART',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in rujukan.take(3))
                    ActionChip(
                      label: Text(r.nama, overflow: TextOverflow.ellipsis),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/beasiswa/${r.id}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _pil(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(26),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tersedia = _c.bisaMenjawab;
    final riwayat = _c.riwayat.state.value;
    final kirim = _c.mengirim.value;
    final galat = _c.galat.value;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TombolBulat.kembali(context),
        ),
        title: Text(
          'Chatbot Beasiswa',
          style: t.titleLarge?.copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Hapus riwayat',
            onPressed: _c.hapusRiwayat,
            icon: Icon(Icons.delete_outline, color: Warna.muted),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!tersedia)
            Container(
              width: double.infinity,
              color: Warna.errorSoft,
              padding: const EdgeInsets.all(12),
              child: Text(
                'Chatbot belum dapat menjawab saat ini. Anda tetap dapat menelusuri beasiswa dan melihat rekomendasi.',
                style: TextStyle(color: Warna.error),
              ),
            ),
          Expanded(
            child: riwayat.when(
              loading: () => const MemuatState(),
              error: (e, _) => Center(child: Text(pesanGalat(e))),
              data: (daftar) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _gelembung(
                    'Halo! Tanyakan syarat, tenggat, atau berkas beasiswa. Jawaban saya berdasarkan data di SMART.',
                    saya: false,
                    gaya: t.bodyMedium,
                  ),
                  for (final p in daftar) ...[
                    _gelembung(p.pesan, saya: true),
                    _gelembung(
                      p.jawaban ?? 'Belum ada jawaban.',
                      saya: false,
                      gaya: t.bodyMedium,
                      rujukan: p.rujukan,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (galat != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(galat, style: TextStyle(color: Warna.error)),
            ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final q in _Saran.daftar)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChipFilter(
                      label: q,
                      terpilih: false,
                      onTap: () {
                        _isi.text = q;
                        _kirimPesan();
                      },
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _isi,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _kirimPesan(),
                      decoration: InputDecoration(
                        hintText: 'Tulis pertanyaanmu',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: _pil(Warna.outline),
                        enabledBorder: _pil(Warna.outline),
                        focusedBorder: _pil(Warna.primary, 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Kirim',
                    style: IconButton.styleFrom(
                      backgroundColor: Warna.primary,
                      foregroundColor: Warna.putih,
                      minimumSize: const Size(48, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: kirim ? null : _kirimPesan,
                    icon: kirim
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Jawaban chatbot bukan jaminan diterima pada beasiswa mana pun.',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _Saran {
  static const daftar = [
    'Syarat IPK',
    'Berkas apa saja?',
    'Tenggat minggu ini',
    'Cocok untuk saya?',
  ];
}
