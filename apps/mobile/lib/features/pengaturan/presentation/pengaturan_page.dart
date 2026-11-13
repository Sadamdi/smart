import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/tema_controller.dart';
import '../../../core/update/app_update_checker.dart';
import '../../../core/update/versi_aplikasi.dart';
import '../../../core/widgets/tombol_bulat.dart';
import '../../auth/presentation/auth_controller.dart';
import 'pengaturan_controller.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  final _ctrl = Get.put(PengaturanController());

  @override
  void dispose() {
    Get.delete<PengaturanController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final p = Get.find<AuthController>().pengguna;
    final tema = Get.find<TemaController>();
    final pesan = ScaffoldMessenger.of(context);

    Future<void> ubah({required bool email, required bool push}) async {
      final galat = await _ctrl.ubahPreferensi(email: email, push: push);
      if (galat != null) {
        pesan.showSnackBar(SnackBar(content: Text(galat)));
      }
    }

    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TombolBulat.kembali(context),
        ),
      ),
      body: p == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text('Pengaturan', style: t.headlineMedium),
                const SizedBox(height: 16),
                _Grup(
                  judul: 'Tampilan',
                  anak: _Segmen(nilai: tema.mode.value, onPilih: tema.atur),
                ),
                _Grup(
                  judul: 'Pengingat tenggat',
                  anak: Column(
                    children: [
                      _Kartu(
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: Text(
                            'Pengingat lewat surel',
                            style: _judulBaris(t),
                          ),
                          value: p.notifEmail,
                          onChanged: (v) => ubah(email: v, push: p.notifPush),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Kartu(
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: Text(
                            'Pengingat push di ponsel',
                            style: _judulBaris(t),
                          ),
                          value: p.notifPush,
                          onChanged: (v) => ubah(email: p.notifEmail, push: v),
                        ),
                      ),
                    ],
                  ),
                ),
                _Grup(
                  judul: 'Aplikasi',
                  anak: Column(
                    children: [
                      const _Kartu(child: TileVersiAplikasi()),
                      const SizedBox(height: 8),
                      _Kartu(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: Text(
                            'Periksa pembaruan',
                            style: _judulBaris(t),
                          ),
                          subtitle: Text(
                            'Unduh versi terbaru bila tersedia',
                            style: t.bodySmall?.copyWith(fontSize: 11),
                          ),
                          onTap: () => AppUpdateChecker.manual(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Kartu(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          title: Text('Catatan rilis', style: _judulBaris(t)),
                          onTap: () =>
                              AppUpdateChecker.tampilkanCatatan(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Pengingat di dalam aplikasi selalu aktif. Sistem tidak pernah menyatakan Anda pasti diterima pada suatu beasiswa.',
                  style: t.bodySmall,
                ),
              ],
            ),
    );
  }
}

TextStyle? _judulBaris(TextTheme t) =>
    t.bodyMedium?.copyWith(fontWeight: FontWeight.w500);

/// Kartu putih bergaris tipis, radius 14, untuk satu baris pengaturan.
class _Kartu extends StatelessWidget {
  const _Kartu({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Warna.container4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Pilihan tampilan: latar kapsul lembut, segmen aktif berwarna utama.
class _Segmen extends StatelessWidget {
  const _Segmen({required this.nilai, required this.onPilih});

  final ThemeMode nilai;
  final ValueChanged<ThemeMode> onPilih;

  static const _opsi = [
    (ThemeMode.system, 'Sistem'),
    (ThemeMode.light, 'Terang'),
    (ThemeMode.dark, 'Gelap'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Warna.container2,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final (mode, label) in _opsi)
            Expanded(
              child: Semantics(
                button: true,
                selected: nilai == mode,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onPilih(mode),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: nilai == mode ? Warna.primary : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: t.labelLarge?.copyWith(
                        color: nilai == mode ? Warna.putih : Warna.ink,
                        fontWeight: nilai == mode
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
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
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(judul, style: Theme.of(context).textTheme.titleMedium),
          ),
          anak,
        ],
      ),
    );
  }
}
