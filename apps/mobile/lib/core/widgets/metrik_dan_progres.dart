import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu angka: ikon, angka besar, label, keterangan.
class Metrik extends StatelessWidget {
  const Metrik({
    super.key,
    required this.angka,
    required this.label,
    this.keterangan,
    required this.ikon,
    this.warna,
    this.latarIkon,
  });

  final String angka;
  final String label;
  final String? keterangan;
  final IconData ikon;
  final Color? warna;
  final Color? latarIkon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: latarIkon ?? Warna.container2,
            child: Icon(ikon, size: 18, color: warna ?? Warna.primary),
          ),
          const SizedBox(height: 8),
          Text(angka, style: t.titleLarge?.copyWith(fontSize: 24)),
          Text(
            label,
            textAlign: TextAlign.center,
            style: t.labelSmall?.copyWith(
              color: warna ?? Warna.primary,
              letterSpacing: 0,
            ),
          ),
          if (keterangan != null)
            Text(
              keterangan!,
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(fontSize: 11),
            ),
        ],
      ),
    );
  }
}

/// Bar progres bulat dengan nilai 0 sampai 1.
class BarProgres extends StatelessWidget {
  const BarProgres({super.key, required this.nilai, this.tinggi = 6});

  final double nilai;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Jari.bulat),
      child: LinearProgressIndicator(
        value: nilai.clamp(0, 1).toDouble(),
        minHeight: tinggi,
        backgroundColor: Warna.container4,
        color: Warna.primary,
      ),
    );
  }
}

/// Judul bagian dengan tautan opsional di kanan.
class JudulBagian extends StatelessWidget {
  const JudulBagian(this.judul, {super.key, this.aksi, this.onAksi});

  final String judul;
  final String? aksi;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(judul, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (aksi != null)
          TextButton(
            onPressed: onAksi,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(48, 40),
            ),
            child: Text(aksi!),
          ),
      ],
    );
  }
}
