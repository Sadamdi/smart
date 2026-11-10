import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

/// Pilihan tampilan: ikut sistem, terang, atau gelap. Disimpan di berkas kecil di perangkat.
class TemaController extends GetxController {
  final mode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _muat();
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
    final cocok = ThemeMode.values.where((m) => m.name == nilai);
    if (cocok.isNotEmpty) mode.value = cocok.first;
  }

  Future<void> atur(ThemeMode baru) async {
    mode.value = baru;
    final f = await _berkas();
    try {
      await f?.writeAsString(baru.name);
    } catch (_) {}
  }
}
