import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
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
                Text(
                  'Pengingat tenggat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
                const SizedBox(height: 8),
                const Text(
                  'Pengingat di dalam aplikasi selalu aktif. Sistem tidak pernah menyatakan Anda pasti diterima pada suatu beasiswa.',
                ),
              ],
            ),
    );
  }
}
