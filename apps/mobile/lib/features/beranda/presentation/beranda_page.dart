import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/kartu_beasiswa.dart';
import '../../../core/widgets/metrik_dan_progres.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../kalender/domain/kalender.dart';
import '../../beasiswa/presentation/simpan_aksi.dart';
import '../../beasiswa/presentation/tersimpan_controller.dart';
import 'beranda_controller.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final _c = Get.find<BerandaController>();
  final _simpan = Get.find<TersimpanController>();

  @override
  void initState() {
    super.initState();
    _c.buka();
    _simpan.idTersimpan.pastikan();
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = Get.find<AuthController>().pengguna;
    final kel = p?.kelengkapan;
    final ringkasan = _c.ringkasan.state.value;
    final utama = _c.utama.state.value;
    final kalender = _c.acara.state.value;
    final segarkan = _c.segarkan;

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
                        onPressed: () => _c.ringkasan.muat(),
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
                      Warna.heroTeks,
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
                  cobaLagi: () => _c.utama.muat(),
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
                  tersimpan: _simpan.ids.contains(r.beasiswa.id),
                  onSimpan: () => ubahSimpan(
                    context,
                    r.beasiswa.id,
                    tersimpan: _simpan.ids.contains(r.beasiswa.id),
                  ),
                  onBuka: () => context.push('/beasiswa/${r.beasiswa.id}'),
                );
              },
            ),
            const SizedBox(height: 20),
            const JudulBagian('Tenggat Terdekat'),
            const SizedBox(height: 8),
            kalender.when(
              loading: () => const SizedBox(height: 100, child: MemuatState()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: GalatState(
                  pesan: pesanGalat(e),
                  cobaLagi: () => _c.acara.muat(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.hero,
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
                style: t.labelMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Text(
            'Halo, $nama',
            style: t.headlineMedium?.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Lihat beasiswa yang paling sesuai dengan profilmu dan tenggat yang perlu dikejar.',
            style: t.bodyMedium?.copyWith(
              color: Warna.heroTeks,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ringkasan,
          const SizedBox(height: 12),
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
                        style: t.labelLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
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
                        style: t.bodySmall?.copyWith(
                          color: Warna.heroTeks,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: t.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
            style: t.headlineMedium?.copyWith(color: warna, fontSize: 30),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 40,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: t.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
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
    final warna = dekat ? Warna.error : Warna.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        border: Border.all(color: Warna.container4),
        boxShadow: bayanganKartu,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: dekat ? Warna.errorSoft : Warna.container3,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_today_outlined, size: 20, color: warna),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acara.judul,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  sisa == 0 ? 'Tenggat hari ini' : 'Tenggat $sisa hari lagi',
                  style: t.bodySmall?.copyWith(
                    color: dekat ? Warna.error : Warna.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
