import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../core/dependensi.dart';
import '../../../core/lokal/mesin_lokal.dart';
import '../../../core/lokal/model_ai.dart';
import '../../../core/theme/app_theme.dart';

/// Pengaturan mode luring: semua perhitungan rekomendasi dan simpan beasiswa berjalan di perangkat, dan perubahan
/// dikirim ke server saat jaringan kembali.
class KartuModeLuring extends StatefulWidget {
  const KartuModeLuring({super.key});

  @override
  State<KartuModeLuring> createState() => _KartuModeLuringState();
}

class _KartuModeLuringState extends State<KartuModeLuring> {
  final _m = Get.find<MesinLokal>();
  final _api = Get.find<ApiClient>();

  String _waktu(DateTime? d) {
    if (d == null) return 'belum pernah';
    final selisih = DateTime.now().difference(d);
    if (selisih.inMinutes < 1) return 'baru saja';
    if (selisih.inHours < 1) return '${selisih.inMinutes} menit lalu';
    if (selisih.inDays < 1) return '${selisih.inHours} jam lalu';
    return '${selisih.inDays} hari lalu';
  }

  Future<void> _ganti(bool nyala) async {
    final pesan = ScaffoldMessenger.of(context);
    if (nyala) {
      if (!_m.siap) {
        final ok = await _api.sinkronkan();
        if (!ok) {
          pesan.showSnackBar(
            const SnackBar(
              content: Text(
                'Data belum bisa diunduh. Nyalakan mode luring saat ada jaringan.',
              ),
            ),
          );
          return;
        }
      }
      await _m.aturAktif(true);
      Get.find<PengelolaModelAi>().siapkanDiLatarBelakang();
    } else {
      await _m.aturAktif(false);
      final ok = await _api.sinkronkan();
      pesan.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Perubahan dikirim dan data diperbarui.'
                : 'Perubahan akan dikirim saat jaringan kembali.',
          ),
        ),
      );
    }
    segarkanTampilan();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Warna.container4),
      ),
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _m.aktif,
          _m.menunggu,
          _m.terakhirSinkron,
          _m.sedangSinkron,
        ]),
        builder: (context, _) {
          final keterangan = StringBuffer(
            _m.siap
                ? 'Data ${_m.jumlahBeasiswa} beasiswa ada di perangkat, diperbarui ${_waktu(_m.terakhirSinkron.value)}.'
                : 'Data belum diunduh. Nyalakan saat ada jaringan untuk mengunduhnya.',
          );
          if (_m.menunggu.value > 0) {
            keterangan.write(
              ' ${_m.menunggu.value} perubahan menunggu dikirim ke server.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  'Mode luring',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Rekomendasi, peluang, simpan beasiswa, dan chatbot dasar dihitung di ponsel tanpa jaringan. Hasilnya perkiraan dan tidak memakai pemeringkat server.',
                  style: t.bodySmall?.copyWith(fontSize: 11),
                ),
                value: _m.aktif.value,
                onChanged: _m.sedangSinkron.value ? null : _ganti,
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  'Chatbot AI luring',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Unduh model AI kecil agar chatbot menjawab tanpa jaringan',
                  style: t.bodySmall?.copyWith(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push('/pengaturan/model-ai'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        keterangan.toString(),
                        style: t.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                    TextButton(
                      onPressed: _m.sedangSinkron.value
                          ? null
                          : () async {
                              final pesan = ScaffoldMessenger.of(context);
                              final ok = await _api.sinkronkan();
                              pesan.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok ? 'Sinkron selesai.' : 'Tidak ada jaringan, coba lagi nanti.',
                                  ),
                                ),
                              );
                              segarkanTampilan();
                            },
                      child: Text(
                        _m.sedangSinkron.value ? 'Menyinkronkan' : 'Sinkronkan',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
