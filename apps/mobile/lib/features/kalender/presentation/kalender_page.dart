import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/metrik_dan_progres.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../../../core/widgets/state_widgets.dart';
import '../domain/kalender.dart';
import 'kalender_providers.dart';

class KalenderPage extends ConsumerStatefulWidget {
  const KalenderPage({super.key});

  @override
  ConsumerState<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends ConsumerState<KalenderPage> {
  late DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);

  void _geser(int n) =>
      setState(() => _bulan = DateTime(_bulan.year, _bulan.month + n));

  Future<void> _tambahTugas() async {
    final judul = TextEditingController();
    var tanggal = DateTime.now();
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Tugas pribadi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: judul,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Judul tugas',
                  hintText: 'Contoh: minta surat rekomendasi dosen',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.event),
                label: Text(formatTanggal(tanggal)),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: tanggal,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (d != null) setD(() => tanggal = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(90, 40)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    final teks = judul.text.trim();
    judul.dispose();
    if (hasil != true || !mounted) return;
    if (teks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul tugas tidak boleh kosong.')),
      );
      return;
    }
    await _jalankan(() async {
      await ref.read(kalenderRepositoryProvider).tambahTugas(teks, tanggal);
    });
  }

  Future<void> _jalankan(Future<void> Function() aksi) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await aksi();
      ref.invalidate(kalenderProvider);
      ref.invalidate(checklistProvider);
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final kalender = ref.watch(kalenderProvider);
    final checklist = ref.watch(checklistProvider);
    final repo = ref.read(kalenderRepositoryProvider);

    return Scaffold(
      appBar: const SmartAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahTugas,
        backgroundColor: Warna.primary,
        foregroundColor: Warna.putih,
        icon: const Icon(Icons.add),
        label: const Text('Tugas'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(kalenderProvider);
          ref.invalidate(checklistProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Text('Kalender dan Checklist', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Tenggat beasiswa tersimpan, tugas pribadi, dan berkas yang perlu disiapkan.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 16),
            kalender.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: MemuatState(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: () => ref.invalidate(kalenderProvider),
                ),
              ),
              data: (acara) {
                final bulanIni = acara
                    .where(
                      (a) =>
                          a.tanggal.year == _bulan.year &&
                          a.tanggal.month == _bulan.month,
                    )
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GridBulan(
                      bulan: _bulan,
                      acara: bulanIni,
                      mundur: () => _geser(-1),
                      maju: () => _geser(1),
                    ),
                    const SizedBox(height: 16),
                    JudulBagian(
                      'Agenda ${namaBulan(_bulan.month)} ${_bulan.year}',
                    ),
                    if (bulanIni.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Tidak ada tenggat atau tugas pada bulan ini. Simpan beasiswa atau tambah tugas pribadi.',
                        ),
                      ),
                    for (final a in bulanIni)
                      _BarisAcara(
                        acara: a,
                        onBuka: a.tenggat
                            ? () => context.push('/beasiswa/${a.refId}')
                            : null,
                        onSelesai: a.tenggat
                            ? null
                            : (v) => _jalankan(
                                () => repo.selesaikanTugas(a.refId, v),
                              ),
                        onHapus: a.tenggat
                            ? null
                            : () => _jalankan(() => repo.hapusTugas(a.refId)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const JudulBagian('Checklist Berkas'),
            const SizedBox(height: 8),
            checklist.when(
              loading: () => const SizedBox(height: 100, child: MemuatState()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: () => ref.invalidate(checklistProvider),
                ),
              ),
              data: (daftar) {
                if (daftar.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: KosongState(
                      ikon: Icons.checklist,
                      judul: 'Belum ada checklist',
                      pesan: 'Simpan beasiswa dari Jelajah atau Rekomendasi, lalu daftar berkas wajibnya muncul di sini.',
                      aksi: () => context.go('/jelajah'),
                      labelAksi: 'Jelajah beasiswa',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final c in daftar)
                      _KartuChecklist(
                        data: c,
                        onCentang: (b, v) =>
                            _jalankan(() => repo.centang(b.id, v)),
                        onBuka: () =>
                            context.push('/beasiswa/${c.beasiswa.id}'),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GridBulan extends StatelessWidget {
  const _GridBulan({
    required this.bulan,
    required this.acara,
    required this.mundur,
    required this.maju,
  });

  final DateTime bulan;
  final List<Acara> acara;
  final VoidCallback mundur;
  final VoidCallback maju;

  static const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final jumlah = DateTime(bulan.year, bulan.month + 1, 0).day;
    final geser = DateTime(bulan.year, bulan.month, 1).weekday - 1;
    final n = DateTime.now();
    final tenggat = {
      for (final a in acara.where((a) => a.tenggat)) a.tanggal.day,
    };
    final tugas = {
      for (final a in acara.where((a) => !a.tenggat)) a.tanggal.day,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Bulan sebelumnya',
                onPressed: mundur,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${namaBulan(bulan.month)} ${bulan.year}',
                  textAlign: TextAlign.center,
                  style: t.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Bulan berikutnya',
                onPressed: maju,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final h in _hari)
                Expanded(
                  child: Center(child: Text(h, style: t.labelSmall)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: [
              for (var i = 0; i < geser; i++) const SizedBox.shrink(),
              for (var d = 1; d <= jumlah; d++)
                _Sel(
                  hari: d,
                  hariIni:
                      n.year == bulan.year &&
                      n.month == bulan.month &&
                      n.day == d,
                  tenggat: tenggat.contains(d),
                  tugas: tugas.contains(d),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, size: 8, color: Warna.error),
              const SizedBox(width: 4),
              Text('Tenggat', style: t.bodySmall),
              const SizedBox(width: 16),
              Icon(Icons.circle, size: 8, color: Warna.primary),
              const SizedBox(width: 4),
              Text('Tugas pribadi', style: t.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sel extends StatelessWidget {
  const _Sel({
    required this.hari,
    required this.hariIni,
    required this.tenggat,
    required this.tugas,
  });

  final int hari;
  final bool hariIni;
  final bool tenggat;
  final bool tugas;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: hariIni ? Warna.primary : (tenggat ? Warna.errorSoft : null),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$hari',
              style: t.bodyMedium?.copyWith(
                color: hariIni
                    ? Warna.putih
                    : (tenggat ? Warna.error : Warna.ink),
                fontWeight: tenggat || hariIni ? FontWeight.w700 : null,
              ),
            ),
            if (tugas)
              Positioned(
                bottom: 3,
                child: Icon(Icons.circle, size: 5, color: Warna.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarisAcara extends StatelessWidget {
  const _BarisAcara({
    required this.acara,
    this.onBuka,
    this.onSelesai,
    this.onHapus,
  });

  final Acara acara;
  final VoidCallback? onBuka;
  final ValueChanged<bool>? onSelesai;
  final VoidCallback? onHapus;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Jari.kartuDalam),
        boxShadow: bayanganKartu,
      ),
      child: Material(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartuDalam),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onBuka,
          leading: acara.tenggat
              ? CircleAvatar(
                  backgroundColor: Warna.errorSoft,
                  child: Icon(Icons.timer_outlined, color: Warna.error),
                )
              : Checkbox(
                  value: acara.selesai,
                  onChanged: (v) => onSelesai?.call(v ?? false),
                ),
          title: Text(
            acara.judul,
            style: t.titleSmall?.copyWith(
              decoration: acara.selesai ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            '${formatTanggal(acara.tanggal)} · ${acara.tenggat ? 'Tenggat pendaftaran' : 'Tugas pribadi'}',
            style: t.bodySmall,
          ),
          trailing: onHapus == null
              ? const Icon(Icons.chevron_right)
              : IconButton(
                  tooltip: 'Hapus tugas',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onHapus,
                ),
        ),
      ),
    );
  }
}

class _KartuChecklist extends StatelessWidget {
  const _KartuChecklist({
    required this.data,
    required this.onCentang,
    required this.onBuka,
  });

  final ChecklistBeasiswa data;
  final void Function(BerkasChecklist, bool) onCentang;
  final VoidCallback onBuka;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = data.berkas.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onBuka,
              child: Row(
                children: [
                  Expanded(
                    child: Text(data.beasiswa.nama, style: t.titleSmall),
                  ),
                  ChipStatus(label: '${data.jumlahSelesai}/$total siap'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            BarProgres(nilai: total == 0 ? 0 : data.jumlahSelesai / total),
            for (final b in data.berkas)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: b.selesai,
                title: Text(
                  b.namaBerkas,
                  style: TextStyle(
                    decoration: b.selesai ? TextDecoration.lineThrough : null,
                  ),
                ),
                onChanged: (v) => onCentang(b, v ?? false),
              ),
          ],
        ),
      ),
    );
  }
}
