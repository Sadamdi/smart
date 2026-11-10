import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:smart_mobile/core/api_client.dart';
import 'package:smart_mobile/core/dependensi.dart';
import 'package:smart_mobile/core/token_storage.dart';
import 'package:smart_mobile/main.dart';

/// Balasan palsu: status dan isi JSON, atau galat jaringan.
class Balasan {
  Balasan(this.status, this.body, {this.jaringan = false});

  factory Balasan.ok(Object? data, {Map<String, dynamic>? meta}) =>
      Balasan(200, {'success': true, 'data': data, 'meta': meta});

  factory Balasan.galat(int status, String code, String pesan) =>
      Balasan(status, {
        'success': false,
        'error': {'code': code, 'message': pesan},
      });

  factory Balasan.putus() => Balasan(0, null, jaringan: true);

  final int status;
  final Object? body;
  final bool jaringan;
}

typedef Penangan = FutureOr<Balasan> Function(RequestOptions o);

/// Server palsu berbasis adaptor Dio; tidak ada koneksi jaringan.
class ServerPalsu implements HttpClientAdapter {
  ServerPalsu(this.rute);

  /// Kunci: "METODE /jalur" tanpa query.
  final Map<String, Penangan> rute;
  final permintaan = <RequestOptions>[];

  /// Permintaan terakhir untuk kunci "METODE /jalur".
  RequestOptions terakhir(String kunci) =>
      permintaan.lastWhere((o) => '${o.method} ${o.path}' == kunci);

  int hitung(String kunci) =>
      permintaan.where((o) => '${o.method} ${o.path}' == kunci).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    permintaan.add(options);
    final h = rute['${options.method} ${options.path}'];
    if (h == null) {
      throw DioException(
        requestOptions: options,
        message: 'rute tidak dikenal ${options.method} ${options.path}',
      );
    }
    final b = await h(options);
    if (b.jaringan) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(b.body),
      b.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiClient klienPalsu(
  ServerPalsu s,
  TokenStorage storage, {
  void Function()? onSesiBerakhir,
}) {
  final dio = Dio(
    BaseOptions(baseUrl: 'http://x/api/v1', validateStatus: (_) => true),
  )..httpClientAdapter = s;
  return ApiClient(dio: dio, storage: storage, onSesiBerakhir: onSesiBerakhir);
}

Map<String, dynamic> penggunaJson({
  String nama = 'Nabila Putri',
  bool lengkap = true,
}) => {
  'id': '11111111-1111-1111-1111-111111111111',
  'email': 'nabila@kampus.ac.id',
  'peran': 'mahasiswa',
  'nama': nama,
  'kampus': lengkap ? 'Universitas Contoh' : null,
  'jenis_kampus': lengkap ? 'negeri' : null,
  'program_studi': lengkap ? 'Teknik Informatika' : null,
  'jenjang': lengkap ? 'S1' : null,
  'semester': lengkap ? 5 : null,
  'ipk': lengkap ? '3.80' : null,
  'kota_domisili': lengkap ? 'Malang' : null,
  'negara_domisili': 'Indonesia',
  'provinsi_domisili': lengkap ? 'Jawa Timur' : null,
  'minat': lengkap ? ['riset'] : <String>[],
  'preferensi_notifikasi': {'email': true, 'push': true},
};

/// Respons GET /referensi/wilayah (ringkas, bentuk sama dengan API asli).
Map<String, dynamic> wilayahJson() => {
  'negara': ['Indonesia', 'Malaysia', 'Singapura', 'Brunei Darussalam'],
  'provinsi': [
    'Aceh',
    'Jawa Timur',
    'DI Yogyakarta',
    'Kepulauan Bangka Belitung',
    'Papua Pegunungan',
  ],
  'negara_asal': 'Indonesia',
};

Map<String, dynamic> beasiswaJson(String id, String nama, {String? tenggat}) =>
    {
      'id': id,
      'nama': nama,
      'penyelenggara': 'Penyelenggara $id',
      'negara': 'Indonesia',
      'jenjang': 'S1',
      'tenggat': tenggat,
      'tautan_resmi': 'https://contoh.ac.id/$id',
    };

Dio dioPalsu(ServerPalsu s) =>
    Dio(BaseOptions(baseUrl: 'http://x/api/v1', validateStatus: (_) => true))
      ..httpClientAdapter = s;

/// Mengosongkan GetX sebelum dan sesudah tiap tes agar tidak ada controller yang bocor antar tes.
/// Panggil sekali di awal `main()` tiap berkas tes yang memakai [aplikasi] atau [pasangGetUji].
void siapkanGet() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);
}

/// Memasang semua dependensi GetX dengan Dio palsu dan penyimpanan token di memori.
void pasangGetUji(
  ServerPalsu s, {
  TokenStorage? storage,
  Future<bool> Function(Uri)? bukaTautan,
}) {
  Get.testMode = true;
  Get.reset();
  pasangDependensi(
    dio: dioPalsu(s),
    storage: storage ?? MemoryTokenStorage(),
    bukaTautan: bukaTautan,
  );
}

/// Aplikasi lengkap dengan server palsu dan token tersimpan.
Widget aplikasi(ServerPalsu s, {bool sudahMasuk = true}) {
  pasangGetUji(
    s,
    storage: MemoryTokenStorage(
      sudahMasuk ? const PasanganToken(akses: 'a', penyegar: 'p') : null,
    ),
  );
  return const SmartApp(googleFonts: false, pembuka: false);
}
