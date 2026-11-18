import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/lokal/model_ai.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tombol_bulat.dart';

/// Pilih dan unduh model AI untuk chatbot luring: perangkat terdeteksi, daftar dari ringan ke berat, rekomendasi.
class ModelAiPage extends StatefulWidget {
  const ModelAiPage({super.key});

  @override
  State<ModelAiPage> createState() => _ModelAiPageState();
}

class _ModelAiPageState extends State<ModelAiPage> {
  final _p = Get.find<PengelolaModelAi>();

  @override
  void initState() {
    super.initState();
    _p.muat();
  }

  String _gb(double v) => v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

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
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _p.perangkat,
          _p.status,
          _p.kemajuan,
          _p.aktifId,
          _p.galat,
        ]),
        builder: (context, _) {
          final hp = _p.perangkat.value;
          final saran = hp == null ? null : modelDisarankan(hp);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              Text('Chatbot AI luring', style: t.headlineMedium),
              const SizedBox(height: 6),
              Text(
                'Unduh model bahasa kecil agar chatbot bisa menjawab tanpa jaringan. Model berjalan di ponsel, datamu tidak dikirim ke server. Unduhan besar, sebaiknya lewat Wi-Fi.',
                style: t.bodySmall,
              ),
              const SizedBox(height: 16),
              _KartuPerangkat(hp: hp, saran: saran),
              if (_p.galat.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _p.galat.value!,
                    style: t.bodySmall?.copyWith(color: Warna.error),
                  ),
                ),
              const SizedBox(height: 16),
              if (hp != null && !hp.didukung)
                Text(
                  'Ponsel ini belum didukung (butuh prosesor 64-bit dan Android 11 ke atas). Chatbot luring tetap menjawab dari data di ponsel tanpa model AI.',
                  style: t.bodyMedium,
                ),
              if (hp != null && hp.didukung)
                for (final m in katalogModelAi)
                  _KartuModel(
                    m: m,
                    cocok: m.cocokUntuk(hp),
                    disarankan: saran?.id == m.id,
                    status: _p.status.value[m.id] ?? StatusModel.belum,
                    persen: _p.kemajuan.value[m.id] ?? 0,
                    aktif: _p.aktifId.value == m.id,
                    ukuran: '${_gb(m.ukuranGb)} GB',
                    onUnduh: () => _unduh(m, hp),
                    onHapus: () => _p.hapus(m),
                    onPakai: () => _p.pakai(m),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _unduh(ModelAi m, PerangkatInfo hp) async {
    final kurangDisk =
        hp.diskBebasMb > 0 &&
        hp.diskBebasMb < m.ukuranByte / (1024 * 1024) * 1.3;
    if (m.cocokUntuk(hp) == Kecocokan.berat || kurangDisk) {
      final alasan = [
        if (m.cocokUntuk(hp) == Kecocokan.berat)
          '${m.nama} butuh RAM minimal sekitar ${_gb(m.ramMinGb)} GB, ponselmu ${_gb(hp.ramGb)} GB. Bisa sangat lambat, panas, atau aplikasi tertutup sendiri.',
        if (kurangDisk)
          'Ruang penyimpanan kosong ${_gb(hp.diskBebasMb / 1024)} GB, unduhan ${_gb(m.ukuranGb)} GB dan butuh sedikit ruang tambahan.',
      ];
      final lanjut = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Peringatan sebelum mengunduh'),
          content: Text('${alasan.join('\n\n')}\n\nTetap unduh?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tetap unduh'),
            ),
          ],
        ),
      );
      if (lanjut != true) return;
    }
    await _p.unduh(m);
  }
}

class _KartuPerangkat extends StatelessWidget {
  const _KartuPerangkat({required this.hp, required this.saran});

  final PerangkatInfo? hp;
  final ModelAi? saran;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        border: Border.all(color: Warna.container4),
      ),
      child: hp == null
          ? const Text('Mendeteksi perangkat')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hp!.nama,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                for (final baris in [
                  'RAM: ${hp!.ramGb.toStringAsFixed(1)} GB (kosong sekitar ${(hp!.ramBebasMb / 1024).toStringAsFixed(1)} GB)',
                  'Prosesor: ${hp!.soc} (${hp!.papan}), ${hp!.inti} inti, ${hp!.arm64 ? '64-bit' : '32-bit'}',
                  'GPU: ${hp!.vulkan ? 'mendukung Vulkan, percepatan GPU tersedia' : 'tanpa Vulkan, memakai prosesor'}',
                  'Penyimpanan kosong: ${(hp!.diskBebasMb / 1024).toStringAsFixed(1)} GB',
                  'Android: SDK ${hp!.sdk}',
                ])
                  Text(baris, style: t.bodySmall),
                const SizedBox(height: 8),
                Text(
                  !hp!.didukung
                      ? 'Tidak didukung untuk model AI luring.'
                      : saran == null
                      ? 'RAM ponsel ini terbatas; coba model paling ringan.'
                      : 'Saran untuk ponselmu: ${saran!.nama}.',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
    );
  }
}

class _KartuModel extends StatelessWidget {
  const _KartuModel({
    required this.m,
    required this.cocok,
    required this.disarankan,
    required this.status,
    required this.persen,
    required this.aktif,
    required this.ukuran,
    required this.onUnduh,
    required this.onHapus,
    required this.onPakai,
  });

  final ModelAi m;
  final Kecocokan cocok;
  final bool disarankan;
  final StatusModel status;
  final int persen;
  final bool aktif;
  final String ukuran;
  final VoidCallback onUnduh;
  final VoidCallback onHapus;
  final VoidCallback onPakai;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (label, warna) = switch (cocok) {
      Kecocokan.disarankan => ('Cocok untuk ponselmu', Warna.sukses),
      Kecocokan.bisa => ('Bisa dipakai, agak berat', Warna.muted),
      Kecocokan.berat => ('Terlalu berat untuk RAM ponselmu', Warna.error),
      Kecocokan.takDidukung => ('Tidak didukung', Warna.error),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        border: Border.all(
          color: aktif ? Warna.primary : Warna.container4,
          width: aktif ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.nama,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (disarankan)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Warna.suksesSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Disarankan',
                    style: t.labelSmall?.copyWith(
                      color: Warna.sukses,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${m.labelKelas} | $ukuran | RAM sekitar ${m.ramMinGb.toStringAsFixed(0)} GB',
            style: t.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(m.catatan, style: t.bodySmall),
          const SizedBox(height: 8),
          Text('Spesifikasi', style: t.labelLarge),
          const SizedBox(height: 2),
          Text('Parameter: ${m.parameter}', style: t.bodySmall),
          Text('Konteks: ${m.konteks}', style: t.bodySmall),
          Text('Kecepatan: ${m.kecepatan}', style: t.bodySmall),
          Text('Bahasa Indonesia: ${m.mutuIndonesia}', style: t.bodySmall),
          Text('Kemampuan: ${m.kemampuan.join(', ')}', style: t.bodySmall),
          const SizedBox(height: 4),
          Text('Untuk SMART: ${m.untukSmart}', style: t.bodySmall),
          const SizedBox(height: 6),
          Text(
            label,
            style: t.bodySmall?.copyWith(
              color: warna,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (status == StatusModel.mengunduh) ...[
            LinearProgressIndicator(value: persen <= 0 ? null : persen / 100),
            const SizedBox(height: 6),
            Text('Mengunduh $persen%', style: t.bodySmall),
          ] else if (status == StatusModel.terpasang)
            Row(
              children: [
                if (aktif)
                  Text(
                    'Sedang dipakai',
                    style: t.bodySmall?.copyWith(
                      color: Warna.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  FilledButton.tonal(
                    onPressed: onPakai,
                    child: const Text('Pakai model ini'),
                  ),
                const Spacer(),
                TextButton(onPressed: onHapus, child: const Text('Hapus')),
              ],
            )
          else
            FilledButton(
              onPressed: cocok == Kecocokan.takDidukung ? null : onUnduh,
              child: Text('Unduh $ukuran'),
            ),
        ],
      ),
    );
  }
}
