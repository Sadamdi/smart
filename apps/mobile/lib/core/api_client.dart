import 'package:dio/dio.dart';

/// Galat dari server dengan bentuk baku { success: false, error: { code, message } }.
class ApiException implements Exception {
  ApiException(this.code, this.message, this.status);

  final String code;
  final String message;
  final int status;

  @override
  String toString() => 'ApiException($code, $status): $message';
}

/// Alamat API diberikan lewat --dart-define=API_BASE_URL=...
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api/v1', // alamat host dari emulator Android
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
