import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notifikasi/presentation/notifikasi_providers.dart';
import '../theme/app_theme.dart';
import 'logo_smart.dart';

/// Kepala halaman tab: logo SMART, program studi, lonceng notifikasi, avatar.
class SmartAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SmartAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = ref.watch(authControllerProvider).pengguna;
    final belumDibaca =
        ref.watch(notifikasiProvider).value?.where((n) => !n.dibaca).length ??
        0;
    final sub = [
      if ((p?.jenjang ?? '').isNotEmpty) p!.jenjang!,
      if ((p?.programStudi ?? '').isNotEmpty) p!.programStudi!,
    ].join(' ');

    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 16,
      title: Row(
        children: [
          const LogoSmart(),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SMART', style: t.titleMedium),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: () => context.push('/notifikasi'),
          icon: Badge(
            isLabelVisible: belumDibaca > 0,
            label: Text('$belumDibaca'),
            child: const Icon(Icons.notifications_none, color: Warna.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () => context.go('/profil'),
            customBorder: const CircleBorder(),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Warna.primary,
              child: Icon(Icons.person, size: 20, color: Warna.putih),
            ),
          ),
        ),
      ],
    );
  }
}
