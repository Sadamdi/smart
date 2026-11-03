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
            icon: const Icon(Icons.upload_file),
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
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Warna.putih,
                            borderRadius: BorderRadius.circular(
                              Jari.kartuDalam,
                            ),
                            boxShadow: bayanganKartu,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d.namaBerkas, style: t.titleSmall),
                                    Text(
                                      '${_jenis[d.jenis] ?? d.jenis} | ${d.statusBaca == 'selesai' ? 'Terbaca' : 'Belum terbaca, isi profil manual'}',
                                      style: t.bodySmall,
                                    ),
                                    if (d.ringkasan.isNotEmpty)
                                      Text(
                                        d.ringkasan.join(', '),
                                        style: t.bodySmall,
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Hapus',
                                onPressed: () => _hapus(d),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
