import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Keluarga ilustrasi bergerak SMART, sebangun dengan logo Toga Lipat dan palet biru-emas:
/// [JamPasir] untuk memuat satu halaman penuh atau menunggu server, [Gulungan] untuk pengumuman
/// kosong, [LembarTerakhir] untuk kalender tanpa tenggat. Semuanya berulang pelan dan berhenti
/// pada gambar akhir bila pengguna mematikan animasi sistem.
const _navy = Color(0xFF143F7C);
const _muda = Color(0xFFBCD2F1);
const _emas = Color(0xFFF5B73B);
const _latar = Color(0xFFEAF1FF);

double _t(double v, double dari, double sampai, [Curve k = Curves.linear]) =>
    k.transform(((v - dari) / (sampai - dari)).clamp(0.0, 1.0));

class _Gerak extends StatefulWidget {
  const _Gerak({
    required this.ukuran,
    required this.durasi,
    required this.painter,
    required this.label,
    required this.diam,
  });

  final double ukuran;
  final Duration durasi;
  final CustomPainter Function(double t) painter;
  final String label;

  /// Nilai t yang dipakai saat animasi dimatikan (gambar yang paling bermakna).
  final double diam;

  @override
  State<_Gerak> createState() => _GerakState();
}

class _GerakState extends State<_Gerak> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.durasi,
  );
  bool _mulai = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mati = MediaQuery.of(context).disableAnimations;
    if (!mati && !_mulai) {
      _mulai = true;
      _c.repeat();
    } else if (mati && _mulai) {
      _mulai = false;
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      child: ExcludeSemantics(
        child: SizedBox(
          width: widget.ukuran,
          height: widget.ukuran,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: widget.painter(_mulai ? _c.value : widget.diam),
            ),
          ),
        ),
      ),
    );
  }
}

Path _bintang(double cx, double cy, double s) {
  const p = <Offset>[
    Offset(0, -9),
    Offset(2.1, -2.9),
    Offset(8.6, -2.8),
    Offset(3.4, 1.1),
    Offset(5.3, 7.3),
    Offset(0, 3.6),
    Offset(-5.3, 7.3),
    Offset(-3.4, 1.1),
    Offset(-8.6, -2.8),
    Offset(-2.1, -2.9),
  ];
  return Path()..addPolygon([
    for (final o in p) Offset(cx + o.dx * s, cy + o.dy * s),
  ], true);
}

/// Jam pasir: butir emas turun, jam dibalik, lalu mengulang tanpa lompatan.
class JamPasir extends StatelessWidget {
  const JamPasir({super.key, this.ukuran = 72});

  final double ukuran;

  @override
  Widget build(BuildContext context) => _Gerak(
    ukuran: ukuran,
    durasi: const Duration(milliseconds: 4200),
    painter: _PainterJamPasir.new,
    label: 'Memuat',
    diam: 0.3,
  );
}

class _PainterJamPasir extends CustomPainter {
  _PainterJamPasir(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);
    final p = _t(t, 0, 0.72);
    final putar = _t(t, 0.78, 0.96, Curves.easeInOutCubic) * math.pi;
    canvas.translate(60, 60);
    canvas.rotate(putar);
    canvas.translate(-60, -60);

    final pasir = Paint()..color = _emas;
    // Pasir atas menyusut ke arah leher, pasir bawah menumpuk dari dasar.
    canvas.save();
    canvas.translate(0, 48);
    canvas.scale(1, 1 - p);
    canvas.translate(0, -48);
    canvas.drawPath(
      Path()..addPolygon(const [
        Offset(40, 25),
        Offset(80, 25),
        Offset(66, 48),
        Offset(54, 48),
      ], true),
      pasir,
    );
    canvas.restore();
    canvas.save();
    canvas.translate(0, 95);
    canvas.scale(1, p);
    canvas.translate(0, -95);
    canvas.drawPath(
      Path()..addPolygon(const [
        Offset(40, 95),
        Offset(80, 95),
        Offset(66, 72),
        Offset(54, 72),
      ], true),
      pasir,
    );
    canvas.restore();
    if (t > 0.03 && t < 0.72) {
      canvas.drawLine(
        const Offset(60, 50),
        const Offset(60, 94),
        Paint()
          ..color = _emas
          ..strokeWidth = 2,
      );
    }

    final kaca = Path()
      ..moveTo(36, 22)
      ..lineTo(84, 22)
      ..lineTo(64, 60)
      ..lineTo(84, 98)
      ..lineTo(36, 98)
      ..lineTo(56, 60)
      ..close();
    canvas.drawPath(kaca, Paint()..color = Warna.navy.withValues(alpha: 0.07));
    canvas.drawPath(
      kaca,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeJoin = StrokeJoin.round
        ..color = Warna.navy,
    );
    final tutup = Paint()..color = Warna.navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 14, 60, 8),
        const Radius.circular(2),
      ),
      tutup,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 98, 60, 8),
        const Radius.circular(2),
      ),
      tutup,
    );
  }

  @override
  bool shouldRepaint(_PainterJamPasir old) => old.t != t;
}

/// Gulungan: naskah dibentang lalu dicap segel emas. Untuk keadaan pengumuman kosong.
class Gulungan extends StatelessWidget {
  const Gulungan({super.key, this.ukuran = 96});

  final double ukuran;

  @override
  Widget build(BuildContext context) => _Gerak(
    ukuran: ukuran,
    durasi: const Duration(milliseconds: 4800),
    painter: _PainterGulungan.new,
    label: 'Belum ada pengumuman',
    diam: 0.7,
  );
}

class _PainterGulungan extends CustomPainter {
  _PainterGulungan(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);
    final buka =
        _t(t, 0.06, 0.38, Curves.easeOutCubic) *
        (1 - _t(t, 0.9, 1, Curves.easeIn));
    final geser = 28 * (1 - buka);

    canvas.save();
    canvas.translate(60, 0);
    canvas.scale(buka, 1);
    canvas.translate(-60, 0);
    if (buka > 0.01) {
      const kertas = Rect.fromLTWH(32, 34, 56, 52);
      canvas.drawRect(kertas, Paint()..color = Colors.white);
      canvas.drawRect(
        kertas,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = _navy,
      );
      final garis = Paint()
        ..color = _muda
        ..strokeWidth = 4;
      canvas.drawLine(const Offset(40, 46), const Offset(80, 46), garis);
      canvas.drawLine(const Offset(40, 55), const Offset(80, 55), garis);
      canvas.drawLine(const Offset(40, 64), const Offset(64, 64), garis);
    }
    canvas.restore();

    final gulung = Paint()..color = _navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(20 + geser, 28, 12, 64),
        const Radius.circular(6),
      ),
      gulung,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(88 - geser, 28, 12, 64),
        const Radius.circular(6),
      ),
      gulung,
    );

    // Segel jatuh dan memantul sebentar.
    final turun = _t(t, 0.40, 0.58, Curves.easeOutBack);
    final ada = _t(t, 0.40, 0.46) * (1 - _t(t, 0.9, 1));
    if (ada > 0) {
      canvas.save();
      canvas.translate(60, 76 - 34 * (1 - turun));
      canvas.scale(1 + 0.8 * (1 - turun));
      canvas.drawCircle(
        Offset.zero,
        11,
        Paint()..color = _emas.withValues(alpha: ada),
      );
      canvas.drawPath(
        _bintang(0, 0, 0.8),
        Paint()..color = _navy.withValues(alpha: ada),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PainterGulungan old) => old.t != t;
}

/// Lembar terakhir: lembar kalender terlepas dan di baliknya muncul bintang emas.
class LembarTerakhir extends StatelessWidget {
  const LembarTerakhir({super.key, this.ukuran = 96});

  final double ukuran;

  @override
  Widget build(BuildContext context) => _Gerak(
    ukuran: ukuran,
    durasi: const Duration(milliseconds: 4800),
    painter: _PainterLembar.new,
    label: 'Tidak ada tenggat',
    diam: 0.7,
  );
}

class _PainterLembar extends CustomPainter {
  _PainterLembar(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120);
    final kepala = Path()
      ..moveTo(22, 44)
      ..lineTo(22, 28)
      ..arcToPoint(const Offset(28, 22), radius: const Radius.circular(6))
      ..lineTo(92, 22)
      ..arcToPoint(const Offset(98, 28), radius: const Radius.circular(6))
      ..lineTo(98, 44)
      ..close();
    canvas.drawPath(kepala, Paint()..color = _navy);
    canvas.drawCircle(const Offset(42, 22), 4, Paint()..color = _muda);
    canvas.drawCircle(const Offset(78, 22), 4, Paint()..color = _muda);

    const badan = Rect.fromLTWH(22, 44, 76, 58);
    final garis = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _navy;
    canvas.drawRect(badan, Paint()..color = _latar);
    canvas.drawRect(badan, garis);

    final pop = _t(t, 0.40, 0.64, Curves.easeOutBack) * (1 - _t(t, 0.9, 1));
    if (pop > 0) {
      canvas.drawPath(
        _bintang(60, 76, 2.4 * pop.clamp(0.0, 1.4)),
        Paint()..color = _emas,
      );
    }

    // Lembar depan terlepas ke atas (menyusut ke garis engselnya), lalu kembali di akhir putaran.
    final lepas = _t(t, 0.30, 0.48, Curves.easeInOutCubic);
    final kembali = _t(t, 0.92, 1, Curves.easeOut);
    final sk = lepas < 1 ? 1 - lepas : kembali;
    if (sk > 0.01) {
      canvas.save();
      canvas.translate(0, 44);
      canvas.scale(1, sk);
      canvas.translate(0, -44);
      canvas.drawRect(badan, Paint()..color = Colors.white);
      canvas.drawRect(badan, garis);
      final isi = Paint()
        ..color = _muda
        ..strokeWidth = 4;
      canvas.drawLine(const Offset(34, 62), const Offset(86, 62), isi);
      canvas.drawLine(const Offset(34, 74), const Offset(86, 74), isi);
      canvas.drawLine(const Offset(34, 86), const Offset(64, 86), isi);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PainterLembar old) => old.t != t;
}

/// Halaman penuh yang sedang memuat: jam pasir di tengah dengan keterangan singkat.
class MemuatHalaman extends StatelessWidget {
  const MemuatHalaman({super.key, this.pesan = 'Memuat'});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const JamPasir(ukuran: 76),
          const SizedBox(height: 14),
          Text(
            pesan,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Warna.muted, decoration: TextDecoration.none),
          ),
        ],
      ),
    );
  }
}
