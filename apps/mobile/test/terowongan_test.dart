import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/api_client.dart';
import 'package:smart_mobile/core/terowongan.dart';
import 'package:smart_mobile/core/token_storage.dart';

import 'helpers.dart';

// Vektor emas dari server Python (`app/core/terowongan.py`): kunci server 0x11*32, kunci sementara klien 0x22*32.
const _serverPub = 'e06Qm75//kTEZaIgA31gjuNYl9Me+XLwf3SJLLD3PxM=';
const _k = 'D6poTtKIZ7l_Smot7l34zpdOdrcBjj8iocTPJnhXDyA';
const _n = 'MzMzMzMzMzMzMzMz';
const _c =
    'IK40h8FamwpsfIPy5H5JRpSkBPwt-iOAXX-1B8scfBh67EYSyIADzgveq2N4qB1HIC6ZrSXWHWWhQH93UOtcOSrPCSv84KWq3KZbzuoMNcPzZZQbdKSNNZz0QUwqOQZclIDJE38';
const _nJawab = 'RERERERERERERERE';
const _cJawab =
    'h89tC1PGDb4gInMkuwg8_AydRsfkwp6LYqWfVmdXXNkn9UveaCDP4gPMyodgoB2DIAJp6uFCeuCj5oOIkIVIBctT9zEmFUGUbLRabC_6LhmOe_AoPsko21j_';

class _Tetap implements Random {
  _Tetap(this.nilai);
  final int nilai;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => nilai;
}

String _b64u(List<int> b) => base64Url.encode(b).replaceAll('=', '');
List<int> _unb64u(String t) => base64Url.decode(base64Url.normalize(t));

/// Sisi server dalam Dart: membuka amplop dengan kunci privat server, menjalankan "aplikasi", menyegel jawaban.
class _ServerTerowongan {
  _ServerTerowongan(this.aplikasi);

  final Balasan Function(
    String metode,
    String url,
    Map<String, dynamic> header,
    String? isi,
  )
  aplikasi;
  final dilihat = <Map<String, dynamic>>[];
  final seed = List<int>.filled(32, 0x11);

  Future<Balasan> tangani(RequestOptions o) async {
    final amplop = o.data as Map;
    final pair = await X25519().newKeyPairFromSeed(seed);
    final pub = (await pair.extractPublicKey()).bytes;
    final klien = _unb64u(amplop['k'] as String);
    final bersama = await X25519().sharedSecretKey(
      keyPair: pair,
      remotePublicKey: SimplePublicKey(klien, type: KeyPairType.x25519),
    );
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final garam = [...klien, ...pub];
    final kBadan = await hkdf.deriveKey(
      secretKey: bersama,
      nonce: garam,
      info: utf8.encode('smart/v1/body'),
    );
    final kJawab = await hkdf.deriveKey(
      secretKey: bersama,
      nonce: garam,
      info: utf8.encode('smart/v1/response'),
    );
    final data = _unb64u(amplop['c'] as String);
    final polos = await AesGcm.with256bits().decrypt(
      SecretBox(
        data.sublist(0, data.length - 16),
        nonce: _unb64u(amplop['n'] as String),
        mac: Mac(data.sublist(data.length - 16)),
      ),
      secretKey: kBadan,
      aad: utf8.encode('sm2|tun|${amplop['kid']}|${amplop['k']}'),
    );
    final dalam = jsonDecode(utf8.decode(polos)) as Map<String, dynamic>;
    dilihat.add(dalam);
    final r = aplikasi(
      dalam['m'] as String,
      dalam['u'] as String,
      Map<String, dynamic>.from(dalam['h'] as Map),
      dalam['b'] as String?,
    );
    final iv = List<int>.generate(12, (i) => i + 1);
    final kotak = await AesGcm.with256bits().encrypt(
      utf8.encode(
        jsonEncode({
          's': r.status,
          'h': {'content-type': 'application/json'},
          'b': jsonEncode(r.body),
        }),
      ),
      secretKey: kJawab,
      nonce: iv,
      aad: utf8.encode('sm2|tun|res|${amplop['n']}'),
    );
    return Balasan(200, {
      'v': 1,
      'n': _b64u(iv),
      'c': _b64u([...kotak.cipherText, ...kotak.mac.bytes]),
    });
  }
}

Dio _dio(ServerPalsu s) =>
    Dio(BaseOptions(baseUrl: 'http://x/api/v1', validateStatus: (_) => true))
      ..httpClientAdapter = s;

void main() {
  test('amplop sama persis dengan vektor emas server Python dan jawabannya terbuka', () async {
    final s = ServerPalsu({
      'POST /secure': (o) {
        final d = o.data as Map;
        expect(d['k'], _k);
        expect(d['n'], _n);
        expect(d['c'], _c);
        expect(d['kid'], 'k1');
        return Balasan(200, {'v': 1, 'n': _nJawab, 'c': _cJawab});
      },
    });
    final t = Terowongan(
      dio: _dio(s),
      kid: 'k1',
      kunciPublikServer: base64.decode(_serverPub),
      pasanganBaru: () =>
          X25519().newKeyPairFromSeed(List<int>.filled(32, 0x22)),
      sekarangMs: () => 1800000000000,
      acak: _Tetap(0x33),
    );
    final h = await t.kirim('GET', '/me', query: {'x': 1}, token: 'abc');
    expect(h, isNotNull);
    expect(h!.status, 200);
    expect(h.json, isTrue);
    expect(h.teks, '{"success":true}');
  });

  test('ApiClient lewat terowongan: token, isi JSON, dan galat 401 dengan penyegaran', () async {
    var tokenSah = 'baru';
    final srv = _ServerTerowongan((m, u, h, isi) {
      if (u == '/api/v1/auth/refresh') {
        return Balasan.ok({'token_akses': 'baru', 'token_penyegar': 'p2'});
      }
      if (h['Authorization'] != 'Bearer $tokenSah') {
        return Balasan.galat(401, 'UNAUTHORIZED', 'x');
      }
      if (m == 'POST') return Balasan.ok({'gema': jsonDecode(isi!)});
      return Balasan.ok({'u': u});
    });
    final s = ServerPalsu({'POST /secure': srv.tangani});
    final dio = _dio(s);
    final api = ApiClient(
      dio: dio,
      storage: MemoryTokenStorage(
        const PasanganToken(akses: 'lama', penyegar: 'p1'),
      ),
      terowongan: Terowongan(
        dio: dio,
        kid: 'k1',
        kunciPublikServer: base64.decode(_serverPub),
      ),
    );
    final r = await api.get('/me', query: {'a': 'b', 'kosong': ''});
    expect(
      (r.data as Map)['u'],
      '/api/v1/me?a=b',
    ); // lewat terowongan, jalur penuh, token disegarkan
    final p = await api.post('/chat', body: {'pesan': 'halo'});
    expect(((p.data as Map)['gema'] as Map)['pesan'], 'halo');
    // di luar amplop tidak ada jalur, token, atau isi
    for (final o in s.permintaan) {
      expect(o.path, '/secure');
      expect('${o.data}', isNot(contains('halo')));
      expect('${o.data}', isNot(contains('Bearer')));
    }
    expect(
      srv.dilihat.first['h'],
      containsPair('Authorization', 'Bearer lama'),
    );
  });

  test('server belum mendukung: terowongan mati sendiri dan permintaan jatuh ke TLS biasa', () async {
    final s = ServerPalsu({
      'POST /secure': (o) =>
          Balasan.galat(400, 'SECURE_CHANNEL_UNAVAILABLE', 'belum aktif'),
      'GET /me': (o) => Balasan.ok({'ok': true}),
    });
    final dio = _dio(s);
    final t = Terowongan(
      dio: dio,
      kid: 'k1',
      kunciPublikServer: base64.decode(_serverPub),
    );
    final api = ApiClient(
      dio: dio,
      storage: MemoryTokenStorage(
        const PasanganToken(akses: 'a', penyegar: 'p'),
      ),
      terowongan: t,
    );
    expect(((await api.get('/me')).data as Map)['ok'], true);
    expect(t.aktif, isFalse);
    await api.get('/me');
    expect(
      s.hitung('POST /secure'),
      1,
    ); // tidak mencoba lagi pada proses yang sama
  });

  test('jam ponsel meleset: server menyebut waktunya, aplikasi menyesuaikan lalu mengulang satu kali', () async {
    var panggilan = 0;
    final srv = _ServerTerowongan((m, u, h, isi) => Balasan.ok({'ok': true}));
    final s = ServerPalsu({
      'POST /secure': (o) {
        panggilan++;
        if (panggilan == 1) {
          return Balasan(400, {
            'success': false,
            'error': {
              'code': 'SECURE_CHANNEL_STALE',
              'message': 'x',
              'details': {
                'serverTime':
                    DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
              },
            },
          });
        }
        return srv.tangani(o);
      },
    });
    final dio = _dio(s);
    final t = Terowongan(
      dio: dio,
      kid: 'k1',
      kunciPublikServer: base64.decode(_serverPub),
    );
    final h = await t.kirim('GET', '/me');
    expect(h!.status, 200);
    expect(panggilan, 2);
    expect(t.selisihDetik, greaterThan(3000));
  });

  test('alamat dasar berawalan proksi (/backend/api/v1): jalur dalam amplop tetap /api/v1', () async {
    final srv = _ServerTerowongan((m, u, h, isi) => Balasan.ok({'u': u}));
    final s = ServerPalsu({'POST /secure': srv.tangani});
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://smart-web-three.vercel.app/backend/api/v1',
        validateStatus: (_) => true,
      ),
    )..httpClientAdapter = s;
    final t = Terowongan(
      dio: dio,
      kid: 'k1',
      kunciPublikServer: base64.decode(_serverPub),
    );
    final h = await t.kirim('GET', '/me', query: {'a': '1'});
    expect(jsonDecode(h!.teks)['data']['u'], '/api/v1/me?a=1');
    expect(
      s.permintaan.single.uri.toString(),
      'https://smart-web-three.vercel.app/backend/api/v1/secure',
    );
  });
}
