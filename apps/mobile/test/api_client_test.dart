import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/api_client.dart';

void main() {
  test('ambilData mengembalikan isi data pada respons sukses', () {
    final data = ambilData<Map<String, dynamic>>({
      'success': true,
      'data': {'status': 'hidup'},
    }, 200);
    expect(data['status'], 'hidup');
  });

  test('ambilData melempar ApiException dengan kode dari server', () {
    expect(
      () => ambilData<Map<String, dynamic>>({
        'success': false,
        'error': {'code': 'NOT_FOUND', 'message': 'Tidak ditemukan'},
      }, 404),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NOT_FOUND')),
    );
  });

  test('ambilData melempar INTERNAL bila isi tidak dikenali', () {
    expect(
      () => ambilData<dynamic>(null, 500),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'INTERNAL')),
    );
  });
}
