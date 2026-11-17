import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Cache respons GET di penyimpanan perangkat, supaya data terakhir tetap bisa dibaca saat tanpa jaringan.
/// Berisi data milik pengguna sendiri; dikosongkan saat keluar.
class CacheLokal {
  CacheLokal([this._folder]);

  Directory? _folder;

  /// Benar bila respons terakhir yang tampil berasal dari cache (jaringan tidak tersedia).
  final luring = ValueNotifier<bool>(false);

  Future<Directory> _dir() async {
    final d =
        _folder ??
        Directory('${(await getApplicationSupportDirectory()).path}/cache_api');
    if (!d.existsSync()) d.createSync(recursive: true);
    return _folder = d;
  }

  Future<File> _berkas(String kunci) async => File(
    '${(await _dir()).path}/${kunci.hashCode.toUnsigned(32).toRadixString(16)}.json',
  );

  Future<void> simpan(String kunci, Object? data, Object? meta) async {
    try {
      await (await _berkas(kunci))
          .writeAsString(jsonEncode({'k': kunci, 'data': data, 'meta': meta}));
    } on Object {
      // Cache hanya pelengkap; galat tulis diabaikan.
    }
  }

  /// Mengembalikan {data, meta} bila ada dan kuncinya cocok.
  Future<Map<String, dynamic>?> baca(String kunci) async {
    try {
      final f = await _berkas(kunci);
      if (!f.existsSync()) return null;
      final m = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return m['k'] == kunci ? m : null;
    } on Object {
      return null;
    }
  }

  Future<void> bersihkan() async {
    luring.value = false;
    try {
      final d = await _dir();
      if (d.existsSync()) d.deleteSync(recursive: true);
      _folder = null;
    } on Object {
      // abaikan
    }
  }
}
