import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/tema_provider.dart';
import '../../../core/update/app_update_checker.dart';
import '../../../core/update/versi_aplikasi.dart';
import '../../auth/presentation/auth_controller.dart';

class PengaturanPage extends ConsumerWidget {
  const PengaturanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(authControllerProvider).pengguna;
    final pesan = ScaffoldMessenger.of(context);

    Future<void> ubah({required bool email, required bool push}) async {
      try {
        await ref
            .read(authControllerProvider.notifier)
            .ubahPreferensi(email: email, push: push);
      } catch (e) {
        pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: p == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Grup(
                  judul: 'Pengingat tenggat',
                  anak: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Pengingat lewat surel'),
                        value: p.notifEmail,
                        onChanged: (v) => ubah(email: v, push: p.notifPush),
                      ),
                      SwitchListTile(
                        title: const Text('Pengingat push di ponsel'),
                        value: p.notifPush,
                        onChanged: (v) => ubah(email: p.notifEmail, push: v),
                      ),
                    ],
                  ),
                ),
                _Grup(
                  judul: 'Tampilan',
                  anak: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto),
                          label: Text('Sistem'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Terang'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Gelap'),
                        ),
                      ],
                      selected: {ref.watch(temaProvider)},
                      onSelectionChanged: (s) =>
                          ref.read(temaProvider.notifier).atur(s.first),
                    ),
                  ),
                ),
                _Grup(
                  judul: 'Aplikasi',
                  anak: Column(
                    children: [
                      const TileVersiAplikasi(),
                      ListTile(
                        leading: const Icon(Icons.system_update_alt),
                        title: const Text('Periksa pembaruan'),
                        subtitle: const Text(
                          'Unduh versi terbaru bila tersedia',
                        ),
                        onTap: () => AppUpdateChecker.manual(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: const Text('Catatan rilis'),
                        onTap: () => AppUpdateChecker.tampilkanCatatan(context),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Pengingat di dalam aplikasi selalu aktif. Sistem tidak pernah menyatakan Anda pasti diterima pada suatu beasiswa.',
                ),
              ],
            ),
    );
  }
}

class _Grup extends StatelessWidget {
  const _Grup({required this.judul, required this.anak});

  final String judul;
  final Widget anak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
            child: Text(judul, style: Theme.of(context).textTheme.titleMedium),
          ),
          Material(
            color: Warna.kartu,
            borderRadius: BorderRadius.circular(Jari.kartu),
            clipBehavior: Clip.antiAlias,
            child: anak,
          ),
        ],
      ),
    );
  }
}
