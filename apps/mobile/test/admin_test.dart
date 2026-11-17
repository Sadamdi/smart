import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/features/admin/presentation/admin_page.dart';

import 'helpers.dart';

Map<String, Penangan> _rute({int menunggu = 2}) => {
  'GET /admin/laporan': (o) => Balasan.ok({
    'beasiswa_per_status': {
      'menunggu_validasi': menunggu,
      'terbit': 10,
      'kedaluwarsa': 0,
      'ditolak': 1,
    },
    'sumber_per_status': {'berhasil': 3, 'gagal': 1, 'belum_pernah': 0},
    'jumlah_sumber': 4,
    'jumlah_mahasiswa': 7,
  }),
  'GET /admin/antrean-validasi': (o) => Balasan.ok([
    {
      ...beasiswaJson('a1', 'Beasiswa Antre Satu'),
      'status': 'menunggu_validasi',
      'nama_sumber': 'Sumber Satu',
      'alasan_ditandai': 'Laman menolak robot (403)',
    },
    {
      ...beasiswaJson('a2', 'Beasiswa Antre Dua'),
      'status': 'menunggu_validasi',
      'nama_sumber': 'Sumber Dua',
    },
  ]),
  'GET /admin/sumber': (o) => Balasan.ok([
    {
      'id': 's1',
      'nama': 'Sumber Satu',
      'url': 'https://contoh.id',
      'jenis': 'pantau_otomatis',
      'status_terakhir': 'gagal',
      'aktif': true,
    },
  ]),
  'POST /admin/beasiswa/a2/terbitkan': (o) => Balasan.ok({}),
  'PUT /admin/sumber/s1': (o) => Balasan.ok({}),
  'POST /admin/sumber/s1/pantau': (o) =>
      Balasan.ok({'ditemukan': 12, 'baru': 3}),
};

Future<ServerPalsu> _buka(WidgetTester t) async {
  final s = ServerPalsu(_rute());
  pasangGetUji(s);
  t.view.physicalSize = const Size(390 * 2, 1400 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  t.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await t.pumpWidget(const MaterialApp(home: AdminPage()));
  await t.pumpAndSettle();
  return s;
}

void main() {
  siapkanGet();

  testWidgets('ringkasan menyebut pekerjaan yang menunggu dan cara pakai', (
    t,
  ) async {
    await _buka(t);
    expect(find.text('2 beasiswa menunggu validasi'), findsOneWidget);
    expect(find.text('1 sumber gagal diperiksa'), findsOneWidget);
    expect(find.text('Alur kerja admin'), findsOneWidget);
  });

  testWidgets('antrean: filter ditandai dan terbitkan mengirim POST', (
    t,
  ) async {
    final s = await _buka(t);
    await t.tap(find.textContaining('Antrean ('));
    await t.pumpAndSettle();
    expect(find.text('Beasiswa Antre Satu'), findsOneWidget);
    expect(find.text('Beasiswa Antre Dua'), findsOneWidget);
    await t.tap(find.text('Ditandai (1)'));
    await t.pumpAndSettle();
    expect(find.text('Beasiswa Antre Dua'), findsNothing);
    await t.tap(find.text('Semua (2)'));
    await t.pumpAndSettle();
    await t.tap(find.text('Terbitkan').last);
    await t.pumpAndSettle();
    expect(s.hitung('POST /admin/beasiswa/a2/terbitkan'), 1);
  });

  testWidgets('sumber: saklar dan Pantau sekarang memanggil server', (t) async {
    final s = await _buka(t);
    await t.tap(find.textContaining('Sumber ('));
    await t.pumpAndSettle();
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(s.terakhir('PUT /admin/sumber/s1').data, {'aktif': false});
    await t.tap(find.text('Pantau sekarang'));
    await t.pumpAndSettle();
    expect(s.hitung('POST /admin/sumber/s1/pantau'), 1);
  });
}
