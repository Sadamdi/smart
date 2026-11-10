import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/format.dart';
import 'package:smart_mobile/features/beasiswa/domain/beasiswa.dart';
import 'package:smart_mobile/features/beasiswa/presentation/tersimpan_page.dart';

import 'helpers.dart';

String _hariKe(int n) => tanggalApi(DateTime.now().add(Duration(days: n)));

Map<String, dynamic> _item(String id, String nama, {String? tenggat}) => {
  'beasiswa': beasiswaJson(id, nama, tenggat: tenggat),
  'status_rencana': null,
};

Map<String, Penangan> _rute(List<Map<String, dynamic>> Function() isi) => {
  'GET /me': (o) => Balasan.ok(penggunaJson()),
  'GET /notifikasi': (o) => Balasan.ok([]),
  'GET /me/tersimpan': (o) => Balasan.ok(isi()),
  'GET /me/checklist': (o) => Balasan.ok([]),
  'GET /me/kalender': (o) => Balasan.ok([]),
  'GET /rekomendasi/ringkasan': (o) =>
      Balasan.ok({'memenuhi': 0, 'hampir_memenuhi': 0, 'belum_memenuhi': 0}),
  'GET /rekomendasi': (o) => Balasan.ok([]),
  'GET /beasiswa': (o) => Balasan.ok([], meta: {'kursor_berikut': null}),
};

Future<void> _bukaDariProfil(WidgetTester t, ServerPalsu s) async {
  t.view.physicalSize = const Size(390 * 2, 1400 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(aplikasi(s));
  await t.pumpAndSettle();
  await t.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Profil'),
    ),
  );
  await t.pumpAndSettle();
  final menu = find.text('Beasiswa Tersimpan');
  await t.scrollUntilVisible(menu, 200);
  await t.drag(find.byType(Scrollable).first, const Offset(0, -150));
  await t.pumpAndSettle();
  await t.tap(menu);
  await t.pumpAndSettle();
}

void main() {
  siapkanGet();
  test('urutkanTenggat: terdekat dulu, tanpa tenggat, lalu yang lewat', () {
    final sekarang = DateTime(2026, 11, 10);
    BeasiswaRingkas b(String id, DateTime? t) =>
        BeasiswaRingkas(id: id, nama: id, tenggat: t, tautanResmi: '');
    final hasil = urutkanTenggat([
      b('lewat', DateTime(2026, 11, 1)),
      b('kosong', null),
      b('jauh', DateTime(2026, 12, 30)),
      b('dekat', DateTime(2026, 11, 12)),
    ], sekarang: sekarang);
    expect(hasil.map((e) => e.id), ['dekat', 'jauh', 'kosong', 'lewat']);
  });

  testWidgets('daftar tersimpan terurut dan membuka detail', (t) async {
    final s = ServerPalsu({
      ..._rute(
        () => [
          _item('b', 'Beasiswa Jauh', tenggat: _hariKe(60)),
          _item('a', 'Beasiswa Dekat', tenggat: _hariKe(3)),
        ],
      ),
      'GET /beasiswa/a': (o) => Balasan.ok(beasiswaJson('a', 'Beasiswa Dekat')),
    });
    await _bukaDariProfil(t, s);
    expect(find.textContaining('1 bertenggat dalam 7 hari'), findsOneWidget);
    expect(
      t.getTopLeft(find.text('Beasiswa Dekat')).dy,
      lessThan(t.getTopLeft(find.text('Beasiswa Jauh')).dy),
    );
    await t.tap(find.text('Beasiswa Dekat'));
    await t.pumpAndSettle();
    expect(s.hitung('GET /beasiswa/a'), 1);
  });

  testWidgets('keadaan kosong menawarkan Jelajah', (t) async {
    final s = ServerPalsu(_rute(() => []));
    await _bukaDariProfil(t, s);
    expect(find.text('Belum ada beasiswa tersimpan'), findsOneWidget);
    await t.tap(find.text('Jelajahi beasiswa'));
    await t.pumpAndSettle();
    expect(find.text('Jelajah Beasiswa'), findsOneWidget);
  });

  testWidgets('galat menampilkan coba lagi', (t) async {
    var gagal = true;
    final s = ServerPalsu({
      ..._rute(() => []),
      'GET /me/tersimpan': (o) => gagal
          ? Balasan.galat(500, 'galat', 'Server bermasalah')
          : Balasan.ok([_item('a', 'Beasiswa Dekat', tenggat: _hariKe(3))]),
    });
    await _bukaDariProfil(t, s);
    expect(find.text('Coba lagi'), findsOneWidget);
    gagal = false;
    await t.tap(find.text('Coba lagi'));
    await t.pumpAndSettle();
    expect(find.text('Beasiswa Dekat'), findsOneWidget);
  });

  testWidgets('hapus lewat bookmark lalu urungkan', (t) async {
    var isi = [_item('a', 'Beasiswa Dekat', tenggat: _hariKe(3))];
    final s = ServerPalsu({
      ..._rute(() => isi),
      'DELETE /beasiswa/a/interaksi/simpan': (o) {
        isi = [];
        return Balasan.ok(null);
      },
      'POST /beasiswa/a/interaksi': (o) {
        isi = [_item('a', 'Beasiswa Dekat', tenggat: _hariKe(3))];
        return Balasan.ok(null);
      },
    });
    await _bukaDariProfil(t, s);
    await t.tap(find.byTooltip('Hapus dari tersimpan'));
    await t.pumpAndSettle();
    expect(s.hitung('DELETE /beasiswa/a/interaksi/simpan'), 1);
    expect(find.text('Belum ada beasiswa tersimpan'), findsOneWidget);
    await t.tap(find.text('Urungkan'));
    await t.pumpAndSettle();
    expect(s.hitung('POST /beasiswa/a/interaksi'), 1);
    expect(find.text('Beasiswa Dekat'), findsOneWidget);
  });

  testWidgets('tombol Tersimpan di Jelajah membuka halaman', (t) async {
    final s = ServerPalsu(_rute(() => []));
    t.view.physicalSize = const Size(390 * 2, 1400 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    await t.pumpWidget(aplikasi(s));
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Jelajah'),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Tersimpan'));
    await t.pumpAndSettle();
    expect(find.text('Beasiswa Tersimpan'), findsOneWidget);
  });
}
