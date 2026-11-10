// Tangkapan layar untuk tinjauan tampilan terang dan gelap. Tidak ikut uji biasa.
// Jalankan: TANGKAP=1 flutter test test/tangkap_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data_tangkap.dart';
import 'helpers.dart';

void main() {
  siapkanGet();
  final aktif = Platform.environment['TANGKAP'] == '1';
  for (final gelap in [false, true]) {
    final mode = gelap ? 'gelap' : 'terang';
    for (final layar in [
      'masuk',
      'Beranda',
      'Rekomendasi',
      'Jelajah',
      'Kalender',
      'Profil',
    ]) {
      testWidgets('tangkap $layar $mode', skip: !aktif, (t) async {
        await muatHurufTangkap();
        t.view.physicalSize = const Size(390 * 2, 844 * 2);
        t.view.devicePixelRatio = 2;
        t.platformDispatcher.platformBrightnessTestValue = gelap
            ? Brightness.dark
            : Brightness.light;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearAllTestValues);
        await t.pumpWidget(
          aplikasi(ServerPalsu(ruteTangkap()), sudahMasuk: layar != 'masuk'),
        );
        await t.pumpAndSettle();
        if (layar != 'masuk' && layar != 'Beranda') {
          await t.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(layar),
            ),
          );
          await t.pumpAndSettle();
        }
        await expectLater(
          find.byType(Navigator).first,
          matchesGoldenFile('../../../design/render/mobile/$layar-$mode.png'),
        );
      });
    }
  }
}
