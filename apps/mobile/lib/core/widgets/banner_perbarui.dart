import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/rekomendasi/presentation/rekomendasi_controller.dart';
import '../theme/app_theme.dart';
import 'ilustrasi_gerak.dart';

/// Spanduk di atas isi semua tab: muncul saat mesin rekomendasi sedang menghitung ulang (mis. setelah profil disimpan)
/// dan berganti centang singkat bila selesai, sehingga pengguna tahu daftar yang tampil sedang atau sudah diperbarui.
class BannerPerbarui extends StatefulWidget {
  const BannerPerbarui({super.key});

  @override
  State<BannerPerbarui> createState() => _BannerPerbaruiState();
}

class _BannerPerbaruiState extends State<BannerPerbarui> {
  Timer? _sembunyi;

  @override
  void dispose() {
    _sembunyi?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<RekomendasiController>()) {
      return const SizedBox.shrink();
    }
    final c = Get.find<RekomendasiController>();
    return Obx(() {
      final s = c.statusPerbarui.value;
      if (s == StatusPerbarui.selesai && _sembunyi == null) {
        _sembunyi = Timer(const Duration(milliseconds: 3200), () {
          _sembunyi = null;
          if (c.statusPerbarui.value == StatusPerbarui.selesai) {
            c.statusPerbarui.value = StatusPerbarui.diam;
          }
        });
      }
      final menghitung = s == StatusPerbarui.menghitung;
      final selesai = s == StatusPerbarui.selesai;
      final t = Theme.of(context).textTheme;
      return AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: (menghitung || selesai)
            ? Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                decoration: BoxDecoration(
                  color: selesai ? Warna.suksesSoft : Warna.container2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selesai ? Warna.sukses : Warna.container4,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (menghitung)
                          const JamPasir(ukuran: 30)
                        else
                          Icon(
                            Icons.check_circle_rounded,
                            color: Warna.sukses,
                            size: 28,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            menghitung
                                ? 'Memperbarui rekomendasi sesuai profilmu. Daftar akan berubah sebentar lagi.'
                                : 'Rekomendasi sudah diperbarui sesuai profilmu.',
                            style: t.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Warna.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (menghitung) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Warna.container4,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      );
    });
  }
}
