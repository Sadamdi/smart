// Tangkapan layar untuk tinjauan tampilan terang dan gelap. Tidak ikut uji biasa.
// Jalankan: TANGKAP=1 flutter test test/tangkap_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/format.dart';

import 'helpers.dart';

String _hariKe(int n) => tanggalApi(DateTime.now().add(Duration(days: n)));

Map<String, Penangan> _rute() => {
  'GET /me': (o) => Balasan.ok(penggunaJson()),
  'GET /notifikasi': (o) => Balasan.ok([
    {
      'id': 'n1',
      'judul': 'Tenggat dekat',
      'isi': 'Beasiswa Unggulan ditutup 6 hari lagi.',
      'dibaca': false,
      'dibuat_pada': DateTime.now().toIso8601String(),
    },
  ]),
  'GET /me/tersimpan': (o) => Balasan.ok([]),
  'GET /me/checklist': (o) => Balasan.ok([]),
  'GET /me/kalender': (o) => Balasan.ok([
    {
      'jenis': 'tenggat',
      'tanggal': _hariKe(6),
      'judul': 'Beasiswa Unggulan',
      'ref_id': '1',
      'selesai': false,
    },
  ]),
  'GET /rekomendasi/ringkasan': (o) =>
      Balasan.ok({'memenuhi': 2, 'hampir_memenuhi': 1, 'belum_memenuhi': 4}),
  'GET /rekomendasi': (o) => Balasan.ok([
    {
      'beasiswa': beasiswaJson('1', 'Beasiswa Unggulan', tenggat: _hariKe(6)),
      'kategori': 'memenuhi',
      'alasan': ['IPK memenuhi batas minimum', 'Jenjang S1 sesuai'],
      'catatan_kekurangan': <String>[],
      'tenggat': _hariKe(6),
    },
    {
      'beasiswa': beasiswaJson('2', 'Beasiswa Hampir', tenggat: _hariKe(12)),
      'kategori': 'hampir_memenuhi',
      'alasan': ['Jenjang S1 sesuai'],
      'catatan_kekurangan': ['Perlu skor TOEFL 500, skor saat ini 470'],
      'tenggat': _hariKe(12),
    },
  ]),
  'GET /beasiswa': (o) => Balasan.ok(
    [
      beasiswaJson('1', 'Beasiswa Unggulan', tenggat: _hariKe(6)),
      beasiswaJson('2', 'Beasiswa Prestasi Nasional', tenggat: _hariKe(20)),
      beasiswaJson('3', 'Beasiswa Riset Dasar', tenggat: _hariKe(45)),
    ],
    meta: {'next_cursor': null},
  ),
};

Future<void> _muatHuruf() async {
  final data = File('assets/google_fonts/PlusJakartaSans-Medium.ttf')
      .readAsBytesSync();
  final f = FontLoader('Roboto')
    ..addFont(Future.value(ByteData.view(data.buffer)));
  await f.load();
  final ikon = File(
    '${Platform.environment['USERPROFILE']}/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (ikon.existsSync()) {
    final g = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(ikon.readAsBytesSync().buffer)));
    await g.load();
  }
}

void main() {
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
        await _muatHuruf();
        t.view.physicalSize = const Size(390 * 2, 844 * 2);
        t.view.devicePixelRatio = 2;
        t.platformDispatcher.platformBrightnessTestValue = gelap
            ? Brightness.dark
            : Brightness.light;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearAllTestValues);
        await t.pumpWidget(
          aplikasi(ServerPalsu(_rute()), sudahMasuk: layar != 'masuk'),
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
