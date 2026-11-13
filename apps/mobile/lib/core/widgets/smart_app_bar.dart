import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifikasi/presentation/notifikasi_controller.dart';
import 'logo_smart.dart';
import 'tombol_bulat.dart';

/// Kepala halaman tab: logo SMART dan lonceng notifikasi dalam lingkaran.
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
    final belumDibaca = Get.find<NotifikasiController>().belumDibaca;
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 16,
      title: Row(
        children: [
          const LogoSmart(ukuran: 32),
          const SizedBox(width: 10),
          Text(
            'SMART',
            style: t.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TombolBulat(
            ikon: Icons.notifications_none,
            tooltip: 'Notifikasi',
            onTap: () => context.push('/notifikasi'),
            lencana: belumDibaca,
          ),
        ),
      ],
    );
  }
}
