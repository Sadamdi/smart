import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/metrik_dan_progres.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../../../core/widgets/state_widgets.dart';
import '../domain/kalender.dart';
import 'kalender_controller.dart';

class KalenderPage extends StatefulWidget {
  const KalenderPage({super.key});

  @override
  State<KalenderPage> createState() => _KalenderPageState();
}

class _KalenderPageState extends State<KalenderPage> {
  final _c = Get.find<KalenderController>();

  @override
  void initState() {
    super.initState();
    _c.pastikanSemua();
  }

  late DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _pilih;

  /// Tanggal terpilih: pilihan pengguna bila masih di bulan tampil, bila tidak tenggat
  /// terdekat pada bulan itu (atau hari ini), sehingga bagian agenda tidak pernah kosong tanpa alasan.
  DateTime _tanggalAgenda(List<Acara> bulanIni) {
    final p = _pilih;
    if (p != null && p.year == _bulan.year && p.month == _bulan.month) {
      return p;
    }
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    final urut = bulanIni.where((a) => a.tenggat).map((a) => a.tanggal).toList()
      ..sort();
    final depan = urut.where((d) => !d.isBefore(hariIni));
    if (depan.isNotEmpty) return depan.first;
    if (urut.isNotEmpty) return urut.first;
    return n.year == _bulan.year && n.month == _bulan.month
        ? hariIni
        : DateTime(_bulan.year, _bulan.month);
  }

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
              style: FilledButton.styleFrom(minimumSize: const Size(90, 48)),
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
    await _jalankan(() => _c.tambahTugas(teks, tanggal));
  }

  Future<void> _jalankan(Future<void> Function() aksi) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await aksi();
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final kalender = _c.acara.state.value;
    final checklist = _c.checklist.state.value;

    return Scaffold(
      appBar: const SmartAppBar(),
      body: RefreshIndicator(
        onRefresh: _c.muatSemua,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            Text('Kalender', style: t.headlineMedium),
            const SizedBox(height: 14),
            kalender.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: MemuatState(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: _c.acara.muat,
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
                final pilih = _tanggalAgenda(bulanIni);
                final hariIni = bulanIni
                    .where(
                      (a) =>
                          a.tanggal.day == pilih.day &&
                          a.tanggal.month == pilih.month,
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
                      dipilih: pilih,
                      onPilih: (d) => setState(() => _pilih = d),
                    ),
                    const SizedBox(height: 16),
                    JudulBagian(
                      '${pilih.day} ${namaBulan(pilih.month)}',
                      aksi: '+ Tugas',
                      onAksi: _tambahTugas,
                    ),
                    if (hariIni.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          bulanIni.isEmpty
                              ? 'Tidak ada tenggat atau tugas pada bulan ini. Simpan beasiswa atau tambah tugas pribadi.'
                              : 'Tidak ada tenggat atau tugas pada tanggal ini.',
                          style: t.bodySmall,
                        ),
                      ),
                    for (final a in hariIni)
                      _BarisAcara(
                        acara: a,
                        onBuka: a.tenggat
                            ? () => context.push('/beasiswa/${a.refId}')
                            : null,
                        onSelesai: a.tenggat
                            ? null
                            : (v) => _jalankan(
                                () => _c.selesaikanTugas(a.refId, v),
                              ),
                        onHapus: a.tenggat
                            ? null
                            : () => _jalankan(() => _c.hapusTugas(a.refId)),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const JudulBagian('Checklist berkas'),
            const SizedBox(height: 8),
            checklist.when(
              loading: () => const SizedBox(height: 100, child: MemuatState()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: _c.checklist.muat,
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
                            _jalankan(() => _c.centang(b.id, v)),
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
    required this.dipilih,
    required this.onPilih,
  });

  final DateTime dipilih;
  final ValueChanged<DateTime> onPilih;
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

    final kartu = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Warna.container4),
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
                  child: Center(
                    child: Text(
                      h,
                      style: t.labelSmall?.copyWith(letterSpacing: 0),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.1,
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
                  onTap: () => onPilih(DateTime(bulan.year, bulan.month, d)),
                ),
            ],
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        kartu,
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Warna.error),
                const SizedBox(width: 6),
                Text('Tenggat', style: t.bodySmall),
              ],
            ),
            if (tugas.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Warna.primary),
                  const SizedBox(width: 6),
                  Text('Tugas pribadi', style: t.bodySmall),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Sel extends StatelessWidget {
  const _Sel({
    required this.hari,
    required this.hariIni,
    required this.tenggat,
    required this.tugas,
    required this.onTap,
  });

  final int hari;
  final bool hariIni;
  final bool tenggat;
  final bool tugas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hariIni ? Warna.primary : null,
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
                  fontWeight: tenggat || hariIni
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              if (tenggat && !hariIni)
                Positioned(
                  bottom: -1,
                  child: Icon(Icons.circle, size: 6, color: Warna.error),
                ),
              if (tugas && !tenggat)
                Positioned(
                  bottom: -1,
                  child: Icon(Icons.circle, size: 6, color: Warna.primary),
                ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Material(
        color: Warna.kartu,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Jari.kartu),
          side: BorderSide(color: Warna.container4),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onBuka,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: acara.tenggat
              ? Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Warna.errorSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: Warna.error,
                  ),
                )
              : Checkbox(
                  value: acara.selesai,
                  onChanged: (v) => onSelesai?.call(v ?? false),
                ),
          title: Text(
            acara.judul,
            style: t.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              decoration: acara.selesai ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            acara.tenggat ? 'Tenggat pendaftaran' : 'Tugas pribadi',
            style: t.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: acara.tenggat ? Warna.error : Warna.muted,
            ),
          ),
          trailing: onHapus == null
              ? null
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                  Lencana('${data.jumlahSelesai}/$total siap'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final b in data.berkas) ...[
              InkWell(
                borderRadius: BorderRadius.circular(Jari.kartuDalam),
                onTap: () => onCentang(b, !b.selesai),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Warna.kartu,
                    border: Border.all(color: Warna.container4),
                    borderRadius: BorderRadius.circular(Jari.kartuDalam),
                  ),
                  child: Row(
                    children: [
                      b.selesai
                          ? Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Warna.sukses,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Warna.putih,
                              ),
                            )
                          : Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Warna.outline,
                                  width: 1.5,
                                ),
                              ),
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          b.namaBerkas,
                          style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}
