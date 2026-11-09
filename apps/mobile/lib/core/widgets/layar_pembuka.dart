import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animasi pembuka, disusun dari potongan logo yang bergerak sendiri-sendiri: topi toga jatuh dan memantul,
/// alasnya naik, jumbai turun, bintang pemandu muncul, gelombang pantau merambat keluar, lalu huruf SMART
/// muncul satu per satu. Hanya visual, tidak menahan sentuhan.
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
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6FC0), Color(0xFF143F7C)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 160,
              child: CustomPaint(painter: _PainterLogo(ms)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _huruf.length; i++) _satuHuruf(i),
              ],
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: tag,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - tag)),
                child: Text(
                  'Beasiswa yang tepat untukmu',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    decoration: TextDecoration.none,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _satuHuruf(int i) {
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 5,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lambang tanpa latar kotak, dalam ruang gambar 64 x 64 yang sama dengan logo.svg.
class _PainterLogo extends CustomPainter {
  _PainterLogo(this.ms);

  final double ms;

  static const _emas = Color(0xFFF5B73B);

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width / 56, size.height / 44);
    // Lambang menempati x 7 sampai 62 dan y 13 sampai 55 pada kotak 64.
    canvas.translate(
      (size.width - 55 * k) / 2 - 7 * k,
      (size.height - 42 * k) / 2 - 13 * k,
    );
    canvas.scale(k);

    final topi = _tahap(ms, 0, 850, Curves.bounceOut);
    final topiMuncul = _tahap(ms, 0, 250, Curves.easeOut);
    final alas = _tahap(ms, 300, 750, Curves.easeOutCubic);
    final jumbai = _tahap(ms, 750, 1050, Curves.easeOut);
    final bintang = _tahap(ms, 1000, 1450, Curves.easeOutBack);

    // Alas topi.
    canvas.save();
    canvas.translate(0, 8 * (1 - alas));
    canvas.drawPath(
      Path()
        ..moveTo(18, 30.5)
        ..lineTo(32, 37)
        ..lineTo(46, 30.5)
        ..lineTo(46, 39.5)
        ..cubicTo(46, 43.5, 39.5, 47.5, 32, 47.5)
        ..cubicTo(24.5, 47.5, 18, 43.5, 18, 39.5)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.82 * alas),
    );
    canvas.restore();

    // Topi toga: jatuh dari atas lalu memantul.
    canvas.save();
    canvas.translate(0, -22 * (1 - topi));
    canvas.drawPath(
      Path()
        ..moveTo(32, 13)
        ..lineTo(57, 24.5)
        ..lineTo(32, 36)
        ..lineTo(7, 24.5)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: topiMuncul),
    );
    canvas.restore();

    // Jumbai turun dari ujung topi.
    if (jumbai > 0) {
      canvas.drawLine(
        const Offset(50, 27.6),
        Offset(50, 27.6 + 13.4 * jumbai),
        Paint()
          ..color = _emas
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // Bintang pemandu.
    if (bintang > 0) {
      canvas.save();
      canvas.translate(50, 46.1);
      canvas.rotate(-0.8 * (1 - bintang));
      canvas.scale(bintang.clamp(0.0, 1.4));
      canvas.translate(-50, -46.1);
      canvas.drawPath(
        Path()
          ..moveTo(50, 40.5)
          ..lineTo(51.7, 44.4)
          ..lineTo(55.6, 46.1)
          ..lineTo(51.7, 47.8)
          ..lineTo(50, 51.7)
          ..lineTo(48.3, 47.8)
          ..lineTo(44.4, 46.1)
          ..lineTo(48.3, 44.4)
          ..close(),
        Paint()..color = _emas,
      );
      canvas.restore();
    }

    // Gelombang pantau: merambat keluar dari bintang, berulang pelan.
    for (var i = 0; i < 2; i++) {
      final awal = 1400.0 + i * 260;
      final fase = ((ms - awal) / 900).clamp(0.0, 1.0);
      if (fase <= 0) continue;
      final r = (i == 0 ? 8.0 : 11.5) + 3 * fase;
      final alpha = math.sin(fase * math.pi) * (i == 0 ? 0.95 : 0.6);
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(50, 46.1), radius: r),
        -65 * math.pi / 180,
        50 * math.pi / 180,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.8
          ..color = _emas.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_PainterLogo old) => old.ms != ms;
}
