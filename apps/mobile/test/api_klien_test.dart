import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/api_client.dart';
import 'package:smart_mobile/core/token_storage.dart';
import 'package:smart_mobile/features/beasiswa/data/beasiswa_repository.dart';
import 'package:smart_mobile/features/rekomendasi/data/rekomendasi_repository.dart';
import 'package:smart_mobile/features/rekomendasi/domain/rekomendasi.dart';

import 'helpers.dart';

void main() {
  group('ApiClient', () {
    test('menyisipkan token akses dan membuka amplop data', () async {
      final s = ServerPalsu({
        'GET /me': (o) => Balasan.ok({'nama': 'A'}),
      });
      final c = klienPalsu(
        s,
        MemoryTokenStorage(const PasanganToken(akses: 'tok1', penyegar: 'r1')),
      );
      final r = await c.get('/me');
      expect((r.data as Map)['nama'], 'A');
      expect(s.permintaan.single.headers['Authorization'], 'Bearer tok1');
    });

    test('membuang parameter kosong dari query', () async {
      final s = ServerPalsu({'GET /beasiswa': (o) => Balasan.ok([])});
      final c = klienPalsu(s, MemoryTokenStorage());
      await c.get('/beasiswa', query: {'q': '', 'jenjang': null, 'batas': 5});
      expect(s.permintaan.single.queryParameters, {'batas': 5});
    });

    test('401 menyegarkan token sekali lalu mengulang permintaan', () async {
      var panggilan = 0;
      final s = ServerPalsu({
        'GET /me': (o) {
          panggilan++;
          return o.headers['Authorization'] == 'Bearer baru'
              ? Balasan.ok({'ok': true})
              : Balasan.galat(401, 'UNAUTHORIZED', 'kedaluwarsa');
        },
        'POST /auth/refresh': (o) {
          expect(o.data, {'token_penyegar': 'r1'});
          return Balasan.ok({
            'token_akses': 'baru',
            'token_penyegar': 'r2',
            'kedaluwarsa_detik': 900,
          });
        },
      });
      final storage = MemoryTokenStorage(
        const PasanganToken(akses: 'lama', penyegar: 'r1'),
      );
      final c = klienPalsu(s, storage);
      final r = await c.get('/me');
      expect((r.data as Map)['ok'], true);
      expect(panggilan, 2);
      expect(s.hitung('POST /auth/refresh'), 1);
      final t = await storage.baca();
      expect(t!.akses, 'baru');
      expect(t.penyegar, 'r2');
    });

    test('permintaan serentak berbagi satu penyegaran', () async {
      final s = ServerPalsu({
        'GET /a': (o) => o.headers['Authorization'] == 'Bearer baru'
            ? Balasan.ok(1)
            : Balasan.galat(401, 'UNAUTHORIZED', 'x'),
        'GET /b': (o) => o.headers['Authorization'] == 'Bearer baru'
            ? Balasan.ok(2)
            : Balasan.galat(401, 'UNAUTHORIZED', 'x'),
        'POST /auth/refresh': (o) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return Balasan.ok({
            'token_akses': 'baru',
            'token_penyegar': 'r2',
            'kedaluwarsa_detik': 900,
          });
        },
      });
      final c = klienPalsu(
        s,
        MemoryTokenStorage(const PasanganToken(akses: 'lama', penyegar: 'r1')),
      );
      final hasil = await Future.wait([c.get('/a'), c.get('/b')]);
      expect([hasil[0].data, hasil[1].data], [1, 2]);
      expect(s.hitung('POST /auth/refresh'), 1);
    });

    test(
      'penyegaran gagal menghapus token dan memberi tahu aplikasi',
      () async {
        var berakhir = 0;
        final s = ServerPalsu({
          'GET /me': (o) => Balasan.galat(401, 'UNAUTHORIZED', 'x'),
          'POST /auth/refresh': (o) =>
              Balasan.galat(401, 'UNAUTHORIZED', 'penyegar tidak valid'),
        });
        final storage = MemoryTokenStorage(
          const PasanganToken(akses: 'lama', penyegar: 'r1'),
        );
        final c = klienPalsu(s, storage, onSesiBerakhir: () => berakhir++);
        await expectLater(c.get('/me'), throwsA(isA<ApiException>()));
        expect(berakhir, 1);
        expect(await storage.baca(), isNull);
        expect(
          s.hitung('GET /me'),
          1,
          reason: 'tidak diulang tanpa token baru',
        );
      },
    );

    test('401 pada login tidak memicu penyegaran', () async {
      final s = ServerPalsu({
        'POST /auth/login': (o) => Balasan.galat(
          401,
          'INVALID_CREDENTIALS',
          'Email atau kata sandi salah',
        ),
      });
      final c = klienPalsu(s, MemoryTokenStorage());
      await expectLater(
        c.post('/auth/login', body: {}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'INVALID_CREDENTIALS',
          ),
        ),
      );
      expect(s.hitung('POST /auth/refresh'), 0);
    });

    test(
      'galat jaringan menjadi ApiException NETWORK berbahasa Indonesia',
      () async {
        final s = ServerPalsu({'GET /me': (o) => Balasan.putus()});
        final c = klienPalsu(s, MemoryTokenStorage());
        await expectLater(
          c.get('/me'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.galatJaringan, 'jaringan', true)
                .having((e) => e.message, 'pesan', contains('terhubung')),
          ),
        );
      },
    );
  });

  group('Repositori', () {
    test('daftar beasiswa membaca kursor berikutnya dan item', () async {
      final s = ServerPalsu({
        'GET /beasiswa': (o) => Balasan.ok(
          [beasiswaJson('1', 'Beasiswa Satu', tenggat: '2026-12-01')],
          meta: {'kursor_berikut': 'abc'},
        ),
      });
      final repo = BeasiswaRepository(klienPalsu(s, MemoryTokenStorage()));
      final h = await repo.daftar(q: 'satu', jenjang: 'S1', kursor: 'k0');
      expect(h.items.single.nama, 'Beasiswa Satu');
      expect(h.items.single.tenggat, DateTime(2026, 12, 1));
      expect(h.kursorBerikut, 'abc');
      expect(s.permintaan.single.queryParameters, {
        'q': 'satu',
        'jenjang': 'S1',
        'kursor': 'k0',
        'batas': 10,
      });
    });

    test('detail membaca persyaratan dan berkas wajib', () async {
      final s = ServerPalsu({
        'GET /beasiswa/1': (o) => Balasan.ok({
          ...beasiswaJson('1', 'Satu'),
          'manfaat': 'Biaya kuliah',
          'tanggal_diperiksa': '2026-11-01',
          'persyaratan': [
            {
              'jenis': 'ipk_minimum',
              'nilai_batas': {'nilai': 3.0},
              'dapat_dikejar': true,
            },
          ],
          'berkas_wajib': [
            {'id': 'b1', 'nama_berkas': 'Transkrip'},
          ],
        }),
      });
      final d = await BeasiswaRepository(klienPalsu(s, MemoryTokenStorage()))
          .detail('1');
      expect(d.persyaratan.single.label, 'IPK minimum');
      expect(d.persyaratan.single.nilai, '3.0');
      expect(d.berkasWajib.single.namaBerkas, 'Transkrip');
    });

    test('simpan dan hapus simpan memakai jalur interaksi', () async {
      final s = ServerPalsu({
        'POST /beasiswa/1/interaksi': (o) =>
            Balasan.ok({'id': 'i', 'aksi': 'simpan'}),
        'DELETE /beasiswa/1/interaksi/simpan': (o) => Balasan.ok({}),
      });
      final repo = BeasiswaRepository(klienPalsu(s, MemoryTokenStorage()));
      await repo.simpan('1');
      await repo.hapusSimpan('1');
      expect(s.permintaan.first.data, {'aksi': 'simpan'});
      expect(s.hitung('DELETE /beasiswa/1/interaksi/simpan'), 1);
    });

    test('rekomendasi memetakan kategori, alasan, dan catatan', () async {
      final s = ServerPalsu({
        'GET /rekomendasi': (o) => Balasan.ok([
          {
            'beasiswa': beasiswaJson('1', 'Satu'),
            'kategori': 'hampir_memenuhi',
            'alasan': ['Jenjang sesuai'],
            'catatan_kekurangan': ['IPK kurang 0,10 dari syarat 3,50'],
            'tenggat': null,
          },
        ]),
      });
      final r = await RekomendasiRepository(klienPalsu(s, MemoryTokenStorage()))
          .daftar(kategori: Kategori.hampirMemenuhi);
      expect(r.single.kategori, Kategori.hampirMemenuhi);
      expect(r.single.catatanKekurangan.single, contains('IPK kurang'));
      expect(s.permintaan.single.queryParameters, {
        'kategori': 'hampir_memenuhi',
      });
    });
  });
}
