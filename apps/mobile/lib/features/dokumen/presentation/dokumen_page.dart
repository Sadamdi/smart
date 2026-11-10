import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';
import '../domain/dokumen.dart';
import 'dokumen_controller.dart';

const _jenis = {
  'cv': 'CV',
  'sertifikat': 'Sertifikat',
  'pengalaman_organisasi': 'Pengalaman organisasi',
};

class DokumenPage extends StatefulWidget {
  const DokumenPage({super.key});

  @override
  State<DokumenPage> createState() => _DokumenPageState();
}

class _DokumenPageState extends State<DokumenPage> {
  final _c = Get.find<DokumenController>();

  @override
  void initState() {
    super.initState();
    _c.daftar.muat();
  }

  Future<void> _unggah() async {
    final pesan = ScaffoldMessenger.of(context);
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    final berkas = hasil.isEmpty ? null : hasil.first;
    if (berkas?.path == null) return;
    try {
      await _c.unggah(berkas!.path!, berkas.name);
      pesan.showSnackBar(const SnackBar(content: Text('Dokumen diunggah.')));
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  Future<void> _hapus(Dokumen d) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await _c.hapus(d.id);
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final nilai = _c.daftar.state.value;
    final pilihanJenis = _c.jenis.value;
    final kirim = _c.mengirim.value;
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
            initialValue: pilihanJenis,
            decoration: const InputDecoration(labelText: 'Jenis dokumen'),
            items: [
              for (final e in _jenis.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => _c.jenis.value = v ?? 'cv',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: kirim ? null : _unggah,
            icon: kirim
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: Text(kirim ? 'Mengunggah' : 'Pilih berkas'),
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
