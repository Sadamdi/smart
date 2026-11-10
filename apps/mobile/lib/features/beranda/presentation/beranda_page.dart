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
            _Hero(
              nama: p?.namaDepan ?? 'Mahasiswa',
              info: p != null && (p.jenjang ?? '').isNotEmpty
                  ? [
                      if (p.semester != null) 'Semester ${p.semester}',
                      p.jenjang!,
                      if ((p.ipk ?? '').isNotEmpty) 'IPK ${p.ipk}',
                    ].join(' · ')
                  : null,
              terisi: kel?.terisi ?? 0,
              total: kel?.total ?? 0,
              onLengkapi: () => context.go('/profil'),
              ringkasan: ringkasan.when(
                loading: () => const SizedBox(
                  height: 64,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pesanGalat(e),
                          style: t.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            ref.invalidate(ringkasanRekomendasiProvider),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
                data: (r) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Angka(
                      '${r.memenuhi}',
                      'Memenuhi',
                      const Color(0xFF7BE0A4),
                    ),
                    _Pemisah(),
                    _Angka(
                      '${r.hampirMemenuhi}',
                      'Hampir memenuhi',
                      const Color(0xFFFFD27A),
                    ),
                    _Pemisah(),
                    _Angka(
                      '${r.belumMemenuhi}',
                      'Belum memenuhi',
                      Colors.white70,
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.nama,
    required this.info,
    required this.terisi,
    required this.total,
    required this.onLengkapi,
    required this.ringkasan,
  });

  final String nama;
  final String? info;
  final int terisi;
  final int total;
  final VoidCallback onLengkapi;
  final Widget ringkasan;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lengkap = total > 0 && terisi == total;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6FC0), Color(0xFF143F7C)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (info != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(Jari.bulat),
              ),
              child: Text(
                info!,
                style: t.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
          Text(
            'Halo, $nama',
            style: t.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Lihat beasiswa yang paling sesuai dengan profilmu dan tenggat yang perlu dikejar.',
            style: t.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          ringkasan,
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelengkapan Profil',
                        style: t.labelLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Jari.bulat),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : terisi / total,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFFF5B73B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$terisi dari $total data utama terisi',
                        style: t.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: onLengkapi,
                  child: Text(lengkap ? 'Lihat' : 'Lengkapi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka(this.angka, this.label, this.warna);

  final String angka;
  final String label;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            angka,
            style: t.headlineMedium?.copyWith(color: warna, fontSize: 32),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 40,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: t.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pemisah extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: Colors.white.withValues(alpha: 0.2),
  );
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
        color: Warna.kartu,
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
            color: Warna.kartu,
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
