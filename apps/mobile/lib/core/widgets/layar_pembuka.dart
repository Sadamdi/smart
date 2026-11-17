import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animasi pembuka Toga Lipat: alasnya turun, empat lipatan kertas membuka satu per satu menjadi topi toga,
/// jumbai emas berayun lalu diam, kemudian huruf SMART muncul satu per satu. Hanya visual, tidak menahan sentuhan.
class LayarPembuka extends StatefulWidget {
  const LayarPembuka({super.key, required this.child, this.aktif = true});

  final Widget child;
  final bool aktif;

  /// Seluruh urutan, termasuk memudar di akhir.
  static const totalMs = 3000;

  @override
  State<LayarPembuka> createState() => _LayarPembukaState();
}

class _LayarPembukaState extends State<LayarPembuka>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: LayarPembuka.totalMs),
  );
  bool _selesai = false;

  @override
  void initState() {
    super.initState();
    if (!widget.aktif) {
      _selesai = true;
      return;
    }
    _c.forward().whenComplete(() {
      if (mounted) setState(() => _selesai = true);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selesai || MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final ms = _c.value * LayarPembuka.totalMs;
              final pudar = _tahap(ms, 2650, 3000, Curves.easeIn);
              return Opacity(
                opacity: 1 - pudar,
                child: _IsiPembuka(ms: ms),
              );
            },
          ),
        ),
      ],
    );
  }
}

double _tahap(double ms, double dari, double sampai, Curve kurva) =>
    kurva.transform(((ms - dari) / (sampai - dari)).clamp(0.0, 1.0));

class _IsiPembuka extends StatelessWidget {
  const _IsiPembuka({required this.ms});

  final double ms;

  static const _huruf = ['S', 'M', 'A', 'R', 'T'];

  @override
  Widget build(BuildContext context) {
    final tag = _tahap(ms, 1900, 2500, Curves.easeOutCubic);
    return ColoredBox(
      color: Warna.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: CustomPaint(painter: _PainterLogo(ms)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _huruf.length; i++) _satuHuruf(context, i),
              ],
            ),
            const SizedBox(height: 6),
            Opacity(
              opacity: tag,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - tag)),
                child: Text(
                  'Beasiswa yang tepat untukmu',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: Warna.muted,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _satuHuruf(BuildContext context, int i) {
    final mulai = 1150.0 + i * 90;
    final v = _tahap(ms, mulai, mulai + 450, Curves.easeOutBack);
    final f = _tahap(ms, mulai, mulai + 220, Curves.easeOut);
    return Opacity(
      opacity: f,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - v)),
        child: Transform.scale(
          scale: 0.8 + 0.2 * v,
          child: Text(
            _huruf[i],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Warna.navy,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// Toga Lipat dalam ruang gambar 120 x 120 yang sama dengan logo.svg (kotak biru tua, empat lipatan, jumbai emas).
class _PainterLogo extends CustomPainter {
  _PainterLogo(this.ms);

  final double ms;

  static const _navy = Color(0xFF143F7C);
  static const _emas = Color(0xFFF5B73B);
  static const _alas = Color(0xFF7FA8E0);

  /// Empat lipatan: titik segitiga, warna, dan waktu mulai membuka (ms).
  static const _lipatan = <(List<Offset>, Color, double)>[
    ([Offset(60, 52), Offset(60, 22), Offset(14, 52)], Color(0xFFBCD2F1), 300),
    ([Offset(60, 52), Offset(60, 22), Offset(106, 52)], Color(0xFFFFFFFF), 420),
    ([Offset(60, 52), Offset(106, 52), Offset(60, 82)], Color(0xFF3E83D6), 540),
    ([Offset(60, 52), Offset(60, 82), Offset(14, 52)], _alas, 660),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width, size.height) / 120;
    canvas.scale(k);

    // Kotak biru tua tumbuh dari tengah.
    final kotak = _tahap(ms, 0, 350, Curves.easeOutBack);
    canvas.save();
    canvas.translate(60, 60);
    canvas.scale(kotak.clamp(0.0, 1.06));
    canvas.translate(-60, -60);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 120, 120),
        const Radius.circular(26),
      ),
      Paint()..color = _navy,
    );
    canvas.restore();

    canvas.translate(60, 60);
    canvas.scale(0.9);
    canvas.translate(-60, -57);

    // Alas topi turun.
    final alas = _tahap(ms, 100, 700, Curves.easeOut);
    if (alas > 0) {
      canvas.save();
      canvas.translate(0, -14 * (1 - alas));
      canvas.drawPath(
        Path()
          ..moveTo(36, 62)
          ..lineTo(36, 84)
          ..cubicTo(45, 92, 75, 92, 84, 84)
          ..lineTo(84, 62)
          ..lineTo(60, 74)
          ..close(),
        Paint()..color = _alas.withValues(alpha: alas),
      );
      canvas.restore();
    }

    // Lipatan membuka satu per satu dari titik tengah.
    for (final (titik, warna, mulai) in _lipatan) {
      final v = _tahap(ms, mulai, mulai + 700, Curves.easeOutBack);
      final a = _tahap(ms, mulai, mulai + 250, Curves.easeOut);
      if (a <= 0) continue;
      canvas.save();
      canvas.translate(60, 52);
      canvas.rotate(-0.7 * (1 - v));
      canvas.scale(v.clamp(0.0, 1.12));
      canvas.translate(-60, -52);
      canvas.drawPath(
        Path()..addPolygon(titik, true),
        Paint()..color = warna.withValues(alpha: a),
      );
      canvas.restore();
    }

    // Jumbai emas berayun lalu diam.
    final muncul = _tahap(ms, 900, 1200, Curves.easeOut);
    if (muncul > 0) {
      final s = ms - 1050;
      final sudut = s < 0
          ? -0.52
          : -0.52 * math.exp(-s / 500) * math.cos(s / 150);
      canvas.save();
      canvas.translate(106, 52);
      canvas.rotate(sudut);
      canvas.translate(-106, -52);
      final cat = Paint()..color = _emas.withValues(alpha: muncul);
      canvas.drawLine(
        const Offset(106, 52),
        const Offset(106, 78),
        cat
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawRect(
        const Rect.fromLTWH(101, 78, 10, 13),
        cat..style = PaintingStyle.fill,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PainterLogo old) => old.ms != ms;
}
