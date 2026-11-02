import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/format.dart';
import 'package:smart_mobile/core/providers.dart';
import 'package:smart_mobile/core/theme/app_theme.dart';
import 'package:smart_mobile/core/token_storage.dart';
import 'package:smart_mobile/features/beasiswa/presentation/detail_page.dart';

import 'helpers.dart';

void main() {
  testWidgets(
    'detail menampilkan syarat dan berkas, membuka tautan resmi, mencatat klik',
    (t) async {
      t.view.physicalSize = const Size(390 * 2, 1600 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final dibuka = <Uri>[];
      final s = ServerPalsu({
        'GET /beasiswa/1': (o) => Balasan.ok({
          ...beasiswaJson(
            '1',
            'Beasiswa Satu',
            tenggat: tanggalApi(DateTime.now().add(const Duration(days: 5))),
          ),
          'manfaat': 'Biaya kuliah penuh',
          'tanggal_diperiksa': '2026-11-01',
          'persyaratan': [
            {
              'jenis': 'jenjang',
              'nilai_batas': {'nilai': 'S1'},
              'dapat_dikejar': false,
            },
          ],
          'berkas_wajib': [
            {'id': 'b1', 'nama_berkas': 'Transkrip nilai'},
          ],
        }),
        'GET /me/tersimpan': (o) => Balasan.ok([]),
        'GET /me/checklist': (o) => Balasan.ok([]),
        'POST /beasiswa/1/interaksi': (o) =>
            Balasan.ok({'id': 'i', 'aksi': 'klik'}),
      });
      await t.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(MemoryTokenStorage()),
            dioProvider.overrideWithValue(dioPalsu(s)),
            bukaTautanProvider.overrideWithValue((u) async {
              dibuka.add(u);
              return true;
            }),
          ],
          child: MaterialApp(
            theme: buatTema(googleFonts: false),
            home: const DetailPage(id: '1'),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Beasiswa Satu'), findsOneWidget);
      expect(find.text('Biaya kuliah penuh'), findsOneWidget);
      expect(find.text('Jenjang'), findsOneWidget);
      expect(find.text('Transkrip nilai'), findsOneWidget);

      await t.tap(find.text('Kunjungi Laman Resmi'));
      await t.pumpAndSettle();
      expect(dibuka.single.toString(), 'https://contoh.ac.id/1');
      expect(s.hitung('POST /beasiswa/1/interaksi'), 1);
      expect(s.terakhir('POST /beasiswa/1/interaksi').data, {'aksi': 'klik'});
    },
  );
}
