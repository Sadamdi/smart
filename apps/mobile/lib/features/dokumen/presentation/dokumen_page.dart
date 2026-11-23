import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dependensi.dart';
import '../../../core/lokal/ekstrak_teks.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/tombol_bulat.dart';
import '../data/dokumen_repository.dart';
import '../domain/dokumen.dart';
import '../../chat/presentation/chat_controller.dart';
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
    _c.penyimpanan.muat();
  }

  Future<void> _unggah() async {
    final pesan = ScaffoldMessenger.of(context);
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ChatController.jenisDidukung,
    );
    final berkas = hasil.isEmpty ? null : hasil.first;
    if (berkas?.path == null) return;
    try {
      final info = await _c.unggah(berkas!.path!, berkas.name);
      pesan.showSnackBar(SnackBar(content: Text(info)));
    } on EkstrakGagal catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(e.pesan)));
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  Future<void> _bersihkan() async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      pesan.showSnackBar(SnackBar(content: Text(await _c.bersihkanRuang())));
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  Future<void> _lihat(Dokumen d) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        final teks = (d.hasilBaca?['ringkasan_teks'] ?? '') as String;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              shrinkWrap: true,
              children: [
                Text(d.namaBerkas, style: t.titleMedium),
                const SizedBox(height: 8),
                Text(
                  d.ringkasan.isEmpty
                      ? 'Belum ada nilai yang terbaca.'
                      : 'Terbaca: ${d.ringkasan.join(', ')}',
                  style: t.bodyMedium,
                ),
                if (teks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Cuplikan isi', style: t.labelLarge),
                  const SizedBox(height: 4),
                  Text(teks, style: t.bodySmall),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: d.adaBerkas
                      ? () {
                          Navigator.pop(ctx);
                          _bukaAsli(d);
                        }
                      : null,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(
                    d.adaBerkas
                        ? 'Buka berkas asli'
                        : 'Berkas asli tidak tersimpan',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _bukaAsli(Dokumen d) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      final jalur = await Get.find<DokumenRepository>().unduhAsli(
        d.id,
        d.namaBerkas,
      );
      final r = await OpenFilex.open(jalur);
      if (r.type != ResultType.done) {
        pesan.showSnackBar(
          const SnackBar(
            content: Text('Tidak ada aplikasi di HP untuk membuka berkas ini.'),
          ),
        );
      }
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
            'PDF, Word, PowerPoint, Excel, gambar, dan teks, maksimal 10 MB per berkas. Berkas disimpan di server agar bisa dilihat dari web dan HP. Tanpa jaringan, berkas diantrekan dan diunggah otomatis saat online.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 12),
          Obx(() => _KartuRuang(_c.penyimpanan.state.value.value, _bersihkan)),
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
            loading: () => const MemuatState(jam: true),
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
                          onLihat: () => _lihat(d),
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
    required this.onLihat,
  });

  final Dokumen d;
  final String jenis;
  final VoidCallback onHapus;
  final VoidCallback onLihat;

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
    final tambahan = d.asal == 'chat'
        ? 'Lampiran chat, dihapus otomatis bila 30 hari tak dipakai'
        : null;
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
                if (tambahan != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      tambahan,
                      style: t.bodySmall?.copyWith(color: Warna.muted),
                    ),
                  ),
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
            tooltip: 'Lihat isi',
            onPressed: onLihat,
            icon: Icon(Icons.visibility_outlined, color: Warna.primary),
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


/// Pemakaian ruang dokumen di server beserta tombol bersihkan manual.
class _KartuRuang extends StatelessWidget {
  const _KartuRuang(this.data, this.onBersihkan);

  final Map<String, dynamic>? data;
  final VoidCallback onBersihkan;

  @override
  Widget build(BuildContext context) {
    final d = data;
    if (d == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final terpakai = (d['terpakai_byte'] as num?)?.toInt() ?? 0;
    final maks = (d['maks_byte'] as num?)?.toInt() ?? 1;
    final persen = (d['persen'] as num?)?.toInt() ?? 0;
    final penuh = persen >= 80;
    String mb(int b) {
      if (b < 1024 * 1024) return '${(b / 1024).round()} KB';
      final v = b / (1024 * 1024);
      return v == v.roundToDouble() ? '${v.round()} MB' : '${v.toStringAsFixed(1)} MB';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        border: Border.all(color: penuh ? Warna.error : Warna.container4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ruang dokumen',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${mb(terpakai)} dari ${mb(maks)}', style: t.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (terpakai / maks).clamp(0.0, 1.0),
              minHeight: 8,
              color: penuh ? Warna.error : Warna.primary,
              backgroundColor: Warna.container4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            penuh
                ? 'Ruang hampir penuh. Lampiran chat lama dibersihkan otomatis, atau bersihkan sekarang.'
                : 'Lampiran chat yang 30 hari tak dipakai dan memori yang tak terpakai dibersihkan otomatis. Dokumen profil tidak pernah dihapus otomatis.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onBersihkan,
              icon: const Icon(Icons.cleaning_services_outlined, size: 18),
              label: const Text('Bersihkan yang tidak terpakai'),
            ),
          ),
        ],
      ),
    );
  }
}
