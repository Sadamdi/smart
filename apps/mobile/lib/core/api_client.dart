import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'cache_lokal.dart';
import 'lokal/mesin_lokal.dart';
import 'token_storage.dart';

/// Galat dari server dengan bentuk baku { success: false, error: { code, message } }.
class ApiException implements Exception {
  ApiException(this.code, this.message, this.status);

  final String code;
  final String message;
  final int status;

  bool get galatJaringan => code == 'NETWORK';

  @override
  String toString() => 'ApiException($code, $status): $message';
}

/// Alamat API diberikan lewat --dart-define=API_BASE_URL=...
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue:
      'http://10.0.2.2:8000/api/v1', // alamat host dari emulator Android
);

/// Membaca isi `data` dari respons baku, atau melempar [ApiException].
T ambilData<T>(Map<String, dynamic>? body, int status) {
  if (body != null && body['success'] == true) {
    return body['data'] as T;
  }
  final error = body?['error'];
  if (error is Map<String, dynamic>) {
    throw ApiException(
      (error['code'] ?? 'INTERNAL') as String,
      (error['message'] ?? 'Terjadi kesalahan pada server.') as String,
      status,
    );
  }
  throw ApiException('INTERNAL', 'Terjadi kesalahan pada server.', status);
}

Dio buatDio({String? baseUrl}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl ?? apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (_) => true,
    ),
  );
}

/// Hasil respons baku: isi `data` dan `meta` (mis. kursor paginasi).
class Respons {
  const Respons(this.data, this.meta);

  final dynamic data;
  final Map<String, dynamic>? meta;
}

/// Klien API: menyisipkan token akses, menyegarkan token otomatis satu kali
/// ketika menerima 401, dan menerjemahkan galat jaringan menjadi [ApiException].
class ApiClient {
  ApiClient({
    required this.dio,
    required this.storage,
    this.onSesiBerakhir,
    this.cache,
    this.lokal,
  });

  /// Cache data terakhir untuk mode luring (baca saja); null bila tidak dipakai.
  final CacheLokal? cache;

  /// Mesin luring (hitung dan simpan di perangkat); null bila tidak dipakai.
  final MesinLokal? lokal;

  final Dio dio;
  final TokenStorage storage;

  /// Dipanggil bila penyegaran gagal; aplikasi kembali ke layar masuk.
  void Function()? onSesiBerakhir;

  Future<bool>? _sedangMenyegarkan;

  static const _jalurAuth = ['/auth/login', '/auth/register', '/auth/refresh'];

  Future<Respons> get(String jalur, {Map<String, dynamic>? query}) async {
    final l = lokal;
    if (l != null && l.aktif.value) {
      final r = l.layaniGet(jalur, query);
      if (r != null) return r;
      // Mode luring aktif: tidak menghubungi server SMART. Pakai salinan terakhir bila ada.
      final kunci = '$jalur?${jsonEncode(query ?? const {})}';
      final salinan = await cache?.baca(kunci);
      if (salinan != null && !_jalurAuth.contains(jalur)) {
        final meta = salinan['meta'];
        return Respons(
          salinan['data'],
          meta is Map<String, dynamic> ? meta : null,
        );
      }
      throw ApiException(
        'LURING',
        'Mode luring aktif. Data ini belum tersedia di ponsel; matikan mode luring untuk memuatnya.',
        0,
      );
    }
    try {
      return await _getJaringan(jalur, query);
    } on ApiException catch (e) {
      if (!e.galatJaringan || l == null) rethrow;
      final r = l.layaniGet(jalur, query);
      if (r == null) rethrow;
      cache?.luring.value = true;
      return r;
    }
  }

  Future<Respons> _getJaringan(
    String jalur,
    Map<String, dynamic>? query,
  ) async {
    final c = cache;
    if (c == null || _jalurAuth.contains(jalur)) {
      return _kirim('GET', jalur, query: query);
    }
    final kunci = '$jalur?${jsonEncode(query ?? const {})}';
    try {
      final r = await _kirim('GET', jalur, query: query);
      c.luring.value = false;
      unawaited(c.simpan(kunci, r.data, r.meta));
      _kirimAntreanBilaPerlu();
      return r;
    } on ApiException catch (e) {
      if (!e.galatJaringan) rethrow;
      // Mesin luring lebih dulu: hasilnya dihitung ulang dari profil terbaru, bukan salinan lama.
      if (lokal?.layaniGet(jalur, query) != null) rethrow;
      final m = await c.baca(kunci);
      if (m == null) rethrow;
      c.luring.value = true;
      final meta = m['meta'];
      return Respons(m['data'], meta is Map<String, dynamic> ? meta : null);
    }
  }

  Future<Respons> post(String jalur, {Object? body}) =>
      _tulis('POST', jalur, body);

  Future<Respons> put(String jalur, {Object? body}) =>
      _tulis('PUT', jalur, body);

  Future<Respons> patch(String jalur, {Object? body}) =>
      _tulis('PATCH', jalur, body);

  Future<Respons> delete(String jalur) => _tulis('DELETE', jalur, null);

  /// Penulisan: dilayani lokal saat mode luring (dan masuk antrean), atau saat jaringan putus bila datanya sudah ada.
  Future<Respons> _tulis(String metode, String jalur, Object? body) async {
    final l = lokal;
    if (l != null && l.aktif.value && body is! FormData) {
      final r = l.layaniTulis(metode, jalur, body);
      if (r != null) return r;
    }
    if (l != null &&
        l.aktif.value &&
        !_jalurAuth.contains(jalur) &&
        jalur != '/chat') {
      throw ApiException(
        'LURING',
        'Mode luring aktif. Fitur ini butuh server; matikan mode luring untuk memakainya.',
        0,
      );
    }
    try {
      return await _kirim(metode, jalur, body: body);
    } on ApiException catch (e) {
      if (!e.galatJaringan || l == null || body is FormData) rethrow;
      final r = l.layaniTulis(metode, jalur, body);
      if (r == null) rethrow;
      cache?.luring.value = true;
      return r;
    }
  }

  bool _mengantre = false;

  void _kirimAntreanBilaPerlu() {
    final l = lokal;
    if (l == null || l.aktif.value || l.menunggu.value == 0 || _mengantre) {
      return;
    }
    unawaited(sinkronkan());
  }

  /// Mengirim perubahan yang tertunda lalu mengunduh paket data terbaru untuk dipakai saat luring.
  Future<bool> sinkronkan() async {
    final l = lokal;
    if (l == null || _mengantre) return false;
    _mengantre = true;
    l.sedangSinkron.value = true;
    try {
      await l.kosongkanAntrean((m, j, b) => _kirim(m, j, body: b));
      if (l.menunggu.value > 0) return false;
      final beasiswa = (await _kirim('GET', '/beasiswa/sinkron')).data as List;
      final profil = (await _kirim('GET', '/me')).data as Map<String, dynamic>;
      final tersimpan = (await _kirim('GET', '/me/tersimpan')).data as List;
      final dokumen = (await _kirim('GET', '/me/dokumen')).data as List;
      await l.simpanSinkron(
        beasiswa: [
          for (final x in beasiswa) Map<String, dynamic>.from(x as Map),
        ],
        profil: Map<String, dynamic>.from(profil),
        tersimpan: {
          for (final x in tersimpan)
            ((x as Map)['beasiswa'] as Map)['id'] as String,
        },
        berkas: {
          for (final x in dokumen) ...[
            (x as Map)['jenis'] as String,
            x['nama_berkas'] as String,
          ],
        },
      );
      return true;
    } on ApiException {
      return false;
    } finally {
      _mengantre = false;
      l.sedangSinkron.value = false;
    }
  }

  /// Membuka aliran SSE (POST) dan menghasilkan pasangan (peristiwa, data). Membatalkan langganan atau [batal] memutus
  /// koneksi sehingga server menghentikan jawaban. Token disegarkan satu kali bila 401.
  Stream<(String, String)> alirSse(
    String jalur,
    Object? body, {
    CancelToken? batal,
  }) async* {
    Future<Response<ResponseBody>> buka(String? token) =>
        dio.post<ResponseBody>(
          jalur,
          data: body,
          cancelToken: batal,
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: const Duration(minutes: 5),
            headers: {
              'Accept': 'text/event-stream',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ),
        );
    Response<ResponseBody> res;
    try {
      res = await buka((await storage.baca())?.akses);
      if (res.statusCode == 401 && await _segarkan()) {
        res = await buka((await storage.baca())?.akses);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      throw ApiException(
        'NETWORK',
        'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.',
        0,
      );
    }
    if (res.statusCode != 200) {
      final teks = await utf8.decodeStream(res.data!.stream);
      Map<String, dynamic>? b;
      try {
        b = jsonDecode(teks) as Map<String, dynamic>;
      } on Object {
        b = null;
      }
      ambilData<dynamic>(b, res.statusCode ?? 0);
      throw ApiException(
        'INTERNAL',
        'Terjadi kesalahan pada server.',
        res.statusCode ?? 0,
      );
    }
    var sisa = '';
    try {
      await for (final potongan in res.data!.stream.cast<List<int>>().transform(
        utf8.decoder,
      )) {
        sisa += potongan;
        int i;
        while ((i = sisa.indexOf('\n\n')) >= 0) {
          final blok = sisa.substring(0, i);
          sisa = sisa.substring(i + 2);
          var peristiwa = 'message';
          final data = StringBuffer();
          for (final baris in blok.split('\n')) {
            if (baris.startsWith('event:')) {
              peristiwa = baris.substring(6).trim();
            }
            if (baris.startsWith('data:')) {
              data.write(baris.substring(5).trim());
            }
          }
          yield (peristiwa, data.toString());
        }
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      throw ApiException(
        'NETWORK',
        'Koneksi terputus saat menerima jawaban.',
        0,
      );
    }
  }

  /// Mengunduh berkas biner (mis. dokumen asli) ke [simpanKe], dengan token dan satu kali penyegaran.
  Future<void> unduh(String jalur, String simpanKe) async {
    Future<Response<dynamic>> coba(String? token) => dio.download(
      jalur,
      simpanKe,
      options: Options(
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );
    try {
      var res = await coba((await storage.baca())?.akses);
      if (res.statusCode == 401 && await _segarkan()) {
        res = await coba((await storage.baca())?.akses);
      }
      if (res.statusCode != 200) {
        throw ApiException(
          'NOT_FOUND',
          'Berkas asli tidak tersimpan di server.',
          res.statusCode ?? 0,
        );
      }
    } on DioException {
      throw ApiException(
        'NETWORK',
        'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.',
        0,
      );
    }
  }

  Future<Response<dynamic>> _sekali(
    String metode,
    String jalur,
    Map<String, dynamic>? query,
    Object? body,
    String? token,
  ) async {
    try {
      return await dio.request<dynamic>(
        jalur,
        data: body,
        queryParameters: query,
        options: Options(
          method: metode,
          headers: {if (token != null) 'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (e) {
      throw ApiException(
        'NETWORK',
        'Tidak dapat terhubung ke server. Periksa koneksi internet lalu coba lagi.',
        e.response?.statusCode ?? 0,
      );
    }
  }

  Future<Respons> _kirim(
    String metode,
    String jalur, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final bersih = <String, dynamic>{
      for (final e in (query ?? {}).entries)
        if (e.value != null && e.value != '') e.key: e.value,
    };
    final pasang = await storage.baca();
    var res = await _sekali(metode, jalur, bersih, body, pasang?.akses);
    if (res.statusCode == 401 && !_jalurAuth.contains(jalur)) {
      final ok = await _segarkan();
      if (ok) {
        final baru = await storage.baca();
        res = await _sekali(metode, jalur, bersih, body, baru?.akses);
      }
      if (!ok || res.statusCode == 401) {
        await storage.hapus();
        unawaited(cache?.bersihkan());
        onSesiBerakhir?.call();
      }
    }
    final b = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : null;
    final data = ambilData<dynamic>(b, res.statusCode ?? 0);
    final meta = b?['meta'];
    return Respons(data, meta is Map<String, dynamic> ? meta : null);
  }

  /// Satu penyegaran pada satu waktu; permintaan lain menunggu hasilnya.
  Future<bool> _segarkan() {
    return _sedangMenyegarkan ??= _jalankanSegar().whenComplete(
      () => _sedangMenyegarkan = null,
    );
  }

  Future<bool> _jalankanSegar() async {
    final pasang = await storage.baca();
    if (pasang == null) return false;
    try {
      final res = await _sekali('POST', '/auth/refresh', null, {
        'token_penyegar': pasang.penyegar,
      }, null);
      final b = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : null;
      final d = ambilData<Map<String, dynamic>>(b, res.statusCode ?? 0);
      await storage.simpan(
        PasanganToken(
          akses: d['token_akses'] as String,
          penyegar: d['token_penyegar'] as String,
        ),
      );
      return true;
    } on ApiException {
      return false;
    }
  }
}
