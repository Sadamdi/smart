import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/api_client.dart';
import 'package:smart_mobile/core/lokal/mesin_lokal.dart';
import 'package:smart_mobile/core/token_storage.dart';

import 'helpers.dart';

Map<String, dynamic> _b(
  String id,
  String nama,
  List syarat, {
  bool luar = false,
  String? tenggat,
}) => {
  'id': id,
  'nama': nama,
  'penyelenggara': 'Yayasan Uji',
  'negara': luar ? 'Jepang' : 'Indonesia',
  'jenjang': ['S1'],
  'tenggat': tenggat,
  'tautan_resmi': 'https://contoh.id/$id',
  'manfaat': null,
  'syarat': syarat,
  'luar_negeri': luar,
  'dasar_statistik': null,
  'tingkat': null,
};

Future<MesinLokal> _siap(Directory tmp) async {
  final m = MesinLokal(tmp, false);
  await m.muat(
    teksWilayah: File('assets/data/wilayah.json').readAsStringSync(),
  );
  final depan = DateTime.now()
      .add(const Duration(days: 30))
      .toIso8601String()
      .substring(0, 10);
  await m.simpanSinkron(
    beasiswa: [
      _b('a', 'Beasiswa Prestasi', [
        [
          'ipk_minimum',
          {'nilai': 3.0},
        ],
        [
          'jenjang',
          {
            'nilai': ['S1'],
          },
        ],
      ], tenggat: depan),
      _b('b', 'Beasiswa Tinggi', [
        [
          'ipk_minimum',
          {'nilai': 3.9},
        ],
        [
          'jenjang',
          {
            'nilai': ['S1'],
          },
        ],
      ], tenggat: depan),
      _b(
        'c',
        'Beasiswa Jepang',
        [
          [
            'ipk_minimum',
            {'nilai': 3.0},
          ],
        ],
        luar: true,
        tenggat: depan,
      ),
    ],
    profil: {'ipk': '3.50', 'jenjang': 'S1', 'semester': 5},
    tersimpan: {},
    berkas: {},
  );
  return m;
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('mesin_uji'));
  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    try {
      tmp.deleteSync(recursive: true);
    } on Object {
      // berkas masih ditulis; folder sementara dibersihkan sistem
    }
  });

  test(
    'rekomendasi, ringkasan, dan filter wilayah dihitung di perangkat',
    () async {
      final m = await _siap(tmp);
      final r = m.layaniGet('/rekomendasi', {'urut': 'peluang'})!.data as List;
      expect(r, hasLength(3));
      expect((r.first as Map)['kategori'], 'memenuhi');
      final ring =
          m.layaniGet('/rekomendasi/ringkasan', {'wilayah': 'luar'})!.data
              as Map;
      expect(
        ring['memenuhi'] + ring['hampir_memenuhi'] + ring['belum_memenuhi'],
        1,
      );
      final luar =
          m.layaniGet('/rekomendasi', {'wilayah': 'luar', 'batas': 1})!.data
              as List;
      expect(luar, hasLength(1));
    },
  );

  test(
    'ubah profil saat luring langsung mengubah hasil dan masuk antrean',
    () async {
      final m = await _siap(tmp);
      final sebelum =
          (m.layaniGet('/rekomendasi/ringkasan', null)!.data
              as Map)['memenuhi'];
      m.layaniTulis('PUT', '/me/profil', {'ipk': 2.0});
      m.layaniTulis('PUT', '/me/profil', {'semester': 6});
      final sesudah =
          (m.layaniGet('/rekomendasi/ringkasan', null)!.data
              as Map)['memenuhi'];
      expect(sesudah, lessThan(sebelum));
      expect(m.menunggu.value, 1, reason: 'perubahan profil beruntun digabung');
      expect(m.antrean.first['b'], {'ipk': 2.0, 'semester': 6});
    },
  );

  test(
    'simpan lalu batal simpan saling meniadakan dan chatbot lokal menjawab',
    () async {
      final m = await _siap(tmp);
      m.layaniTulis('POST', '/beasiswa/a/interaksi', {'aksi': 'simpan'});
      expect(
        ((m.layaniGet('/me/tersimpan', null)!.data as List).single
            as Map)['beasiswa']['id'],
        'a',
      );
      m.layaniTulis('DELETE', '/beasiswa/a/interaksi/simpan', null);
      expect(m.layaniGet('/me/tersimpan', null)!.data, isEmpty);
      expect(m.menunggu.value, 1);
      final j =
          m.layaniTulis('POST', '/chat', {
                'pesan': 'kapan tenggat beasiswa?',
              })!.data
              as Map;
      expect(j['jawaban'], contains('bukan jaminan'));
    },
  );

  test(
    'data tersimpan dimuat ulang dan antrean dikirim saat jaringan kembali',
    () async {
      final m = await _siap(tmp);
      m.layaniTulis('POST', '/beasiswa/a/interaksi', {'aksi': 'simpan'});
      final m2 = MesinLokal(tmp, false);
      await m2.muat(
        teksWilayah: File('assets/data/wilayah.json').readAsStringSync(),
      );
      expect(m2.siap, isTrue);
      expect(m2.menunggu.value, 1);
      final terkirim = <String>[];
      await m2.kosongkanAntrean((met, j, b) async => terkirim.add('$met $j'));
      expect(terkirim, ['POST /beasiswa/a/interaksi']);
      expect(m2.menunggu.value, 0);
    },
  );

  test(
    'ApiClient memakai mesin luring saat jaringan putus dan mengantre tulisan',
    () async {
      final m = await _siap(tmp);
      final s = ServerPalsu({
        'GET /rekomendasi/ringkasan': (_) => Balasan.putus(),
        'POST /beasiswa/a/interaksi': (_) => Balasan.putus(),
      });
      final dio = Dio(
        BaseOptions(baseUrl: 'http://x/api/v1', validateStatus: (_) => true),
      )..httpClientAdapter = s;
      final c = ApiClient(
        dio: dio,
        storage: MemoryTokenStorage(
          const PasanganToken(akses: 't', penyegar: 'r'),
        ),
        lokal: m,
      );
      final r = await c.get('/rekomendasi/ringkasan');
      expect((r.data as Map)['memenuhi'], greaterThan(0));
      await c.post('/beasiswa/a/interaksi', body: {'aksi': 'simpan'});
      expect(m.menunggu.value, 1);
      expect(jsonEncode(m.antrean), contains('simpan'));
      // Dokumen (unggah berkas) tidak bisa dilayani luring: galat jaringan tetap muncul.
      await expectLater(c.get('/me/dokumen'), throwsA(isA<ApiException>()));
    },
  );
}
