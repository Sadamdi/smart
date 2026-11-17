import 'package:flutter/material.dart';

import '../../features/beasiswa/domain/beasiswa.dart';
import '../../features/rekomendasi/domain/rekomendasi.dart';
import '../format.dart';
import '../theme/app_theme.dart';
import 'chips.dart';
import 'cincin_skor.dart';

/// Kartu beasiswa untuk Jelajah, Rekomendasi, dan Beranda.
/// Memuat nama, penyelenggara, tenggat, dan bila dari mesin rekomendasi:
/// skor kelayakan (cincin), kategori, dan jumlah syarat terpenuhi. Skor kelayakan bukan peluang diterima.
class KartuBeasiswa extends StatelessWidget {
  const KartuBeasiswa({
    super.key,
    required this.beasiswa,
    this.kategori,
    this.alasan = const [],
    this.catatan = const [],
    this.kelayakan,
    this.tersimpan,
    this.onSimpan,
    required this.onBuka,
    this.sekarang,
  });

  final BeasiswaRingkas beasiswa;
  final Kategori? kategori;
  final List<String> alasan;
  final List<String> catatan;

  /// Penilaian untuk kartu; bila null dipakai milik [beasiswa] (Jelajah), dan bila itu juga null tampil ikon bintang.
  final Kelayakan? kelayakan;
  final bool? tersimpan;
  final VoidCallback? onSimpan;
  final VoidCallback onBuka;
  final DateTime? sekarang;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final kel = kelayakan ?? beasiswa.kelayakan;
    final kat =
        kategori ??
        (kel?.kategori == null ? null : Kategori.dari(kel!.kategori!));
    final warnaSkor = warnaKategoriSkor(kat?.kode);
    final tenggat = beasiswa.tenggat;
    final sisa = tenggat == null ? null : sisaHari(tenggat, sekarang: sekarang);
    final dekat = sisa != null && sisa >= 0 && sisa <= 7;
    final teksTenggat = tenggat == null
        ? 'Tenggat belum diumumkan'
        : sisa! < 0
        ? 'Tenggat sudah lewat'
        : sisa == 0
        ? 'Tenggat hari ini'
        : 'Tenggat $sisa hari lagi';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(Jari.kartu),
          onTap: onBuka,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Warna.kartu,
              borderRadius: BorderRadius.circular(Jari.kartu),
              border: Border.all(color: Warna.container4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (kel != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CincinSkor(skor: kel.peluang, warna: warnaSkor),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Warna.container2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.star_border_rounded,
                          size: 26,
                          color: Warna.primary,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            beasiswa.nama,
                            style: t.titleMedium?.copyWith(
                              fontSize: 15,
                              height: 1.25,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((beasiswa.penyelenggara ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              beasiswa.penyelenggara!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onSimpan != null)
                      Semantics(
                        label: tersimpan == true
                            ? 'Hapus dari tersimpan'
                            : 'Simpan beasiswa',
                        button: true,
                        child: Tooltip(
                          message: tersimpan == true
                              ? 'Hapus dari tersimpan'
                              : 'Simpan beasiswa',
                          child: InkResponse(
                            onTap: onSimpan,
                            radius: 24,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                tersimpan == true
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                size: 26,
                                color: tersimpan == true
                                    ? Warna.primary
                                    : Warna.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if ((beasiswa.jenjang ?? '').isNotEmpty)
                      Lencana(beasiswa.jenjang!),
                    if (kat != null) Lencana.kategori(kat),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dekat ? Warna.error : Warna.primarySoft,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        teksTenggat,
                        style: t.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: dekat ? Warna.error : Warna.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (kel != null) ...[
                  const SizedBox(height: 10),
                  if (kel.adaSyarat)
                    Row(
                      children: [
                        TitikSyarat(
                          terpenuhi: kel.terpenuhi,
                          total: kel.total,
                          warna: warnaSkor,
                        ),
                        Flexible(
                          child: Text(
                            'Syarat terpenuhi ${kel.terpenuhi} dari ${kel.total}',
                            style: t.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Syarat belum tercatat, cek laman resmi',
                      style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                ] else
                  for (final s in [...alasan, ...catatan]) ...[
                    const SizedBox(height: 8),
                    Text(s, style: t.bodySmall, maxLines: 3),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
