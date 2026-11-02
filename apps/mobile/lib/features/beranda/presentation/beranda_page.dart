import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/kartu_beasiswa.dart';
import '../../../core/widgets/metrik_dan_progres.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../kalender/domain/kalender.dart';
import '../../kalender/presentation/kalender_providers.dart';
import '../../rekomendasi/domain/rekomendasi.dart';
import '../../rekomendasi/presentation/rekomendasi_providers.dart';

class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = ref.watch(authControllerProvider).pengguna;
    final kel = p?.kelengkapan;
    final ringkasan = ref.watch(ringkasanRekomendasiProvider);
    final utama = ref.watch(rekomendasiProvider(Kategori.memenuhi));
    final kalender = ref.watch(kalenderProvider);

    Future<void> segarkan() async {
      ref.invalidate(ringkasanRekomendasiProvider);
      ref.invalidate(rekomendasiProvider);
      ref.invalidate(kalenderProvider);
    }

    return Scaffold(
      appBar: const SmartAppBar(),
      body: RefreshIndicator(
        onRefresh: segarkan,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (p != null && (p.jenjang ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ChipStatus(
                    label: [
                      if (p.semester != null) 'Semester ${p.semester}',
                      p.jenjang!,
                      if ((p.ipk ?? '').isNotEmpty) 'IPK ${p.ipk}',
                    ].join(' · '),
                  ),
                ),
              ),
            Text(
              'Halo, ${p?.namaDepan ?? 'Mahasiswa'}',
              style: t.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Lihat beasiswa yang paling sesuai dengan profilmu dan tenggat yang perlu dikejar.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (kel != null) _KartuProfil(terisi: kel.terisi, total: kel.total),
            const SizedBox(height: 20),
            const JudulBagian('Ringkasan Rekomendasi'),
            const SizedBox(height: 8),
            ringkasan.when(
              loading: () => const SizedBox(height: 120, child: MemuatState()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: () => ref.invalidate(ringkasanRekomendasiProvider),
                ),
              ),
              data: (r) => IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Metrik(
                        angka: '${r.memenuhi}',
                        label: 'Memenuhi',
                        keterangan: 'Semua syarat',
                        ikon: Icons.check_circle_outline,
                        warna: Warna.sukses,
                        latarIkon: Warna.suksesSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Metrik(
                        angka: '${r.hampirMemenuhi}',
                        label: 'Hampir memenuhi',
                        keterangan: 'Kurang sedikit',
                        ikon: Icons.timelapse,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Metrik(
                        angka: '${r.belumMemenuhi}',
                        label: 'Belum memenuhi',
                        keterangan: 'Syarat belum terpenuhi',
                        ikon: Icons.lock_outline,
                        warna: Warna.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            JudulBagian(
              'Pilihan Utama',
              aksi: 'Lihat semua',
              onAksi: () => context.go('/rekomendasi'),
            ),
            const SizedBox(height: 8),
            utama.when(
              loading: () => const SizedBox(height: 120, child: MemuatState()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: () =>
                      ref.invalidate(rekomendasiProvider(Kategori.memenuhi)),
                ),
              ),
              data: (daftar) {
                if (daftar.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: KosongState(
                      ikon: Icons.auto_awesome_outlined,
                      judul: 'Belum ada pilihan utama',
                      pesan: 'Lengkapi profil akademik agar Mesin Rekomendasi dapat menyusun pilihan untukmu.',
                      aksi: () => context.go('/profil'),
                      labelAksi: 'Lengkapi profil',
                    ),
                  );
                }
                final r = daftar.first;
                return KartuBeasiswa(
                  beasiswa: r.beasiswa,
                  kategori: r.kategori,
                  alasan: r.alasan,
                  catatan: r.catatanKekurangan,
                  labelAksi: 'Lihat detail dan syarat',
                  onBuka: () => context.push('/beasiswa/${r.beasiswa.id}'),
                );
              },
            ),
            const SizedBox(height: 20),
            JudulBagian(
              'Tenggat Terdekat',
              aksi: 'Lihat kalender',
              onAksi: () => context.go('/kalender'),
            ),
            const SizedBox(height: 8),
            kalender.when(
              loading: () => const SizedBox(height: 100, child: MemuatState()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: () => ref.invalidate(kalenderProvider),
                ),
              ),
              data: (acara) {
                final hariIni = DateTime.now();
                final dekat =
                    acara
                        .where(
                          (a) =>
                              a.tenggat &&
                              sisaHari(a.tanggal, sekarang: hariIni) >= 0,
                        )
                        .toList()
                      ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
                if (dekat.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Belum ada tenggat dalam waktu dekat. Simpan beasiswa agar tenggatnya muncul di sini.',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final a in dekat.take(3)) _BarisTenggat(acara: a),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const JudulBagian('Jalan Pintas'),
            const SizedBox(height: 8),
            Row(
              children: [
                _Pintas(
                  ikon: Icons.explore_outlined,
                  label: 'Jelajah',
                  onTap: () => context.go('/jelajah'),
                ),
                _Pintas(
                  ikon: Icons.auto_awesome_outlined,
                  label: 'Rekomendasi',
                  onTap: () => context.go('/rekomendasi'),
                ),
                _Pintas(
                  ikon: Icons.calendar_month_outlined,
                  label: 'Kalender',
                  onTap: () => context.go('/kalender'),
                ),
                _Pintas(
                  ikon: Icons.person_outline,
                  label: 'Profil',
                  onTap: () => context.go('/profil'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuProfil extends StatelessWidget {
  const _KartuProfil({required this.terisi, required this.total});

  final int terisi;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lengkap = terisi == total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.putih,
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: Warna.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Kelengkapan Profil', style: t.titleMedium)),
              TextButton(
                onPressed: () => context.go('/profil'),
                child: Text(lengkap ? 'Lihat' : 'Lengkapi'),
              ),
            ],
          ),
          Text(
            '$terisi dari $total data akademik terisi. Data yang lengkap membuat rekomendasi lebih tepat.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 10),
          BarProgres(nilai: terisi / total),
        ],
      ),
    );
  }
}

class _BarisTenggat extends StatelessWidget {
  const _BarisTenggat({required this.acara});

  final Acara acara;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sisa = sisaHari(acara.tanggal);
    final dekat = sisa <= 7;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.putih,
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: dekat ? Warna.errorSoft : Warna.container3,
              borderRadius: BorderRadius.circular(Jari.kartuDalam),
            ),
            child: Column(
              children: [
                Text(
                  bulanPendek(acara.tanggal.month).toUpperCase(),
                  style: t.labelSmall?.copyWith(
                    color: dekat ? Warna.error : Warna.muted,
                  ),
                ),
                Text(
                  '${acara.tanggal.day}',
                  style: t.titleLarge?.copyWith(
                    color: dekat ? Warna.error : Warna.navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(acara.judul, style: t.titleSmall),
                const SizedBox(height: 2),
                Text('Tenggat pendaftaran', style: t.bodySmall),
              ],
            ),
          ),
          ChipStatus.tenggat(
            sisa == 0 ? 'Hari ini' : '$sisa hari',
            dekat: dekat,
          ),
        ],
      ),
    );
  }
}

class _Pintas extends StatelessWidget {
  const _Pintas({required this.ikon, required this.label, required this.onTap});

  final IconData ikon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(Jari.kartu),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Warna.putih,
            borderRadius: BorderRadius.circular(Jari.kartu),
            boxShadow: bayanganKartu,
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Warna.container3,
                child: Icon(ikon, color: Warna.primary, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Warna.navy, letterSpacing: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
