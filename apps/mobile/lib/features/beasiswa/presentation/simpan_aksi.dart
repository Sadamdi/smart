import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dependensi.dart';
import 'tersimpan_controller.dart';

/// Simpan atau hapus simpanan lewat [TersimpanController], lalu tampilkan hasilnya.
Future<void> ubahSimpan(
  BuildContext context,
  String id, {
  required bool tersimpan,
}) async {
  final c = Get.find<TersimpanController>();
  final pesan = ScaffoldMessenger.of(context);
  try {
    if (tersimpan) {
      await c.hapus(id);
    } else {
      await c.simpan(id);
    }
    pesan.showSnackBar(
      SnackBar(
        content: Text(
          tersimpan ? 'Dihapus dari tersimpan.' : 'Beasiswa disimpan.',
        ),
      ),
    );
  } catch (e) {
    pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
  }
}
