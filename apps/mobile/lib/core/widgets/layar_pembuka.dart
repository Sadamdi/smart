import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'logo_smart.dart';

/// Animasi pembuka: logo muncul membesar, nama aplikasi naik, lalu seluruh
/// layar memudar dan menampakkan aplikasi. Hanya visual, tidak menahan sentuhan.
class LayarPembuka extends StatefulWidget {
  const LayarPembuka({super.key, required this.child, this.aktif = true});

  final Widget child;
  final bool aktif;

  @override
  State<LayarPembuka> createState() => _LayarPembukaState();
}

class _LayarPembukaState extends State<LayarPembuka>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
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
    final t = Theme.of(context).textTheme;
    final logo = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.35, curve: Curves.easeOutBack),
    );
    final teks = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
    );
    final pudar = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.8, 1, curve: Curves.easeIn),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Opacity(
              opacity: 1 - pudar.value,
              child: ColoredBox(
                color: Warna.surface,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: logo.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.6 + 0.4 * logo.value,
                          child: const LogoSmart(ukuran: 96),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: teks.value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - teks.value)),
                          child: Column(
                            children: [
                              Text(
                                'SMART',
                                style: t.headlineMedium?.copyWith(
                                  letterSpacing: 2,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Beasiswa yang tepat untukmu',
                                style: t.bodySmall?.copyWith(
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
