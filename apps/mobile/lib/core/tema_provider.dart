import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Pilihan tampilan: ikut sistem, terang, atau gelap. Disimpan di berkas kecil di perangkat.
class TemaController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _muat();
    return ThemeMode.system;
  }

  Future<File?> _berkas() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/tampilan.txt');
    } catch (_) {
      return null; // uji tanpa plugin
    }
  }

  Future<void> _muat() async {
    final f = await _berkas();
    if (f == null || !await f.exists()) return;
    final nilai = (await f.readAsString()).trim();
    final mode = ThemeMode.values.where((m) => m.name == nilai);
    if (mode.isNotEmpty) state = mode.first;
  }

  Future<void> atur(ThemeMode mode) async {
    state = mode;
    final f = await _berkas();
    try {
      await f?.writeAsString(mode.name);
    } catch (_) {}
  }
}

final temaProvider = NotifierProvider<TemaController, ThemeMode>(
  TemaController.new,
);
