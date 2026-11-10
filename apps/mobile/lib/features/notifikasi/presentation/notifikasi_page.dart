import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';
import '../domain/notifikasi.dart';
import 'notifikasi_controller.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final _c = Get.find<NotifikasiController>();

  @override
  void initState() {
    super.initState();
    _c.daftar.muat();
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final nilai = _c.daftar.state.value;

    Future<void> aksi(Future<void> Function() f) async {
      final pesan = ScaffoldMessenger.of(context);
      try {
        await f();
      } catch (e) {
        pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (nilai.value?.any((n) => !n.dibaca) ?? false)
            TextButton(
              onPressed: () => aksi(_c.bacaSemua),
              child: const Text('Tandai semua dibaca'),
            ),
        ],
      ),
      body: AsyncIsi<List<Notifikasi>>(
        nilai: nilai,
        ulang: _c.daftar.muat,
        bangun: (daftar) {
          if (daftar.isEmpty) {
            return const KosongState(
              ikon: Icons.notifications_none,
              judul: 'Belum ada notifikasi',
              pesan: 'Pengingat tenggat beasiswa tersimpan dan beasiswa baru akan muncul di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: _c.daftar.muat,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: daftar.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final n = daftar[i];
                final tenggat = n.jenis == 'tenggat';
                return Material(
                  color: n.dibaca ? Warna.kartu : Warna.container2,
                  borderRadius: BorderRadius.circular(Jari.kartu),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Jari.kartu),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: tenggat
                          ? Warna.errorSoft
                          : Warna.container3,
                      child: Icon(
                        tenggat
                            ? Icons.timer_outlined
                            : Icons.new_releases_outlined,
                        color: tenggat ? Warna.error : Warna.primary,
                      ),
                    ),
                    title: Text(
                      n.judul,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      '${n.pesan}\n${formatTanggal(n.tanggalAcuan)}',
                    ),
                    isThreeLine: true,
                    trailing: n.dibaca
                        ? null
                        : Icon(Icons.circle, size: 10, color: Warna.primary),
                    onTap: () async {
                      final router = GoRouter.of(context);
                      if (!n.dibaca) await aksi(() => _c.baca(n.id));
                      router.push('/beasiswa/${n.beasiswaId}');
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
