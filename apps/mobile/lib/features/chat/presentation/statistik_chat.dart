import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Lembar statistik chatbot: angka pemakaian, grafik 7 hari, asal jawaban, topik, dan beasiswa yang sering dirujuk.
/// Data sama untuk server dan ponsel (di ponsel dihitung dari riwayat lokal), jadi tampil juga saat luring.
Future<void> tampilkanStatistikChat(
  BuildContext context, {
  required Map<String, dynamic> awal,
  required Future<Map<String, dynamic>> Function() muat,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, kontrol) => _PemuatStatistik(awal, muat, kontrol),
    ),
  );
}

/// Lembar terbuka seketika dengan data ponsel; data server menggantikannya diam-diam bila tiba (gagal: data ponsel tetap).
class _PemuatStatistik extends StatefulWidget {
  const _PemuatStatistik(this.awal, this.muat, this.kontrol);

  final Map<String, dynamic> awal;
  final Future<Map<String, dynamic>> Function() muat;
  final ScrollController kontrol;

  @override
  State<_PemuatStatistik> createState() => _PemuatStatistikState();
}

class _PemuatStatistikState extends State<_PemuatStatistik> {
  late Map<String, dynamic> _d = widget.awal;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    widget
        .muat()
        .then((d) {
          if (mounted) setState(() => _d = d);
        })
        .catchError((Object _) {})
        .whenComplete(() {
          if (mounted) setState(() => _memuat = false);
        });
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_memuat) const LinearProgressIndicator(minHeight: 2),
      Expanded(child: _IsiStatistik(_d, widget.kontrol)),
    ],
  );
}

int _n(Object? x) => (x as num?)?.toInt() ?? 0;

String _ribu(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)} jt';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)} rb';
  return '$n';
}

class _IsiStatistik extends StatelessWidget {
  const _IsiStatistik(this.d, this.kontrol);

  final Map<String, dynamic> d;
  final ScrollController kontrol;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final jumlah = _n(d['jumlah']);
    final server = _n(d['dijawab_server']);
    final ponsel = _n(d['dijawab_ponsel']);
    final hari = [
      for (final x in (d['per_hari'] as List? ?? const [])) x as Map,
    ];
    final tertinggi = hari.fold<int>(
      1,
      (a, x) => _n(x['jumlah']) > a ? _n(x['jumlah']) : a,
    );
    final topik = [for (final x in (d['topik'] as List? ?? const [])) x as Map];
    final sesiStat = [
      for (final x in (d['per_sesi'] as List? ?? const [])) x as Map,
    ];
    final rujukan = [
      for (final x in (d['beasiswa_teratas'] as List? ?? const [])) x as Map,
    ];

    Widget kartu(String label, String nilai, IconData ikon) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Warna.kartu,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Warna.container4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ikon, size: 20, color: Warna.primary),
            const SizedBox(height: 8),
            Text(
              nilai,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(label, style: t.bodySmall),
          ],
        ),
      ),
    );

    Widget judul(String teks) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        teks,
        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    return ListView(
      controller: kontrol,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          'Statistik chatbot',
          style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Token adalah perkiraan (karakter dibagi 4), bukan tagihan.',
          style: t.bodySmall,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            kartu('Pertanyaan', '$jumlah', Icons.question_answer_outlined),
            const SizedBox(width: 10),
            kartu(
              'Percakapan',
              '${_n(d['jumlah_sesi'])}',
              Icons.forum_outlined,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            kartu(
              'Token masuk',
              _ribu(_n(d['token_masuk'])),
              Icons.south_west_rounded,
            ),
            const SizedBox(width: 10),
            kartu(
              'Token keluar',
              _ribu(_n(d['token_keluar'])),
              Icons.north_east_rounded,
            ),
          ],
        ),
        judul('7 hari terakhir'),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final x in hari)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${_n(x['jumlah'])}', style: t.labelSmall),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: _n(x['jumlah']) / tertinggi,
                          ),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => Container(
                            height: 6 + 50 * v,
                            decoration: BoxDecoration(
                              color: _n(x['jumlah']) == 0
                                  ? Warna.container4
                                  : Warna.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${x['tanggal']}'.split('-').last,
                          style: t.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        judul('Asal jawaban'),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (server > 0)
                  Expanded(
                    flex: server,
                    child: ColoredBox(color: Warna.primary),
                  ),
                if (ponsel > 0)
                  Expanded(
                    flex: ponsel,
                    child: const ColoredBox(color: Color(0xFFF2B33D)),
                  ),
                if (jumlah == 0)
                  Expanded(child: ColoredBox(color: Warna.container4)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text('Server $server  ·  Model di ponsel $ponsel', style: t.bodySmall),
        if (topik.isNotEmpty) ...[
          judul('Topik yang sering ditanyakan'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final x in topik)
                Chip(label: Text('${x['kata']}  ${x['jumlah']}')),
            ],
          ),
        ],
        if (sesiStat.isNotEmpty) ...[
          judul('Pemakaian per percakapan'),
          for (final x in sesiStat)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Warna.kartu,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Warna.container4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${x['judul']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_n(x['pertanyaan'])} pertanyaan',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'masuk ${_ribu(_n(x['token_masuk']))}  ·  keluar ${_ribu(_n(x['token_keluar']))}',
                    style: t.labelSmall,
                  ),
                ],
              ),
            ),
        ],
        if (rujukan.isNotEmpty) ...[
          judul('Paling sering dirujuk'),
          for (final b in rujukan)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${b['nama']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${b['jumlah']}x', style: t.labelLarge),
                ],
              ),
            ),
        ],
        if (jumlah == 0)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(
              'Belum ada percakapan. Statistik muncul setelah kamu bertanya.',
              style: t.bodyMedium,
            ),
          ),
      ],
    );
  }
}
