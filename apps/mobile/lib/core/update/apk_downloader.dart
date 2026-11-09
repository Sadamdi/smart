import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'update_config.dart';

/// Penyebab unduhan pembaruan gagal; masing-masing dipetakan ke pesan yang jelas.
enum UpdateFailure {
  /// Alamat unduhan bukan HTTPS dari GitHub.
  hostDitolak,

  /// Selesai diunduh tetapi SHA-256 tidak sama dengan yang tercantum di manifest.
  corrupted,

  /// Tetap tidak ada koneksi setelah semua percobaan ulang.
  network,

  /// Rilis sudah dicabut atau diganti sehingga berkas tidak ada lagi.
  tidakAda,
}

class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.reason);
  final UpdateFailure reason;
  @override
  String toString() => 'UpdateDownloadException($reason)';
}

/// Mengunduh APK ke `<target>.part`, melanjutkan dengan permintaan HTTP `Range` setiap kali koneksi putus
/// (pindah Wi-Fi ke data, sinyal lemah), lalu memeriksa SHA-256 sebelum mengganti nama menjadi [target].
class ApkDownloader {
  ApkDownloader({
    Dio? dio,
    this.retryDelays = _defaultDelays,
    this.cekHost = hostPembaruanDiizinkan,
  }) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Jeda antarpercobaan; total sekitar 5 menit sebelum menyerah.
  final List<Duration> retryDelays;

  /// Pemeriksa alamat; diganti pada uji dengan server lokal.
  final bool Function(Uri) cekHost;

  static const _defaultDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 60),
    Duration(seconds: 90),
  ];

  Future<File> download({
    required String url,
    required File target,
    required String expectedSha256,
    required void Function(int received, int total) onProgress,
    void Function(bool waiting)? onWaitingForNetwork,
    CancelToken? cancelToken,
  }) async {
    if (!cekHost(Uri.parse(url))) {
      throw const UpdateDownloadException(UpdateFailure.hostDitolak);
    }
    final part = File('${target.path}.part');
    // Sudah pernah diunduh tetapi pemasang ditutup: pakai ulang selama masih utuh.
    if (await target.exists()) {
      final digest = await sha256.bind(target.openRead()).first;
      if (digest.toString() == expectedSha256.toLowerCase()) {
        final size = await target.length();
        onProgress(size, size);
        return target;
      }
      await target.delete();
    }
    var attempt = 0;
    var waiting = false;
    // Byte pertama setelah putus berarti koneksi kembali.
    void progress(int received, int total) {
      if (waiting) {
        waiting = false;
        onWaitingForNetwork?.call(false);
      }
      onProgress(received, total);
    }

    while (true) {
      try {
        await _fetchRemaining(url, part, progress, cancelToken);
        onWaitingForNetwork?.call(false);
        break;
      } on _MulaiUlang {
        if (await part.exists()) await part.delete();
        continue;
      } on UpdateDownloadException {
        rethrow;
      } catch (e) {
        // Putus di tengah badan respons muncul sebagai HttpException atau SocketException, bukan DioException:
        // keduanya berarti "lanjutkan".
        if (e is DioException && CancelToken.isCancel(e)) rethrow;
        if (attempt >= retryDelays.length) {
          throw const UpdateDownloadException(UpdateFailure.network);
        }
        waiting = true;
        onWaitingForNetwork?.call(true);
        debugPrint('[update] unduhan terputus ($e), percobaan ${attempt + 1}');
        await Future<void>.delayed(retryDelays[attempt++]);
      }
    }

    final digest = await sha256.bind(part.openRead()).first;
    if (digest.toString() != expectedSha256.toLowerCase()) {
      await part.delete();
      throw const UpdateDownloadException(UpdateFailure.corrupted);
    }
    if (await target.exists()) await target.delete();
    return part.rename(target.path);
  }

  Future<void> _fetchRemaining(
    String url,
    File part,
    void Function(int, int) onProgress,
    CancelToken? cancelToken,
  ) async {
    final already = await part.exists() ? await part.length() : 0;
    final response = await _dio.get<ResponseBody>(
      url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        headers: {if (already > 0) 'Range': 'bytes=$already-'},
        // Jaringan lambat tidak boleh diputus oleh batas waktu; hanya sambungan mati yang diputus (lalu dilanjutkan).
        receiveTimeout: const Duration(seconds: 45),
        validateStatus: (_) => true,
      ),
    );
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      await response.data!.stream.drain<void>();
      throw _kegagalan(status);
    }
    final resumed = status == 206;
    final start = resumed ? already : 0;
    final length =
        int.tryParse(
          response.headers.value(Headers.contentLengthHeader) ?? '',
        ) ??
        -1;
    final total = length < 0 ? -1 : start + length;

    final sink = part.openWrite(
      mode: resumed ? FileMode.append : FileMode.write,
    );
    var received = start;
    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Object _kegagalan(int status) {
    if (status == 416) return const _MulaiUlang();
    if (status == 404 || status == 410) {
      return const UpdateDownloadException(UpdateFailure.tidakAda);
    }
    // 5xx dan lainnya diperlakukan seperti koneksi putus: coba lagi.
    return DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.badResponse,
    );
  }
}

class _MulaiUlang implements Exception {
  const _MulaiUlang();
}
