import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Logo SMART: huruf S dengan bintang pemandu (SVG di assets/logo.svg).
class LogoSmart extends StatelessWidget {
  const LogoSmart({super.key, this.ukuran = 40});

  final double ukuran;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo.svg',
      width: ukuran,
      height: ukuran,
      semanticsLabel: 'SMART',
    );
  }
}
