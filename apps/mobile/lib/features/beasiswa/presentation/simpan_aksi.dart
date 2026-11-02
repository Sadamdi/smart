import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../kalender/presentation/kalender_providers.dart';
import 'beasiswa_providers.dart';

/// Simpan atau hapus simpanan, lalu segarkan daftar tersimpan dan checklist.
Future<void> ubahSimpan(
  BuildContext context,
  WidgetRef ref,
  String id, {
  required bool tersimpan,
}) async {
  final repo = ref.read(beasiswaRepositoryProvider);
  final pesan = ScaffoldMessenger.of(context);
  try {
    if (tersimpan) {
      await repo.hapusSimpan(id);
    } else {
      await repo.simpan(id);
    }
    ref.invalidate(tersimpanProvider);
    ref.invalidate(checklistProvider);
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
