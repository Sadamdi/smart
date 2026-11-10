import 'package:flutter/material.dart';

import '../../features/beasiswa/domain/beasiswa.dart';
import '../../features/rekomendasi/domain/rekomendasi.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import 'chips.dart';

/// Kartu beasiswa untuk Jelajah, Rekomendasi, dan Beranda.
/// Memuat nama, penyelenggara, tenggat, dan bila dari mesin rekomendasi:
/// kategori beserta alasan dan catatan kekurangan. Tanpa persen kecocokan.
class KartuBeasiswa extends StatelessWidget {
  const KartuBeasiswa({
    super.key,
    required this.beasiswa,
    this.kategori,
    this.alasan = const [],
    this.catatan = const [],
    this.tersimpan,
    this.onSimpan,
    required this.onBuka,
    this.labelAksi = 'Lihat detail',
    this.sekarang,
  });

  final BeasiswaRingkas beasiswa;
  final Kategori? kategori;
  final List<String> alasan;
  final List<String> catatan;
  final bool? tersimpan;
  final VoidCallback? onSimpan;
  final VoidCallback onBuka;
  final String labelAksi;
  final DateTime? sekarang;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tenggat = beasiswa.tenggat;
    final sisa = tenggat == null ? null : sisaHari(tenggat, sekarang: sekarang);
    final meta = [
      if ((beasiswa.penyelenggara ?? '').isNotEmpty) beasiswa.penyelenggara!,
      if ((beasiswa.negara ?? '').isNotEmpty) beasiswa.negara!,
    ].join(' · ');

    return Container(
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Warna.container4),
        boxShadow: bayanganKartu,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Warna.container3,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _inisial(beasiswa.penyelenggara ?? beasiswa.nama),
                        style: t.titleMedium?.copyWith(color: Warna.primary),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (meta.isNotEmpty)
                            Text(
                              meta.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.labelSmall,
                            ),
                          const SizedBox(height: 4),
                          Text(beasiswa.nama, style: t.titleMedium),
                        ],
                      ),
                    ),
                    if (onSimpan != null)
                      IconButton(
                        tooltip: tersimpan == true
                            ? 'Hapus dari tersimpan'
                            : 'Simpan beasiswa',
                        onPressed: onSimpan,
                        icon: Icon(
                          tersimpan == true
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Warna.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (kategori != null) ChipStatus.kategori(kategori!),
                    if ((beasiswa.jenjang ?? '').isNotEmpty)
                      ChipStatus(label: beasiswa.jenjang!),
                    if (tenggat != null)
                      ChipStatus.tenggat(
                        sisa! < 0
                            ? 'Sudah lewat'
                            : '${teksSisaHari(tenggat, sekarang: sekarang)} (${tenggat.day} ${bulanPendek(tenggat.month)})',
                        dekat: sisa <= 7,
                      )
                    else
                      ChipStatus.tenggat(
                        'Tenggat belum diumumkan',
                        dekat: false,
                      ),
                  ],
                ),
                if (alasan.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Daftar(
                    judul: 'Alasan',
                    isi: alasan,
                    ikon: Icons.check_circle_outline,
                    warna: Warna.sukses,
                  ),
                ],
                if (catatan.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Daftar(
                    judul: 'Catatan kekurangan',
                    isi: catatan,
                    ikon: Icons.info_outline,
                    warna: Warna.primary,
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    backgroundColor: Warna.container3,
                    foregroundColor: Warna.primary,
                  ),
                  onPressed: onBuka,
                  child: Text(labelAksi),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _inisial(String s) {
  final h = s.trim();
  return h.isEmpty ? '?' : h.characters.first.toUpperCase();
}

class _Daftar extends StatelessWidget {
  const _Daftar({
    required this.judul,
    required this.isi,
    required this.ikon,
    required this.warna,
  });

  final String judul;
  final List<String> isi;
  final IconData ikon;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.container1,
        borderRadius: BorderRadius.circular(Jari.kartuDalam),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: t.titleSmall),
          const SizedBox(height: 6),
          for (final s in isi)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(ikon, size: 16, color: warna),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s, style: t.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
