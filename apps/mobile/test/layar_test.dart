import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/format.dart';
import 'package:smart_mobile/core/theme/app_theme.dart';
import 'package:smart_mobile/core/widgets/kartu_beasiswa.dart';
import 'package:smart_mobile/features/beasiswa/domain/beasiswa.dart';
import 'package:smart_mobile/features/rekomendasi/domain/rekomendasi.dart';

import 'helpers.dart';

final _larangan = RegExp(
  r'pencocokan|\d+\s?%|peluang|pasti diterima',
  caseSensitive: false,
);

String _hariKe(int n) => tanggalApi(DateTime.now().add(Duration(days: n)));

Map<String, Penangan> _rutePokok({
  Map<String, Penangan> tambahan = const {},
}) => {
  'GET /me': (o) => Balasan.ok(penggunaJson()),
  'GET /notifikasi': (o) => Balasan.ok([]),
  'GET /me/tersimpan': (o) => Balasan.ok([]),
  'GET /me/checklist': (o) => Balasan.ok([]),
  'GET /me/kalender': (o) => Balasan.ok([]),
  'GET /rekomendasi/ringkasan': (o) =>
      Balasan.ok({'memenuhi': 2, 'hampir_memenuhi': 1, 'belum_memenuhi': 4}),
  'GET /rekomendasi': (o) => Balasan.ok([]),
  'GET /beasiswa': (o) => Balasan.ok([]),
  ...tambahan,
};

Future<void> _pasang(WidgetTester t, ServerPalsu s, {bool masuk = true}) async {
  t.view.physicalSize = const Size(390 * 2, 1400 * 2);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(aplikasi(s, sudahMasuk: masuk));
  await t.pumpAndSettle();
}

Future<void> _tab(WidgetTester t, String label) async {
  await t.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await t.pumpAndSettle();
}

void main() {
  group('KartuBeasiswa', () {
    testWidgets(
      'menampilkan kategori, alasan, catatan; tanpa persen atau peluang',
      (t) async {
        var dibuka = false;
        await t.pumpWidget(
          MaterialApp(
            theme: buatTema(googleFonts: false),
            home: Scaffold(
              body: SingleChildScrollView(
                child: KartuBeasiswa(
                  beasiswa: BeasiswaRingkas(
                    id: '1',
                    nama: 'Beasiswa Uji',
                    penyelenggara: 'Yayasan Uji',
                    jenjang: 'S1',
                    tenggat: DateTime(2026, 11, 18),
                    tautanResmi: 'https://uji.id',
                  ),
                  kategori: Kategori.hampirMemenuhi,
                  alasan: const ['Jenjang S1 sesuai'],
                  catatan: const ['IPK kurang 0,10 dari syarat 3,50'],
                  sekarang: DateTime(2026, 11, 12),
                  tersimpan: false,
                  onSimpan: () {},
                  onBuka: () => dibuka = true,
                ),
              ),
            ),
          ),
        );
        expect(find.text('Beasiswa Uji'), findsOneWidget);
        expect(find.text('Hampir memenuhi'), findsOneWidget);
        expect(find.text('Jenjang S1 sesuai'), findsOneWidget);
        expect(find.text('Catatan kekurangan'), findsOneWidget);
        expect(find.textContaining('Tersisa 6 hari'), findsOneWidget);
        for (final w in t.widgetList<Text>(find.byType(Text))) {
          expect(w.data ?? '', isNot(matches(_larangan)));
        }
        await t.tap(find.text('Lihat detail'));
        expect(dibuka, isTrue);
      },
    );
  });

  group('Masuk', () {
    testWidgets('validasi form sebelum mengirim', (t) async {
      final s = ServerPalsu(_rutePokok());
      await _pasang(t, s, masuk: false);
      expect(find.text('Masuk ke Akun SMART'), findsOneWidget);
      await t.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await t.pump();
      expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
      expect(s.hitung('POST /auth/login'), 0);
    });

    testWidgets('kredensial salah menampilkan pesan server', (t) async {
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'POST /auth/login': (o) => Balasan.galat(
              401,
              'INVALID_CREDENTIALS',
              'Email atau kata sandi salah.',
            ),
          },
        ),
      );
      await _pasang(t, s, masuk: false);
      await t.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.id');
      await t.enterText(
        find.widgetWithText(TextFormField, 'Kata sandi'),
        'salahsekali',
      );
      await t.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await t.pumpAndSettle();
      expect(find.text('Email atau kata sandi salah.'), findsOneWidget);
    });

    testWidgets('masuk berhasil membuka Beranda', (t) async {
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'POST /auth/login': (o) => Balasan.ok({
              'token_akses': 'a',
              'token_penyegar': 'p',
              'kedaluwarsa_detik': 900,
            }),
          },
        ),
      );
      await _pasang(t, s, masuk: false);
      await t.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.id');
      await t.enterText(
        find.widgetWithText(TextFormField, 'Kata sandi'),
        'rahasia123',
      );
      await t.tap(find.widgetWithText(FilledButton, 'Masuk'));
      await t.pumpAndSettle();
      expect(find.text('Halo, Nabila'), findsOneWidget);
    });
  });

  group('Beranda', () {
    testWidgets('menampilkan sapaan, metrik, pilihan utama, dan tenggat', (
      t,
    ) async {
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'GET /rekomendasi': (o) => Balasan.ok([
              {
                'beasiswa': beasiswaJson(
                  '1',
                  'Beasiswa Unggulan',
                  tenggat: _hariKe(6),
                ),
                'kategori': 'memenuhi',
                'alasan': ['IPK memenuhi batas minimum'],
                'catatan_kekurangan': <String>[],
                'tenggat': _hariKe(6),
              },
            ]),
            'GET /me/kalender': (o) => Balasan.ok([
              {
                'jenis': 'tenggat',
                'tanggal': _hariKe(6),
                'judul': 'Beasiswa Unggulan',
                'ref_id': '1',
                'selesai': false,
              },
            ]),
          },
        ),
      );
      await _pasang(t, s);
      expect(find.text('Halo, Nabila'), findsOneWidget);
      expect(find.text('Memenuhi'), findsOneWidget);
      expect(find.text('Hampir memenuhi'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Tenggat pendaftaran'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Beasiswa Unggulan'), findsWidgets);
      expect(find.text('IPK memenuhi batas minimum'), findsOneWidget);
      for (final w in t.widgetList<Text>(find.byType(Text))) {
        expect(w.data ?? '', isNot(matches(_larangan)));
      }
    });

    testWidgets('galat jaringan menampilkan coba lagi dan pulih', (t) async {
      var gagal = true;
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'GET /rekomendasi/ringkasan': (o) => gagal
                ? Balasan.putus()
                : Balasan.ok({
                    'memenuhi': 1,
                    'hampir_memenuhi': 0,
                    'belum_memenuhi': 0,
                  }),
          },
        ),
      );
      await _pasang(t, s);
      expect(find.text('Coba lagi'), findsWidgets);
      gagal = false;
      await t.ensureVisible(find.text('Coba lagi').first);
      await t.tap(find.text('Coba lagi').first);
      await t.pumpAndSettle();
      expect(find.text('Memenuhi'), findsOneWidget);
    });
  });

  group('Jelajah', () {
    testWidgets('daftar, kosong, dan galat dengan coba lagi', (t) async {
      var mode = 'galat';
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'GET /beasiswa': (o) {
              if (mode == 'galat') return Balasan.putus();
              if (mode == 'kosong') return Balasan.ok([]);
              return Balasan.ok(
                [
                  beasiswaJson('1', 'Beasiswa Satu', tenggat: _hariKe(10)),
                  beasiswaJson('2', 'Beasiswa Dua', tenggat: _hariKe(20)),
                ],
                meta: {'kursor_berikut': null},
              );
            },
          },
        ),
      );
      await _pasang(t, s);
      await _tab(t, 'Jelajah');
      expect(find.textContaining('Tidak dapat terhubung'), findsOneWidget);
      mode = 'ok';
      await t.tap(find.text('Coba lagi'));
      await t.pumpAndSettle();
      expect(find.text('Beasiswa Satu'), findsOneWidget);
      expect(find.text('Beasiswa Dua'), findsOneWidget);
      expect(find.text('Menampilkan 2 beasiswa'), findsOneWidget);
    });

    testWidgets(
      'filter jenjang memanggil API dengan parameter dan paginasi kursor',
      (t) async {
        final s = ServerPalsu(
          _rutePokok(
            tambahan: {
              'GET /beasiswa': (o) {
                final kursor = o.queryParameters['kursor'];
                if (kursor == 'k1') {
                  return Balasan.ok(
                    [beasiswaJson('3', 'Beasiswa Tiga')],
                    meta: {'kursor_berikut': null},
                  );
                }
                return Balasan.ok(
                  [beasiswaJson('1', 'Beasiswa Satu')],
                  meta: {'kursor_berikut': 'k1'},
                );
              },
            },
          ),
        );
        await _pasang(t, s);
        await _tab(t, 'Jelajah');
        expect(find.text('Beasiswa Satu'), findsOneWidget);

        await t.ensureVisible(find.text('S2'));
        await t.tap(find.text('S2'));
        await t.pumpAndSettle();
        expect(s.terakhir('GET /beasiswa').queryParameters['jenjang'], 'S2');

        await t.scrollUntilVisible(
          find.text('Muat beasiswa lainnya'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(find.text('Muat beasiswa lainnya'));
        await t.pumpAndSettle();
        expect(find.text('Beasiswa Tiga'), findsOneWidget);
        expect(find.text('Muat beasiswa lainnya'), findsNothing);
      },
    );

    testWidgets('keadaan kosong menjelaskan langkah berikutnya', (t) async {
      final s = ServerPalsu(_rutePokok());
      await _pasang(t, s);
      await _tab(t, 'Jelajah');
      expect(find.text('Belum ada beasiswa yang sesuai'), findsOneWidget);
    });
  });

  group('Rekomendasi', () {
    testWidgets('kartu memuat kategori, alasan, dan catatan kekurangan', (
      t,
    ) async {
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'GET /rekomendasi': (o) => Balasan.ok([
              {
                'beasiswa': beasiswaJson(
                  '2',
                  'Beasiswa Hampir',
                  tenggat: _hariKe(12),
                ),
                'kategori': 'hampir_memenuhi',
                'alasan': ['Jenjang S1 sesuai'],
                'catatan_kekurangan': [
                  'Perlu skor TOEFL 500, skor saat ini 470',
                ],
                'tenggat': _hariKe(12),
              },
            ]),
          },
        ),
      );
      await _pasang(t, s);
      await _tab(t, 'Rekomendasi');
      expect(find.text('Beasiswa Hampir'), findsOneWidget);
      expect(
        find.text('Perlu skor TOEFL 500, skor saat ini 470'),
        findsOneWidget,
      );
      expect(find.text('Semua (7)'), findsOneWidget);
      await t.ensureVisible(find.text('Hampir memenuhi (1)'));
      await t.tap(find.text('Hampir memenuhi (1)'));
      await t.pumpAndSettle();
      expect(
        s.terakhir('GET /rekomendasi').queryParameters['kategori'],
        'hampir_memenuhi',
      );
    });
  });

  group('Kalender dan checklist', () {
    testWidgets('mencentang berkas mengirim PUT dan memuat ulang', (t) async {
      var selesai = false;
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'GET /me/checklist': (o) => Balasan.ok([
              {
                'beasiswa': beasiswaJson(
                  '1',
                  'Beasiswa Satu',
                  tenggat: _hariKe(9),
                ),
                'berkas': [
                  {
                    'id': 'b1',
                    'nama_berkas': 'Transkrip nilai',
                    'selesai': selesai,
                  },
                ],
              },
            ]),
            'PUT /me/checklist/b1': (o) {
              selesai = (o.data as Map)['selesai'] as bool;
              return Balasan.ok({'selesai': selesai});
            },
          },
        ),
      );
      await _pasang(t, s);
      await _tab(t, 'Kalender');
      await t.scrollUntilVisible(
        find.text('Transkrip nilai'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('Transkrip nilai'));
      await t.pumpAndSettle();
      expect(s.hitung('PUT /me/checklist/b1'), 1);
      expect(selesai, isTrue);
      expect(find.text('1/1 siap'), findsOneWidget);
    });
  });

  group('Profil dan notifikasi', () {
    testWidgets('profil menampilkan data dan menyimpan perubahan', (t) async {
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'PUT /me/profil': (o) =>
                Balasan.ok({...penggunaJson(), 'kampus': 'Kampus Baru'}),
          },
        ),
      );
      await _pasang(t, s);
      await _tab(t, 'Profil');
      expect(find.text('Universitas Contoh'), findsOneWidget);
      await t.tap(find.text('Ubah profil'));
      await t.pumpAndSettle();
      await t.enterText(
        find.widgetWithText(TextFormField, 'Kampus'),
        'Kampus Baru',
      );
      await t.enterText(find.widgetWithText(TextFormField, 'IPK'), '5');
      await t.ensureVisible(find.text('Simpan perubahan'));
      await t.tap(find.text('Simpan perubahan'));
      await t.pumpAndSettle();
      expect(find.textContaining('IPK harus berupa angka'), findsOneWidget);
      expect(s.hitung('PUT /me/profil'), 0);
      await t.enterText(find.widgetWithText(TextFormField, 'IPK'), '3,8');
      await t.ensureVisible(find.text('Simpan perubahan'));
      await t.tap(find.text('Simpan perubahan'));
      await t.pumpAndSettle();
      expect(s.terakhir('PUT /me/profil').data['ipk'], 3.8);
      expect(find.text('Kampus Baru'), findsOneWidget);
    });

    testWidgets('notifikasi: daftar dan tandai semua dibaca', (t) async {
      var dibaca = false;
      final s = ServerPalsu(
        _rutePokok(
          tambahan: {
            'GET /notifikasi': (o) => Balasan.ok([
              {
                'id': 'n1',
                'jenis': 'tenggat',
                'dibaca': dibaca,
                'tanggal_acuan': _hariKe(3),
                'judul': 'Tenggat 3 hari lagi',
                'pesan': 'Beasiswa Satu ditutup segera.',
                'beasiswa_id': '1',
              },
            ]),
            'PUT /notifikasi/baca-semua': (o) {
              dibaca = true;
              return Balasan.ok({});
            },
          },
        ),
      );
      await _pasang(t, s);
      await t.tap(find.byTooltip('Notifikasi'));
      await t.pumpAndSettle();
      expect(find.text('Tenggat 3 hari lagi'), findsOneWidget);
      await t.tap(find.text('Tandai semua dibaca'));
      await t.pumpAndSettle();
      expect(s.hitung('PUT /notifikasi/baca-semua'), 1);
      expect(find.text('Tandai semua dibaca'), findsNothing);
    });
  });
}
