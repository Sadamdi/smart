import 'package:dio/dio.dart';

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
  ApiClient({required this.dio, required this.storage, this.onSesiBerakhir});

  final Dio dio;
  final TokenStorage storage;

  /// Dipanggil bila penyegaran gagal; aplikasi kembali ke layar masuk.
  void Function()? onSesiBerakhir;

  Future<bool>? _sedangMenyegarkan;

  static const _jalurAuth = ['/auth/login', '/auth/register', '/auth/refresh'];

  Future<Respons> get(String jalur, {Map<String, dynamic>? query}) =>
      _kirim('GET', jalur, query: query);

  Future<Respons> post(String jalur, {Object? body}) =>
      _kirim('POST', jalur, body: body);

  Future<Respons> put(String jalur, {Object? body}) =>
      _kirim('PUT', jalur, body: body);

  Future<Respons> delete(String jalur) => _kirim('DELETE', jalur);

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
