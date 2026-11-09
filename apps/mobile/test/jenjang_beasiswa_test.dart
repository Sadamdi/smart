import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/features/beasiswa/domain/beasiswa.dart';

void main() {
  group('jenjang beasiswa dari API (daftar)', () {
    test('daftar jenjang digabung menjadi teks', () {
      final b = BeasiswaRingkas.fromJson({
        'id': '1',
        'nama': 'Beasiswa Uji',
        'jenjang': ['S1', 'S2'],
        'tenggat': null,
        'tautan_resmi': 'https://contoh.id',
      });
      expect(b.jenjang, 'S1, S2');
      expect(b.tenggat, isNull);
    });

    test('jenjang null atau kosong tidak membuat galat', () {
      expect(teksJenjang(null), isNull);
      expect(teksJenjang(<String>[]), isNull);
      expect(teksJenjang('S1'), 'S1');
    });
  });
}
