import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/tombol_bulat.dart';
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
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TombolBulat.kembali(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text('Dokumen Saya', style: t.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Unggah transkrip, CV, atau sertifikat agar IPK dan skor bahasa terisi otomatis.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'PDF, DOCX, TXT, PNG, atau JPG, maksimal 5 MB. Gambar dibaca oleh layanan AI.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final e in _jenis.entries) ...[
                  ChipFilter(
                    label: e.value,
                    terpilih: pilihanJenis == e.key,
                    onTap: () => _c.jenis.value = e.key,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: kirim ? null : _unggah,
            child: kirim
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Unggah Dokumen'),
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
    final gagal = d.statusBaca == 'gagal';
    final keterangan = terbaca
        ? (d.ringkasan.isEmpty
              ? 'Terbaca'
              : 'Terbaca: ${d.ringkasan.join(', ')}')
        : gagal
        ? 'Belum terbaca, isi profil manual'
        : 'Sedang dibaca';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        border: Border.all(color: Warna.container4),
        boxShadow: bayanganKartu,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 52,
            decoration: BoxDecoration(
              color: Warna.container2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description_outlined, color: Warna.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.namaBerkas,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text('$jenis · $keterangan', style: t.bodySmall),
                const SizedBox(height: 6),
                terbaca
                    ? Lencana(
                        'Selesai',
                        latar: Warna.suksesSoft,
                        warna: Warna.sukses,
                      )
                    : gagal
                    ? Lencana(
                        'Gagal',
                        latar: Warna.errorSoft,
                        warna: Warna.error,
                      )
                    : Lencana(
                        'Menunggu',
                        latar: Warna.container4,
                        warna: Warna.navy,
                      ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            onPressed: onHapus,
            icon: Icon(Icons.delete_outline_rounded, color: Warna.muted),
          ),
        ],
      ),
    );
  }
}
