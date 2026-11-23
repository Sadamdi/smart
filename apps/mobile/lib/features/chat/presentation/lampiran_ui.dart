import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/lokal/ekstrak_teks.dart' show ekstensiDari;
import '../../../core/theme/app_theme.dart';
import '../../dokumen/data/dokumen_repository.dart';

/// Batas lampiran per pertanyaan: jumlah berkas dan ukuran tiap berkas (sama dengan batas server).
const lampiranMaksBerkas = 3;
const lampiranMaksByte = 10 * 1024 * 1024;

String ukuranTeks(int b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).round()} KB';
  final mb = b / (1024 * 1024);
  return mb == mb.roundToDouble() ? '${mb.round()} MB' : '${mb.toStringAsFixed(1)} MB';
}

/// Ikon, warna, dan label jenis berkas agar dikenali sekilas (seperti ChatGPT dan Claude).
({IconData ikon, Color warna, String label}) jenisBerkas(String nama) {
  final e = ekstensiDari(nama);
  return switch (e) {
    'pdf' => (
      ikon: Icons.picture_as_pdf_rounded,
      warna: const Color(0xFFD64545),
      label: 'PDF',
    ),
    'doc' || 'docx' || 'rtf' || 'odt' => (
      ikon: Icons.description_rounded,
      warna: const Color(0xFF2B6CB0),
      label: 'Word',
    ),
    'xls' || 'xlsx' || 'ods' || 'csv' || 'tsv' => (
      ikon: Icons.table_chart_rounded,
      warna: const Color(0xFF1E8E5A),
      label: e == 'csv' || e == 'tsv' ? e.toUpperCase() : 'Excel',
    ),
    'ppt' || 'pptx' || 'odp' => (
      ikon: Icons.slideshow_rounded,
      warna: const Color(0xFFE0782B),
      label: 'Slide',
    ),
    'png' || 'jpg' || 'jpeg' || 'webp' || 'bmp' || 'gif' || 'heic' => (
      ikon: Icons.image_rounded,
      warna: const Color(0xFF8B5CF6),
      label: 'Gambar',
    ),
    _ => (
      ikon: Icons.article_rounded,
      warna: Warna.primary,
      label: e.isEmpty ? 'Berkas' : e.toUpperCase(),
    ),
  };
}

Widget _ubin(String nama, {double ukuran = 36}) {
  final j = jenisBerkas(nama);
  return Container(
    width: ukuran,
    height: ukuran,
    decoration: BoxDecoration(
      color: j.warna.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(j.ikon, color: j.warna, size: ukuran * 0.56),
  );
}

/// Kartu lampiran di atas kolom tulis: jenis, nama, ukuran, status baca, dan tombol lepas.
class KartuLampiran extends StatelessWidget {
  const KartuLampiran({
    super.key,
    required this.nama,
    this.ukuran,
    this.status,
    this.membaca = false,
    this.onHapus,
    this.onTap,
  });

  final String nama;
  final int? ukuran;
  final String? status;
  final bool membaca;
  final VoidCallback? onHapus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final j = jenisBerkas(nama);
    final sub = [
      j.label,
      if (ukuran != null) ukuranTeks(ukuran!),
      if (membaca) 'Membaca...' else ?status,
    ].join('  ·  ');
    return Material(
      color: Warna.kartu,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: membaca ? null : onTap,
        child: Container(
          width: 292,
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Warna.container4),
          ),
          child: Row(
            children: [
              _ubin(nama),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              if (membaca)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (onHapus != null)
                IconButton(
                  tooltip: 'Lepas $nama',
                  visualDensity: VisualDensity.compact,
                  onPressed: onHapus,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lampiran yang tertanam di gelembung pesan pengguna; diketuk membuka pratinjau.
class ChipLampiranPesan extends StatelessWidget {
  const ChipLampiranPesan({super.key, required this.nama, this.teks});

  final String nama;
  final String? teks;

  @override
  Widget build(BuildContext context) {
    final j = jenisBerkas(nama);
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => tampilkanPratinjauLampiran(context, nama: nama, teks: teks),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(j.ikon, color: j.warna, size: 18),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      j.label,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> tampilkanPratinjauLampiran(
  BuildContext context, {
  required String nama,
  String? teks,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (_, kontrol) => _Pratinjau(nama, teks, kontrol),
    ),
  );
}

class _Pratinjau extends StatefulWidget {
  const _Pratinjau(this.nama, this.teks, this.kontrol);

  final String nama;
  final String? teks;
  final ScrollController kontrol;

  @override
  State<_Pratinjau> createState() => _PratinjauState();
}

class _PratinjauState extends State<_Pratinjau> {
  String? _teks;
  String? _idServer;
  String? _info;
  bool _memuat = false;
  bool _membuka = false;

  @override
  void initState() {
    super.initState();
    _teks = widget.teks;
    if (_teks == null) _muatDariServer();
  }

  Future<void> _muatDariServer() async {
    setState(() => _memuat = true);
    try {
      final daftar = await Get.find<DokumenRepository>().daftar();
      final d = daftar.firstWhereOrNull((x) => x.namaBerkas == widget.nama);
      if (!mounted) return;
      if (d == null) {
        setState(() => _info = 'Berkas ini tidak ada di server (mungkin sudah dihapus) dan teksnya tidak tersimpan di ponsel.');
      } else {
        setState(() {
          _idServer = d.id;
          final r = d.hasilBaca?['ringkasan_teks'];
          if (r is String && r.trim().isNotEmpty) _teks = r;
        });
      }
    } on Object {
      if (mounted) {
        setState(() => _info = 'Pratinjau butuh jaringan. Coba lagi saat online.');
      }
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _buka() async {
    final id = _idServer;
    if (id == null) return;
    setState(() => _membuka = true);
    try {
      final path = await Get.find<DokumenRepository>().unduhAsli(id, widget.nama);
      await OpenFilex.open(path);
    } on Object {
      if (mounted) setState(() => _info = 'Berkas tidak dapat dibuka. Periksa jaringan lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _membuka = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final j = jenisBerkas(widget.nama);
    final teks = _teks;
    final potong = teks != null && teks.length > 6000;
    return ListView(
      controller: widget.kontrol,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          children: [
            _ubin(widget.nama, ukuran: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(j.label, style: t.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_idServer != null)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _membuka ? null : _buka,
              icon: _membuka
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Buka berkas asli'),
            ),
          ),
        if (_memuat)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (teks != null) ...[
          const SizedBox(height: 12),
          Text('Teks yang dibaca asisten', style: t.labelLarge),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Warna.container1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Warna.container4),
            ),
            child: SelectableText(
              potong ? teks.substring(0, 6000) : teks,
              style: t.bodySmall?.copyWith(height: 1.5),
            ),
          ),
          if (potong)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Menampilkan bagian awal. Asisten membaca bagian yang paling relevan dengan pertanyaanmu.',
                style: t.bodySmall,
              ),
            ),
        ],
        if (_info != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_info!, style: t.bodyMedium),
          ),
      ],
    );
  }
}
