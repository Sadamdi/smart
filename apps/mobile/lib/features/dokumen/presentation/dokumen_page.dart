import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';
import '../domain/dokumen.dart';

final dokumenProvider = FutureProvider.autoDispose<List<Dokumen>>(
  (ref) => ref.watch(dokumenRepositoryProvider).daftar(),
);

const _jenis = {
  'cv': 'CV',
  'sertifikat': 'Sertifikat',
  'pengalaman_organisasi': 'Pengalaman organisasi',
};

class DokumenPage extends ConsumerStatefulWidget {
  const DokumenPage({super.key});

  @override
  ConsumerState<DokumenPage> createState() => _DokumenPageState();
}

class _DokumenPageState extends ConsumerState<DokumenPage> {
  String _pilihanJenis = 'cv';
  bool _kirim = false;

  Future<void> _unggah() async {
    final pesan = ScaffoldMessenger.of(context);
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    final berkas = hasil.isEmpty ? null : hasil.first;
    if (berkas?.path == null) return;
    setState(() => _kirim = true);
    try {
      await ref
          .read(dokumenRepositoryProvider)
          .unggah(jenis: _pilihanJenis, path: berkas!.path!, nama: berkas.name);
      ref.invalidate(dokumenProvider);
      pesan.showSnackBar(const SnackBar(content: Text('Dokumen diunggah.')));
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
  }

  Future<void> _hapus(Dokumen d) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await ref.read(dokumenRepositoryProvider).hapus(d.id);
      ref.invalidate(dokumenProvider);
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final nilai = ref.watch(dokumenProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dokumen Saya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Unggah CV atau sertifikat (PDF, DOCX, TXT, PNG, JPG, maksimal 5 MB). Sistem membaca IPK, semester, dan skor bahasa. Gambar dibaca oleh layanan AI.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _pilihanJenis,
            decoration: const InputDecoration(labelText: 'Jenis dokumen'),
            items: [
              for (final e in _jenis.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _pilihanJenis = v ?? 'cv'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _kirim ? null : _unggah,
            icon: _kirim
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: Text(_kirim ? 'Mengunggah' : 'Pilih berkas'),
          ),
          const SizedBox(height: 20),
          nilai.when(
            loading: () => const MemuatState(),
            error: (e, _) => Text(pesanGalat(e)),
            data: (daftar) => daftar.isEmpty
                ? const KosongState(
                    judul: 'Belum ada dokumen',
                    pesan: 'Dokumen yang diunggah tampil di sini.',
                    ikon: Icons.description_outlined,
                  )
                : Column(
                    children: [
                      for (final d in daftar)
                        _KartuDokumen(
                          d: d,
                          jenis: _jenis[d.jenis] ?? d.jenis,
                          onHapus: () => _hapus(d),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _KartuDokumen extends StatelessWidget {
  const _KartuDokumen({
    required this.d,
    required this.jenis,
    required this.onHapus,
  });

  final Dokumen d;
  final String jenis;
  final VoidCallback onHapus;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final terbaca = d.statusBaca == 'selesai';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Warna.container2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.description_rounded, color: Warna.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.namaBerkas, style: t.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '$jenis · ${terbaca ? 'Terbaca' : 'Belum terbaca, isi profil manual'}',
                  style: t.bodySmall?.copyWith(
                    color: terbaca ? Warna.sukses : Warna.muted,
                  ),
                ),
                if (d.ringkasan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(d.ringkasan.join(', '), style: t.bodySmall),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: onHapus,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
