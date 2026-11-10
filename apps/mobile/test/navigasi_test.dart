// Tombol Back dan format rupiah (perbaikan 10 November 2026).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/features/profil/presentation/profil_page.dart';

import 'helpers.dart';

Map<String, Penangan> _rute() => {
  'GET /me': (o) => Balasan.ok(penggunaJson()),
  'GET /notifikasi': (o) => Balasan.ok([]),
  'GET /me/tersimpan': (o) => Balasan.ok([]),
  'GET /me/checklist': (o) => Balasan.ok([]),
  'GET /me/kalender': (o) => Balasan.ok([]),
  'GET /rekomendasi/ringkasan': (o) =>
      Balasan.ok({'memenuhi': 0, 'hampir_memenuhi': 0, 'belum_memenuhi': 0}),
  'GET /rekomendasi': (o) => Balasan.ok([]),
  'GET /beasiswa': (o) => Balasan.ok([], meta: {'next_cursor': null}),
};

Future<void> _bukaTab(WidgetTester t, String nama) async {
  await t.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(nama)),
  );
  await t.pumpAndSettle();
}

int _tabAktif(WidgetTester t) =>
    t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  siapkanGet();
  test('formatRupiah memakai pemisah ribuan', () {
    expect(formatRupiah(0), 'Rp0');
    expect(formatRupiah(950), 'Rp950');
    expect(formatRupiah(3500000), 'Rp3.500.000');
    expect(formatRupiah(12000000), 'Rp12.000.000');
  });

  testWidgets('Back di tab selain Beranda kembali ke Beranda', (t) async {
    await t.pumpWidget(aplikasi(ServerPalsu(_rute())));
    await t.pumpAndSettle();
    await _bukaTab(t, 'Jelajah');
    expect(_tabAktif(t), 2);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(_tabAktif(t), 0);
  });

  testWidgets('Back di Ubah profil menutup formulir, bukan pindah tab', (
    t,
  ) async {
    t.view.physicalSize = const Size(800, 3200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(aplikasi(ServerPalsu(_rute())));
    await t.pumpAndSettle();
    await _bukaTab(t, 'Profil');
    final ubah = find.text('Ubah profil');
    await t.tap(ubah);
    await t.pumpAndSettle();
    expect(find.text('Simpan perubahan'), findsOneWidget);

    // Tanpa perubahan: formulir tertutup langsung dan tab tetap Profil.
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Simpan perubahan'), findsNothing);
    expect(_tabAktif(t), 4);

    // Dengan perubahan: konfirmasi muncul; "Lanjut mengubah" mempertahankan formulir.
    await t.tap(find.text('Ubah profil'));
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextFormField, 'Nama lengkap'),
      'Nama Baru',
    );
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Buang perubahan?'), findsOneWidget);
    await t.tap(find.text('Lanjut mengubah'));
    await t.pumpAndSettle();
    expect(find.text('Simpan perubahan'), findsOneWidget);

    // "Buang" menutup formulir dan tab tetap Profil.
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    await t.tap(find.text('Buang'));
    await t.pumpAndSettle();
    expect(find.text('Simpan perubahan'), findsNothing);
    expect(_tabAktif(t), 4);
  });
}
