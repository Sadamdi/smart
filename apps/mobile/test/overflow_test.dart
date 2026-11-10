// Gerbang tampilan: setiap layar utama harus tampil tanpa overflow pada lebar 320 dp dan skala huruf 130 persen,
// di mode terang maupun gelap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/format.dart';

import 'helpers.dart';

String _hariKe(int n) => tanggalApi(DateTime.now().add(Duration(days: n)));

Map<String, Penangan> _rute() => {
  'GET /me': (o) => Balasan.ok(
    penggunaJson(nama: 'Muhammad Nabila Putri Ramadhani Sekali Panjang'),
  ),
  'GET /notifikasi': (o) => Balasan.ok([
    {
      'id': 'n1',
      'judul': 'Tenggat beasiswa dengan judul yang cukup panjang sekali',
      'isi': 'Beasiswa Unggulan Pemerintah ditutup 6 hari lagi, segera lengkapi berkas.',
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
      'judul': 'Beasiswa Unggulan Pemerintah Republik Indonesia Tahap Dua',
      'ref_id': '1',
      'selesai': false,
    },
  ]),
  'GET /rekomendasi/ringkasan': (o) => Balasan.ok({
    'memenuhi': 12,
    'hampir_memenuhi': 31,
    'belum_memenuhi': 104,
  }),
  'GET /rekomendasi': (o) => Balasan.ok([
    {
      'beasiswa': beasiswaJson(
        '1',
        'Beasiswa Unggulan Pemerintah Republik Indonesia Tahap Dua',
        tenggat: _hariKe(6),
      ),
      'kategori': 'hampir_memenuhi',
      'alasan': ['IPK memenuhi batas minimum yang ditetapkan penyelenggara'],
      'catatan_kekurangan': [
        'Perlu skor TOEFL 500, skor saat ini 470 dan belum ada sertifikat',
      ],
      'tenggat': _hariKe(6),
    },
  ]),
  'GET /beasiswa': (o) => Balasan.ok(
    [
      beasiswaJson(
        '1',
        'Beasiswa Unggulan Pemerintah Republik Indonesia Tahap Dua',
        tenggat: _hariKe(6),
      ),
    ],
    meta: {'next_cursor': null},
  ),
};

void main() {
  for (final gelap in [false, true]) {
    for (final layar in [
      'masuk',
      'Beranda',
      'Rekomendasi',
      'Jelajah',
      'Kalender',
      'Profil',
    ]) {
      testWidgets('tanpa overflow: $layar ${gelap ? 'gelap' : 'terang'}', (
        t,
      ) async {
        t.view.physicalSize = const Size(320 * 2, 640 * 2);
        t.view.devicePixelRatio = 2;
        t.platformDispatcher.textScaleFactorTestValue = 1.3;
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
        expect(t.takeException(), isNull, reason: 'overflow di $layar');
      });
    }
    for (final kosong in [false, true]) {
      testWidgets(
        'tanpa overflow: Beasiswa Tersimpan ${kosong ? 'kosong' : 'berisi'} ${gelap ? 'gelap' : 'terang'}',
        (t) async {
          t.view.physicalSize = const Size(320 * 2, 640 * 2);
          t.view.devicePixelRatio = 2;
          t.platformDispatcher.textScaleFactorTestValue = 1.3;
          t.platformDispatcher.platformBrightnessTestValue = gelap
              ? Brightness.dark
              : Brightness.light;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearAllTestValues);
          final rute = _rute();
          rute['GET /me/tersimpan'] = (o) => Balasan.ok(
            kosong
                ? []
                : [
                    {
                      'beasiswa': beasiswaJson(
                        '1',
                        'Beasiswa Unggulan Pemerintah Republik Indonesia Tahap Dua',
                        tenggat: _hariKe(6),
                      ),
                      'status_rencana': null,
                    },
                  ],
          );
          await t.pumpWidget(aplikasi(ServerPalsu(rute)));
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
          expect(t.takeException(), isNull, reason: 'overflow di Tersimpan');
        },
      );
    }
  }
}
