import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Warna cincin menurut kategori kelayakan: hijau memenuhi, emas hampir, merah belum.
Color warnaKategoriSkor(String? kode) {
  switch (kode) {
    case 'memenuhi':
      return Warna.sukses;
    case 'hampir_memenuhi':
      return const Color(0xFFE0A21B);
    case 'belum_memenuhi':
      return Warna.error;
    default:
      return Warna.primarySoft;
  }
}

/// Cincin skor kelayakan: busur terisi sebesar skor dari atas searah jarum jam dan angka di tengah.
/// Skor null (belum ada syarat terukur) menampilkan lintasan kosong dengan tanda hubung, tanpa angka.
/// Skor kelayakan adalah seberapa banyak syarat terukur terpenuhi, bukan peluang diterima.
class CincinSkor extends StatelessWidget {
  const CincinSkor({
    super.key,
    required this.skor,
    required this.warna,
    this.ukuran = 56,
    this.tebal = 6,
  });

  final int? skor;
  final Color warna;
  final double ukuran;
  final double tebal;

  @override
  Widget build(BuildContext context) {
    final diam = MediaQuery.of(context).disableAnimations;
    final tujuan = (skor ?? 0) / 100;
    return Semantics(
      label: skor == null
          ? 'Skor kelayakan belum tersedia'
          : 'Skor kelayakan $skor persen',
      child: ExcludeSemantics(
        child: SizedBox(
          width: ukuran,
          height: ukuran,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: diam ? tujuan : 0, end: tujuan),
            duration: diam ? Duration.zero : const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => CustomPaint(
              painter: _PainterCincin(v, warna, tebal, Warna.container4),
              child: Center(
                child: skor == null
                    ? Text(
                        '-',
                        style: TextStyle(
                          fontSize: ukuran * 0.34,
                          fontWeight: FontWeight.w700,
                          color: Warna.muted,
                          height: 1,
                        ),
                      )
                    : Text.rich(
                        TextSpan(
                          text: '${(v * 100).round()}',
                          style: TextStyle(
                            fontSize: ukuran * 0.3,
                            fontWeight: FontWeight.w800,
                            color: Warna.navy,
                            height: 1,
                          ),
                          children: [
                            TextSpan(
                              text: '%',
                              style: TextStyle(
                                fontSize: ukuran * 0.16,
                                fontWeight: FontWeight.w700,
                                color: Warna.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PainterCincin extends CustomPainter {
  _PainterCincin(this.nilai, this.warna, this.tebal, this.lintasan);

  final double nilai;
  final Color warna;
  final double tebal;
  final Color lintasan;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(tebal / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tebal
        ..color = lintasan,
    );
    if (nilai > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        math.pi * 2 * nilai.clamp(0.0, 0.999),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tebal
          ..strokeCap = StrokeCap.round
          ..color = warna,
      );
    }
  }

  @override
  bool shouldRepaint(_PainterCincin old) =>
      old.nilai != nilai || old.warna != warna || old.lintasan != lintasan;
}

/// Titik-titik syarat: satu titik per syarat, terisi sebanyak yang terpenuhi.
class TitikSyarat extends StatelessWidget {
  const TitikSyarat({
    super.key,
    required this.terpenuhi,
    required this.total,
    required this.warna,
  });

  final int terpenuhi;
  final int total;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final tampil = math.min(total, 10);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tampil; i++)
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < terpenuhi ? warna : Warna.container4,
            ),
          ),
      ],
    );
  }
}

/// Tab pil Dalam negeri dan Luar negeri. Jumlah ditampilkan bila diketahui.
class TabWilayah extends StatelessWidget {
  const TabWilayah({
    super.key,
    required this.nilai,
    required this.onPilih,
    this.jumlahDalam,
    this.jumlahLuar,
  });

  /// 'dalam' atau 'luar'.
  final String nilai;
  final ValueChanged<String> onPilih;
  final int? jumlahDalam;
  final int? jumlahLuar;

  @override
  Widget build(BuildContext context) {
    Widget pil(String kode, String label, int? n) {
      final aktif = nilai == kode;
      return Expanded(
        child: Semantics(
          button: true,
          selected: aktif,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onPilih(kode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: aktif ? Warna.navy : Warna.kartu,
                border: aktif
                    ? null
                    : Border.all(color: Warna.container4, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                n == null ? label : '$label ($n)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: aktif ? Warna.surface : Warna.primary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pil('dalam', 'Dalam negeri', jumlahDalam),
        const SizedBox(width: 10),
        pil('luar', 'Luar negeri', jumlahLuar),
      ],
    );
  }
}
