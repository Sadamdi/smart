import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/lokal/mesin_lokal.dart';
import '../../../core/lokal/model_ai.dart';

/// Meminta model AI di ponsel menjelaskan satu beasiswa terhadap profil: alasan rekomendasi dan hal yang perlu disiapkan.
/// Tampil hanya bila model AI luring sudah terpasang dan data lokal tersedia. Estimasi tetap perkiraan.
class TombolJelaskanAi extends StatefulWidget {
  const TombolJelaskanAi({super.key, required this.nama});

  final String nama;

  @override
  State<TombolJelaskanAi> createState() => _TombolJelaskanAiState();
}

class _TombolJelaskanAiState extends State<TombolJelaskanAi> {
  final _ai = Get.find<PengelolaModelAi>();
  final _mesin = Get.find<MesinLokal>();
  bool _sibuk = false;

  /// Mengunduh laman resmi beasiswa (bukan server SMART) dan menyaring teksnya. Gagal atau tanpa internet: kosong.
  Future<String?> _ambilLamanResmi() async {
    final url = _mesin.tautanResmi(widget.nama);
    if (url == null) return null;
    try {
      final r = await Dio().get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      var teks = r.data ?? '';
      teks = teks
          .replaceAll(
            RegExp(
              r'<(script|style)[^>]*>.*?</\1>',
              dotAll: true,
              caseSensitive: false,
            ),
            ' ',
          )
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'&nbsp;|&amp;'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return teks.length > 2500 ? teks.substring(0, 2500) : teks;
    } on Object {
      return null;
    }
  }

  Future<void> _jelaskan() async {
    setState(() => _sibuk = true);
    String hasil;
    try {
      final pertanyaan =
          'Jelaskan singkat mengapa beasiswa ${widget.nama} cocok atau belum cocok untukku, lalu sebutkan 3 hal yang perlu kusiapkan.';
      var konteks = _mesin.konteksChat(widget.nama);
      // Bila ada internet, ambil isi laman resmi sekarang supaya syarat dan tenggat terbaru ikut dipertimbangkan.
      final laman = await _ambilLamanResmi();
      if (laman != null && laman.isNotEmpty) {
        konteks =
            '$konteks\nIsi laman resmi (diambil sekarang, ringkas):\n$laman';
      }
      hasil = await _ai.jawab(pertanyaan, konteks);
      if (hasil.isEmpty) hasil = 'Model belum memberi jawaban. Coba lagi.';
    } on Object catch (e) {
      hasil = 'Model AI belum bisa dipakai sekarang: $e';
    }
    if (!mounted) return;
    setState(() => _sibuk = false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            shrinkWrap: true,
            children: [
              Text(
                'Penjelasan AI di ponsel',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(hasil, style: Theme.of(ctx).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(
                'Dijawab model di ponselmu dari data beasiswa dan profil. Estimasi hanya perkiraan, bukan jaminan diterima.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_ai.status, _ai.aktifId]),
      builder: (context, _) {
        if (!_ai.dipakai || !_mesin.siap) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: OutlinedButton.icon(
            onPressed: _sibuk ? null : _jelaskan,
            icon: _sibuk
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(
              _sibuk ? 'Model berpikir' : 'Jelaskan dengan AI di ponsel',
            ),
          ),
        );
      },
    );
  }
}
