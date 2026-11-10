import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notifikasi/presentation/notifikasi_controller.dart';
import '../theme/app_theme.dart';
import 'logo_smart.dart';

/// Kepala halaman tab: logo SMART, program studi, lonceng notifikasi, avatar.
class SmartAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SmartAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<SmartAppBar> createState() => _SmartAppBarState();
}

class _SmartAppBarState extends State<SmartAppBar> {
  @override
  void initState() {
    super.initState();
    // Lencana notifikasi dimuat sekali saat kepala halaman pertama tampil.
    Get.find<NotifikasiController>().daftar.pastikan();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Obx(() => _bangun(context, t));
  }

  Widget _bangun(BuildContext context, TextTheme t) {
    final p = Get.find<AuthController>().pengguna;
    final belumDibaca = Get.find<NotifikasiController>().belumDibaca;
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
            child: Icon(Icons.notifications_none, color: Warna.ink),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            onTap: () => context.go('/profil'),
            customBorder: const CircleBorder(),
            child: CircleAvatar(
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
