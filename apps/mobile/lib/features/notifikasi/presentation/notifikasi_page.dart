import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_widgets.dart';
import '../domain/notifikasi.dart';
import 'notifikasi_providers.dart';

class NotifikasiPage extends ConsumerWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nilai = ref.watch(notifikasiProvider);
    final repo = ref.read(notifikasiRepositoryProvider);

    Future<void> aksi(Future<void> Function() f) async {
      final pesan = ScaffoldMessenger.of(context);
      try {
        await f();
        ref.invalidate(notifikasiProvider);
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
              onPressed: () => aksi(repo.bacaSemua),
              child: const Text('Tandai semua dibaca'),
            ),
        ],
      ),
      body: AsyncIsi<List<Notifikasi>>(
        nilai: nilai,
        ulang: () => ref.invalidate(notifikasiProvider),
        bangun: (daftar) {
          if (daftar.isEmpty) {
            return const KosongState(
              ikon: Icons.notifications_none,
              judul: 'Belum ada notifikasi',
              pesan: 'Pengingat tenggat beasiswa tersimpan dan beasiswa baru akan muncul di sini.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notifikasiProvider),
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
                        : Icon(
                            Icons.circle,
                            size: 10,
                            color: Warna.primary,
                          ),
                    onTap: () async {
                      final router = GoRouter.of(context);
                      if (!n.dibaca) await aksi(() => repo.baca(n.id));
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
