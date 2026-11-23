import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpDate;
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

/// Kunci publik X25519 server (bukan rahasia) dan id-nya. Diberikan lewat --dart-define bila kunci diganti.
const terowonganKunciPublik = String.fromEnvironment(
  'SECURE_PUBLIC_KEY',
  defaultValue: '/bSwF/ax8NjzkEH0Q5Arj3dUVc97LOVuO2/8p3K0cV8=',
);
const terowonganKid = String.fromEnvironment(
  'SECURE_KEY_ID',
  defaultValue: 'k1',
);

/// Hasil satu panggilan lewat terowongan: status, header, dan isi jawaban sebenarnya dari server.
class HasilTerowongan {
  const HasilTerowongan(this.status, this.header, this.badan);

  final int status;
  final Map<String, String> header;
  final List<int> badan;

  String get tipe => header['content-type'] ?? '';
  bool get json => tipe.contains('application/json');
  String get teks => utf8.decode(badan, allowMalformed: true);
}

/// Terowongan terenkripsi tingkat aplikasi di atas TLS (sisi server: `app/core/terowongan.py`).
///
/// Hanya kunci PUBLIK server yang ada di aplikasi. Tiap sesi membuat pasangan kunci X25519 sementara dan
/// kedua sisi menurunkan kunci AES-256-GCM yang sama dengan HKDF-SHA256. Setiap panggilan menjadi satu
/// `POST /secure` berisi amplop; metode, jalur, token, dan isi sebenarnya hanya ada di dalamnya, begitu pula jawabannya.
/// Bila server belum mengaktifkannya (atau jalurnya tidak ada), terowongan mematikan diri dan aplikasi memakai TLS biasa.
class Terowongan {
  Terowongan({
    required this.dio,
    required this.kid,
    required List<int> kunciPublikServer,
    this.umurSesi = const Duration(minutes: 10),
    Future<SimpleKeyPair> Function()? pasanganBaru,
    int Function()? sekarangMs,
    Random? acak,
  }) : _publikServer = List<int>.unmodifiable(kunciPublikServer),
       _pasanganBaru = pasanganBaru ?? (() => X25519().newKeyPair()),
       _sekarangMs =
           sekarangMs ?? (() => DateTime.now().millisecondsSinceEpoch),
       _acak = acak ?? Random.secure();

  static const versi = 1;
  static const jalur = '/secure';
  static const _tag = 16;
  static const _nonce = 12;

  final Dio dio;
  final String kid;
  final Duration umurSesi;
  final List<int> _publikServer;
  final Future<SimpleKeyPair> Function() _pasanganBaru;
  final int Function() _sekarangMs;
  final Random _acak;

  /// Mati sendiri bila server tidak mendukung; tidak pernah menyala lagi pada proses yang sama.
  bool aktif = true;

  /// Jam server dikurangi jam ponsel, dalam detik.
  int selisihDetik = 0;

  Future<_Sesi>? _sesi;
  int _mulaiSesi = 0;

  int get _sekarang => _sekarangMs() + selisihDetik * 1000;

  Future<_Sesi> _ambilSesi() {
    final n = _sekarangMs();
    final s = _sesi;
    if (s != null && n - _mulaiSesi < umurSesi.inMilliseconds) return s;
    _mulaiSesi = n;
    return _sesi = _buatSesi();
  }

  Future<_Sesi> _buatSesi() async {
    final pasangan = await _pasanganBaru();
    final publik = await pasangan.extractPublicKey();
    final bersama = await X25519().sharedSecretKey(
      keyPair: pasangan,
      remotePublicKey: SimplePublicKey(_publikServer, type: KeyPairType.x25519),
    );
    final garam = [...publik.bytes, ..._publikServer];
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    Future<SecretKey> turunkan(String info) => hkdf.deriveKey(
      secretKey: bersama,
      nonce: garam,
      info: utf8.encode('smart/v1/$info'),
    );
    return _Sesi(
      publikB64: _b64u(publik.bytes),
      badan: await turunkan('body'),
      jawaban: await turunkan('response'),
    );
  }

  static String aadPermintaan(String kid, String k) => 'sm2|tun|$kid|$k';
  static String aadJawaban(String nonce) => 'sm2|tun|res|$nonce';

  Future<({String n, String c})> segel(
    SecretKey kunci,
    List<int> polos,
    String aad, {
    List<int>? nonce,
  }) async {
    final iv = nonce ?? List<int>.generate(_nonce, (_) => _acak.nextInt(256));
    final kotak = await AesGcm.with256bits().encrypt(
      polos,
      secretKey: kunci,
      nonce: iv,
      aad: utf8.encode(aad),
    );
    return (n: _b64u(iv), c: _b64u([...kotak.cipherText, ...kotak.mac.bytes]));
  }

  Future<List<int>> buka(SecretKey kunci, String n, String c, String aad) {
    final iv = _unb64u(n);
    final data = _unb64u(c);
    if (iv.length != _nonce || data.length < _tag) {
      throw const FormatException('amplop rusak');
    }
    return AesGcm.with256bits().decrypt(
      SecretBox(
        data.sublist(0, data.length - _tag),
        nonce: iv,
        mac: Mac(data.sublist(data.length - _tag)),
      ),
      secretKey: kunci,
      aad: utf8.encode(aad),
    );
  }

  /// Mengirim satu permintaan lewat terowongan. Mengembalikan null bila terowongan tidak tersedia
  /// (pemanggil memakai TLS biasa). Galat jaringan dilempar sebagai [DioException].
  Future<HasilTerowongan?> kirim(
    String metode,
    String jalurApi, {
    Map<String, dynamic>? query,
    Object? body,
    String? token,
    CancelToken? batal,
    bool ulangiWaktu = true,
  }) async {
    if (!aktif) return null;
    final uriDasar = Uri.parse(dio.options.baseUrl);
    final qs = <String, String>{
      for (final e in (query ?? {}).entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    final dalam = Uri(
      path: '${_awalanApi(uriDasar.path)}$jalurApi',
      queryParameters: qs.isEmpty ? null : qs,
    );
    final url = dalam.hasQuery ? '${dalam.path}?${dalam.query}' : dalam.path;

    final header = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };
    String? teks;
    List<int>? biner;
    if (body is FormData) {
      final bytes = <int>[];
      // Salinan: satu FormData hanya bisa dibaca sekali, sedangkan permintaan bisa diulang setelah token disegarkan.
      await for (final potongan in body.clone().finalize()) {
        bytes.addAll(potongan);
      }
      biner = bytes;
      header['Content-Type'] = 'multipart/form-data; boundary=${body.boundary}';
    } else if (body is Map || body is List) {
      teks = jsonEncode(body);
      header['Content-Type'] = 'application/json';
    } else if (body is String) {
      teks = body;
    }

    final sesi = await _ambilSesi();
    final dalamJson = jsonEncode({
      't': _sekarang,
      'm': metode.toUpperCase(),
      'u': url,
      'h': header,
      'bx': ?(biner == null ? null : base64.encode(biner)),
      'b': ?(biner == null ? teks : null),
    });
    final tersegel = await segel(
      sesi.badan,
      utf8.encode(dalamJson),
      aadPermintaan(kid, sesi.publikB64),
    );
    final res = await dio.post<dynamic>(
      jalur,
      data: {
        'v': versi,
        'kid': kid,
        'k': sesi.publikB64,
        'n': tersegel.n,
        'c': tersegel.c,
      },
      cancelToken: batal,
      // Unggahan dibaca AI di server (gambar bisa puluhan detik), jadi batas waktunya lebih longgar dari permintaan biasa.
      options: Options(
        contentType: Headers.jsonContentType,
        sendTimeout: biner == null ? null : const Duration(minutes: 3),
        receiveTimeout: biner == null ? null : const Duration(minutes: 3),
      ),
    );
    _selaraskanJam(res);
    final d = res.data;
    final status = res.statusCode ?? 0;

    if (status == 200 && d is Map && d['n'] is String && d['c'] is String) {
      final polos = jsonDecode(
        utf8.decode(
          await buka(
            sesi.jawaban,
            d['n'] as String,
            d['c'] as String,
            aadJawaban(tersegel.n),
          ),
        ),
      ) as Map<String, dynamic>;
      final isiBytes = polos['bx'] is String
          ? base64.decode(polos['bx'] as String)
          : utf8.encode((polos['b'] ?? '') as String);
      return HasilTerowongan((polos['s'] as num).toInt(), {
        for (final e in ((polos['h'] ?? {}) as Map).entries)
          '${e.key}'.toLowerCase(): '${e.value}',
      }, isiBytes);
    }

    final kode = d is Map && d['error'] is Map
        ? (d['error'] as Map)['code']
        : null;
    if (kode == 'SECURE_CHANNEL_UNAVAILABLE' ||
        status == 404 ||
        status == 405) {
      aktif = false; // server belum mendukung: pakai TLS biasa
      return null;
    }
    if (kode == 'SECURE_CHANNEL_STALE' && ulangiWaktu) {
      final det = d is Map ? (d['error'] as Map)['details'] : null;
      if (det is Map && det['serverTime'] is num) {
        selisihDetik =
            (det['serverTime'] as num).toInt() -
            DateTime.now().millisecondsSinceEpoch ~/ 1000;
        _sesi = null;
        return kirim(
          metode,
          jalurApi,
          query: query,
          body: body,
          token: token,
          batal: batal,
          ulangiWaktu: false,
        );
      }
    }
    // Penolakan lain (ulang, amplop tidak sah, 426, gangguan proksi): teruskan apa adanya sebagai jawaban biasa.
    final mentah = d is String ? utf8.encode(d) : utf8.encode(jsonEncode(d));
    return HasilTerowongan(status, {
      'content-type': 'application/json',
    }, mentah);
  }

  /// Jalur API di server: alamat dasar bisa berawalan proksi (mis. /backend/api/v1), tetapi server hanya mengenal /api/v1.
  static String _awalanApi(String pathDasar) {
    final i = pathDasar.indexOf('/api/v1');
    final p = i >= 0 ? pathDasar.substring(i) : pathDasar;
    return p.replaceAll(RegExp(r'/+$'), '');
  }

  /// Memperbaiki jam hanya bila ponsel benar-benar meleset (abaikan jitter jaringan).
  void _selaraskanJam(Response<dynamic> res) {
    final h = res.headers.value('date');
    if (h == null) return;
    try {
      final server = HttpDate.parse(h).millisecondsSinceEpoch ~/ 1000;
      final lokal = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final s = server - lokal;
      selisihDetik = s.abs() > 120 ? s : 0;
    } catch (_) {}
  }

  static String _b64u(List<int> b) => base64Url.encode(b).replaceAll('=', '');
  static List<int> _unb64u(String t) =>
      base64Url.decode(base64Url.normalize(t));
}

class _Sesi {
  const _Sesi({
    required this.publikB64,
    required this.badan,
    required this.jawaban,
  });

  final String publikB64;
  final SecretKey badan;
  final SecretKey jawaban;
}
