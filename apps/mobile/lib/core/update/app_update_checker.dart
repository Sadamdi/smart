import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'pembaruan_controller.dart';
import 'update_config.dart';
import 'update_manifest.dart';

enum StatusPeriksa { tersedia, terbaru, bukanResmi, gagal }

class HasilPeriksa {
  const HasilPeriksa(
    this.status, {
    this.manifest,
    this.build = 0,
    this.versi = '',
  });

  final StatusPeriksa status;
  final UpdateManifest? manifest;
  final int build;
  final String versi;
}

/// Memeriksa `latest.json` di GitHub Releases. Bila ada build yang lebih baru, APK untuk arsitektur ponsel
/// (64-bit atau 32-bit) diunduh di dalam aplikasi dengan bilah kemajuan, diverifikasi, lalu diserahkan ke
/// pemasang Android. Android selalu meminta konfirmasi pengguna untuk memasang APK di luar Play Store.
///
/// Pengamanan: unduhan hanya lewat HTTPS dari GitHub, SHA-256 harus cocok dengan manifest, kunci penandatangan
/// APK unduhan harus sama dengan kunci aplikasi terpasang, dan Android sendiri menolak pembaruan yang
/// tanda tangannya berbeda.
class AppUpdateChecker {
  AppUpdateChecker._();

  static const _kanal = MethodChannel('smart/app_info');
  static String? _kunciSendiri;
  static bool _dialogTerbuka = false;
  static bool _ditutupPengguna = false;
  static bool _opsionalSudahTampil = false;
  static DateTime? _terakhirPeriksa;
  static int _percobaanJaringan = 0;

  static Future<String?> sidikKunciSendiri() async {
    try {
      return _kunciSendiri ??= await _kanal.invokeMethod<String>(
        'signingCertSha256',
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String?> sidikKunciApk(String path) async {
    try {
      return await _kanal.invokeMethod<String>('archiveCertSha256', {
        'path': path,
      });
    } catch (_) {
      return null;
    }
  }

  static bool get _didukung => !kIsWeb && Platform.isAndroid;

  static Future<UpdateManifest> ambilManifest({Dio? dio}) async {
    final res = await (dio ?? Dio()).get<String>(
      manifestUrl,
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Cache-Control': 'no-cache'},
        // Tanpa batas waktu, sambungan mati membuat pemeriksaan menggantung.
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    return UpdateManifest.fromJson(
      jsonDecode(res.data ?? '{}') as Map<String, dynamic>,
    );
  }

  /// Satu kali pemeriksaan jaringan. Tidak pernah melempar galat.
  static Future<HasilPeriksa> periksa({Dio? dio}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber) ?? 0;
      final m = await ambilManifest(dio: dio);
      // Build debug atau berkunci lain tidak boleh menerima pembaruan resmi (kuncinya tidak akan cocok).
      final kunci = await sidikKunciSendiri();
      if (m.certSha256 != null && kunci != null && m.certSha256 != kunci) {
        return HasilPeriksa(
          StatusPeriksa.bukanResmi,
          manifest: m,
          build: build,
          versi: info.version,
        );
      }
      if (!m.lebihBaruDari(build)) {
        return HasilPeriksa(
          StatusPeriksa.terbaru,
          manifest: m,
          build: build,
          versi: info.version,
        );
      }
      return HasilPeriksa(
        StatusPeriksa.tersedia,
        manifest: m,
        build: build,
        versi: info.version,
      );
    } catch (e) {
      debugPrint('[update] pemeriksaan dilewati: $e');
      return const HasilPeriksa(StatusPeriksa.gagal);
    }
  }

  /// Dipanggil saat aplikasi dibuka dan setiap kembali ke latar depan. Diam bila tidak ada pembaruan atau gagal.
  static Future<void> otomatis(BuildContext? Function() contextOf) async {
    if (!_didukung || _dialogTerbuka) return;
    if (!kReleaseMode && manifestUrl == manifestUrlBawaan) return;
    final sekarang = DateTime.now();
    if (_terakhirPeriksa != null &&
        sekarang.difference(_terakhirPeriksa!) < const Duration(hours: 6)) {
      return;
    }
    _terakhirPeriksa = sekarang;
    await _hapusUnduhanLama();
    final hasil = await periksa();
    if (hasil.status == StatusPeriksa.gagal && _percobaanJaringan < 3) {
      // Jaringan sering belum siap tepat setelah aplikasi dibuka: coba lagi beberapa kali.
      _percobaanJaringan++;
      _terakhirPeriksa = null;
      Future<void>.delayed(
        const Duration(seconds: 30),
        () => otomatis(contextOf),
      );
      return;
    }
    _percobaanJaringan = 0;
    if (hasil.status != StatusPeriksa.tersedia) return;
    final wajib = hasil.manifest!.wajibUntuk(hasil.build);
    if (!wajib && _opsionalSudahTampil) return;
    _opsionalSudahTampil = true;
    // Tunggu (maksimal semenit) sampai aplikasi melewati layar pemuatan.
    BuildContext? context;
    for (var i = 0; i < 60; i++) {
      context = contextOf();
      if (context != null && context.mounted) break;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (context == null || !context.mounted) {
      _opsionalSudahTampil = false;
      return;
    }
    await _tampilkanDialog(context, hasil, wajib, contextOf: contextOf);
  }

  /// Dari Pengaturan: memeriksa sekarang dan memberi tahu apa pun hasilnya.
  static Future<void> manual(BuildContext context) async {
    final pesan = ScaffoldMessenger.of(context);
    if (!_didukung) {
      pesan.showSnackBar(
        const SnackBar(
          content: Text('Pembaruan otomatis hanya tersedia di Android.'),
        ),
      );
      return;
    }
    pesan.showSnackBar(const SnackBar(content: Text('Memeriksa pembaruan...')));
    final hasil = await periksa();
    pesan.hideCurrentSnackBar();
    if (!context.mounted) return;
    switch (hasil.status) {
      case StatusPeriksa.tersedia:
        await _tampilkanDialog(
          context,
          hasil,
          hasil.manifest!.wajibUntuk(hasil.build),
        );
      case StatusPeriksa.terbaru:
        pesan.showSnackBar(
          SnackBar(
            content: Text('Aplikasi sudah versi terbaru (${hasil.versi}).'),
          ),
        );
      case StatusPeriksa.bukanResmi:
        pesan.showSnackBar(
          const SnackBar(
            content: Text(
              'Aplikasi ini bukan versi resmi, jadi tidak bisa diperbarui otomatis.',
            ),
          ),
        );
      case StatusPeriksa.gagal:
        pesan.showSnackBar(
          const SnackBar(
            content: Text(
              'Pembaruan belum bisa diperiksa. Periksa internet lalu coba lagi.',
            ),
          ),
        );
    }
  }

  static Future<void> _tampilkanDialog(
    BuildContext context,
    HasilPeriksa hasil,
    bool wajib, {
    BuildContext? Function()? contextOf,
  }) async {
    if (_dialogTerbuka) return;
    _dialogTerbuka = true;
    final c = PembaruanController.instance;
    try {
      var ulang = 0;
      BuildContext? ctx = context;
      // Dialog bisa terlepas sendiri bila tumpukan halaman berganti (mis. pengalihan masuk/beranda saat aplikasi
      // baru dibuka). Selama bukan pengguna yang menutupnya dan unduhan belum jalan, tampilkan lagi.
      while (ctx != null && ctx.mounted) {
        _ditutupPengguna = false;
        c.setDialogTerbuka(true);
        if (!ctx.mounted) break;
        await showDialog<void>(
          // ignore: use_build_context_synchronously
          context: ctx,
          barrierDismissible: false,
          builder: (_) => _DialogPembaruan(hasil: hasil, wajib: wajib),
        );
        c.setDialogTerbuka(false);
        final perlu =
            !_ditutupPengguna &&
            c.tahap != TahapPembaruan.memasang &&
            (wajib || c.tahap == TahapPembaruan.siap);
        if (!perlu || contextOf == null || ++ulang > 5) break;
        await Future<void>.delayed(const Duration(milliseconds: 800));
        ctx = contextOf();
      }
    } finally {
      c.setDialogTerbuka(false);
      _dialogTerbuka = false;
    }
  }

  /// Riwayat catatan rilis (Pengaturan, Versi aplikasi).
  static Future<void> tampilkanCatatan(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    final terpasang = int.tryParse(info.buildNumber) ?? 0;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => FutureBuilder<UpdateManifest>(
          future: ambilManifest(),
          builder: (ctx, snap) {
            if (snap.hasError) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Catatan rilis belum bisa dimuat. Periksa internet lalu coba lagi.',
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _DaftarCatatan(
              controller: scroll,
              rilis: snap.data!.riwayat,
              terpasang: terpasang,
            );
          },
        ),
      ),
    );
  }

  /// APK hasil pembaruan sebelumnya hanya memenuhi penyimpanan.
  static Future<void> _hapusUnduhanLama() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final terpasang = int.tryParse(info.buildNumber) ?? 0;
      final dir = await getApplicationCacheDirectory();
      await for (final f in dir.list()) {
        final m = RegExp(r'smart-update-(\d+)\.apk').firstMatch(f.path);
        final build = int.tryParse(m?.group(1) ?? '');
        if (build != null && build <= terpasang) await f.delete();
      }
    } catch (_) {}
  }
}

class _DialogPembaruan extends StatefulWidget {
  const _DialogPembaruan({required this.hasil, required this.wajib});

  final HasilPeriksa hasil;
  final bool wajib;

  @override
  State<_DialogPembaruan> createState() => _DialogPembaruanState();
}

class _DialogPembaruanState extends State<_DialogPembaruan> {
  final _c = PembaruanController.instance;

  UpdateManifest get _m => widget.hasil.manifest!;
  int get _terpasang => widget.hasil.build;

  String get _barisVersi {
    final v = bandingkanVersi(_m.version, widget.hasil.versi);
    if (v < 0) return 'Pembaruan resmi: SMART ${_m.version}';
    return 'Versi Anda ${widget.hasil.versi}, tersedia ${_m.version}';
  }

  int get _tertinggal {
    final baru = _m.riwayat.where((r) => r.build > _terpasang).length;
    return baru > 0 ? baru : 1;
  }

  void _lihatSemua() {
    showModalBottomSheet<void>(
      useSafeArea: true,
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => _DaftarCatatan(
          controller: scroll,
          rilis: _m.riwayat,
          terpasang: _terpasang,
        ),
      ),
    );
  }

  /// Menutup dialog atas kehendak pengguna (bukan karena halaman di bawahnya berganti).
  void _tutup() {
    AppUpdateChecker._ditutupPengguna = true;
    Navigator.of(context).pop();
  }

  void _perbarui() {
    _c.mulai(widget.hasil);
    // Unduhan berjalan di latar belakang dengan banner kemajuan; dialog opsional langsung ditutup.
    if (!widget.wajib) _tutup();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final tahap = _c.tahap;
        final persen = _c.kemajuan == null
            ? null
            : (_c.kemajuan! * 100).clamp(0, 100).round();
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(
              tahap == TahapPembaruan.memasang
                  ? 'Memasang pembaruan'
                  : widget.wajib
                  ? 'Pembaruan wajib'
                  : 'Versi baru tersedia',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _barisVersi,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_tertinggal > 1)
                    Text(
                      'Naik $_tertinggal versi sekaligus',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  if (_m.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_m.notes),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      onPressed: _lihatSemua,
                      child: Text(
                        _m.riwayat.length > 1
                            ? 'Lihat semua catatan rilis'
                            : 'Lihat catatan lengkap',
                      ),
                    ),
                  ),
                  if (widget.wajib) ...[
                    const SizedBox(height: 8),
                    const Text('Versi ini wajib dipasang untuk melanjutkan.'),
                  ],
                  if (tahap == TahapPembaruan.mengunduh) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: _c.kemajuan),
                    const SizedBox(height: 6),
                    Text(
                      _c.menungguJaringan
                          ? 'Menunggu koneksi internet... unduhan dilanjutkan otomatis.'
                          : persen == null
                          ? 'Menyiapkan unduhan...'
                          : 'Mengunduh $persen%',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Unduhan tetap jalan di latar belakang. Pemasang terbuka otomatis setelah selesai.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                  if (tahap == TahapPembaruan.memasang) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih "Perbarui" di jendela pemasangan, lalu "Buka" untuk menjalankan versi baru.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pertama kali, Android meminta izin "Izinkan dari sumber ini". Aktifkan untuk SMART, lalu kembali dan tekan "Pasang lagi".',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                  if (_c.galat != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _c.galat!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (tahap == TahapPembaruan.mengunduh) ...[
                TextButton(onPressed: _c.batal, child: const Text('Batal')),
                if (!widget.wajib)
                  FilledButton(
                    onPressed: _tutup,
                    child: const Text('Sembunyikan'),
                  ),
              ] else ...[
                if (!widget.wajib)
                  TextButton(onPressed: _tutup, child: const Text('Nanti')),
                FilledButton(
                  onPressed: tahap == TahapPembaruan.memasang
                      ? _c.pasang
                      : _perbarui,
                  child: Text(switch (tahap) {
                    TahapPembaruan.gagal =>
                      _c.bisaLanjut ? 'Lanjutkan' : 'Coba lagi',
                    TahapPembaruan.memasang => 'Pasang lagi',
                    _ => 'Perbarui sekarang',
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Riwayat semua rilis. Versi terpasang diberi label "Versi Anda", versi yang dibawa pembaruan diberi "Baru".
class _DaftarCatatan extends StatelessWidget {
  const _DaftarCatatan({
    required this.controller,
    required this.rilis,
    required this.terpasang,
  });

  final ScrollController controller;
  final List<CatatanRilis> rilis;
  final int terpasang;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: rilis.length + 1,
      separatorBuilder: (_, i) =>
          i == 0 ? const SizedBox(height: 8) : const Divider(height: 24),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Text(
            'Catatan rilis',
            style: Theme.of(context).textTheme.titleLarge,
          );
        }
        final r = rilis[i - 1];
        final baru = r.build > terpasang;
        final ini = r.build == terpasang;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: baru ? skema.primary.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(12),
            border: ini ? Border.all(color: skema.outline) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Versi ${r.version}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  if (baru) _Label(teks: 'Baru', warna: skema.primary),
                  if (ini) _Label(teks: 'Versi Anda', warna: skema.outline),
                  const Spacer(),
                  if (r.date != null)
                    Text(r.date!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              if (r.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(r.notes),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.teks, required this.warna});

  final String teks;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        teks,
        style: TextStyle(
          fontSize: 12,
          color: warna,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
