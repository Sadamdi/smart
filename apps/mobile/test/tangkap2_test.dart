// Tangkapan layar halaman lanjutan (Detail, Dokumen, Chat, Pengaturan, Daftar) untuk tinjauan tampilan terang dan gelap. Tidak ikut uji biasa.
// Jalankan: TANGKAP=1 flutter test test/tangkap2_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'data_tangkap.dart';
import 'helpers.dart';

void main() {
  siapkanGet();
  final aktif = Platform.environment['TANGKAP'] == '1';
  const jalur = {
    'Detail': '/beasiswa/1',
    'Dokumen': '/dokumen',
    'Chat': '/chat',
    'Pengaturan': '/pengaturan',
    'Daftar': '/daftar',
    'Tersimpan': '/tersimpan',
  };
  for (final gelap in [false, true]) {
    final mode = gelap ? 'gelap' : 'terang';
    for (final e in jalur.entries) {
      testWidgets('tangkap ${e.key} $mode', skip: !aktif, (t) async {
        await muatHurufTangkap();
        t.view.physicalSize = const Size(390 * 2, 844 * 2);
        t.view.devicePixelRatio = 2;
        t.platformDispatcher.platformBrightnessTestValue = gelap
            ? Brightness.dark
            : Brightness.light;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearAllTestValues);
        await t.pumpWidget(
          aplikasi(ServerPalsu(ruteTangkap()), sudahMasuk: e.key != 'Daftar'),
        );
        await t.pumpAndSettle();
        GoRouter.of(t.element(find.byType(Scaffold).first)).go(e.value);
        await t.pumpAndSettle();
        await expectLater(
          find.byType(Navigator).first,
          matchesGoldenFile('../../../design/render/mobile/${e.key}-$mode.png'),
        );
      });
    }
  }
  for (final gelap in [false, true]) {
    final mode = gelap ? 'gelap' : 'terang';
    testWidgets('tangkap Pembuka $mode', skip: !aktif, (t) async {
      await muatHurufTangkap();
      t.view.physicalSize = const Size(390 * 2, 844 * 2);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.platformBrightnessTestValue = gelap
          ? Brightness.dark
          : Brightness.light;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearAllTestValues);
      await t.pumpWidget(
        aplikasi(ServerPalsu(ruteTangkap()), sudahMasuk: false, pembuka: true),
      );
      // Akhir urutan huruf dan tagline, sebelum memudar (2650 ms).
      await t.pump(const Duration(milliseconds: 2600));
      await expectLater(
        find.byType(Navigator).first,
        matchesGoldenFile('../../../design/render/mobile/Pembuka-$mode.png'),
      );
      await t.pumpAndSettle(const Duration(seconds: 1));
    });
  }
}
