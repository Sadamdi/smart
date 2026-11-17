import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/api_client.dart';
import 'package:smart_mobile/core/cache_lokal.dart';
import 'package:smart_mobile/core/token_storage.dart';

import 'helpers.dart';

void main() {
  test('GET disimpan lalu dibaca dari cache saat jaringan putus', () async {
    final tmp = Directory.systemTemp.createTempSync('cache_uji');
    addTearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });
    var putus = false;
    final s = ServerPalsu({
      'GET /rekomendasi': (_) => putus
          ? Balasan.putus()
          : Balasan.ok([
              {'id': 'a'},
            ]),
      'POST /tulis': (_) => Balasan.putus(),
    });
    final dio = Dio(
      BaseOptions(baseUrl: 'http://x/api/v1', validateStatus: (_) => true),
    )..httpClientAdapter = s;
    final cache = CacheLokal(tmp);
    final c = ApiClient(
      dio: dio,
      storage: MemoryTokenStorage(
        const PasanganToken(akses: 't', penyegar: 'r'),
      ),
      cache: cache,
    );
    expect((await c.get('/rekomendasi')).data, [
      {'id': 'a'},
    ]);
    expect(cache.luring.value, isFalse);

    putus = true;
    final r = await c.get('/rekomendasi');
    expect(r.data, [
      {'id': 'a'},
    ]);
    expect(cache.luring.value, isTrue);

    // Tulis tidak pernah dilayani dari cache.
    await expectLater(c.post('/tulis'), throwsA(isA<ApiException>()));

    await cache.bersihkan();
    await expectLater(c.get('/rekomendasi'), throwsA(isA<ApiException>()));
  });
}
