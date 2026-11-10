import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';
import '../data/chat_repository.dart';

final chatTersediaProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(chatRepositoryProvider).tersedia(),
);

final chatRiwayatProvider = FutureProvider.autoDispose<List<PesanChat>>(
  (ref) => ref.watch(chatRepositoryProvider).riwayat(),
);

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _isi = TextEditingController();
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirimPesan() async {
    final teks = _isi.text.trim();
    if (teks.isEmpty || _kirim) return;
    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      await ref.read(chatRepositoryProvider).kirim(teks);
      _isi.clear();
      ref.invalidate(chatRiwayatProvider);
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
  }

  Future<void> _hapus() async {
    await ref.read(chatRepositoryProvider).hapusRiwayat();
    ref.invalidate(chatRiwayatProvider);
  }

  Widget _gelembung(String teks, {required bool saya, TextStyle? gaya}) {
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
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(saya ? 18 : 4),
            bottomRight: Radius.circular(saya ? 4 : 18),
          ),
          boxShadow: saya ? null : bayanganKartu,
        ),
        child: Text(
          teks,
          style: saya ? const TextStyle(color: Colors.white) : gaya,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tersedia = ref.watch(chatTersediaProvider).value ?? true;
    final riwayat = ref.watch(chatRiwayatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot AI'),
        actions: [
          IconButton(
            tooltip: 'Hapus riwayat',
            onPressed: _hapus,
            icon: const Icon(Icons.delete_outline),
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
              data: (daftar) => daftar.isEmpty
                  ? _Saran(
                      onPilih: (s) {
                        _isi.text = s;
                        _kirimPesan();
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final p in daftar) ...[
                          _gelembung(p.pesan, saya: true),
                          _gelembung(
                            p.jawaban ?? 'Belum ada jawaban.',
                            saya: false,
                            gaya: t.bodyMedium,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          if (_galat != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_galat!, style: TextStyle(color: Warna.error)),
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
                      decoration: const InputDecoration(
                        hintText: 'Tulis pertanyaan',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _kirim ? null : _kirimPesan,
                    icon: _kirim
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

class _Saran extends StatelessWidget {
  const _Saran({required this.onPilih});

  final void Function(String) onPilih;

  static const _daftar = [
    'Beasiswa apa yang tenggatnya paling dekat?',
    'Beasiswa apa yang cocok untuk IPK saya?',
    'Berkas apa saja yang biasanya diminta?',
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.forum_rounded, size: 40, color: Warna.primary),
        const SizedBox(height: 12),
        Text('Tanya seputar beasiswa', style: t.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Jawaban disusun dari data beasiswa di SMART, bukan dari tebakan.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: 20),
        for (final s in _daftar)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionChip(label: Text(s), onPressed: () => onPilih(s)),
          ),
      ],
    );
  }
}
