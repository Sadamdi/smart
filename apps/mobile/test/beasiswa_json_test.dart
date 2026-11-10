import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/features/beasiswa/domain/beasiswa.dart';

void main() {
  test('BeasiswaRingkas fromJson lalu toJson', () {
    final j = {
      'id': '1',
      'nama': 'Beasiswa Uji',
      'penyelenggara': 'Yayasan',
      'negara': 'Indonesia',
      'jenjang': ['S1', 'S2'],
      'tenggat': '2026-12-01',
      'tautan_resmi': 'https://uji.id',
    };
    final b = BeasiswaRingkas.fromJson(j);
    expect(b.toJson(), j);
    expect(BeasiswaRingkas.fromJson(b.toJson()).jenjang, 'S1, S2');
  });

  test('BeasiswaDetail fromJson lalu toJson', () {
    final j = {
      'id': '1',
      'nama': 'Beasiswa Uji',
      'penyelenggara': null,
      'negara': null,
      'jenjang': ['S1'],
      'tenggat': null,
      'tautan_resmi': 'https://uji.id',
      'manfaat': 'UKT dan uang saku',
      'tanggal_diperiksa': '2026-11-01',
      'persyaratan': [
        {
          'jenis': 'ipk_minimum',
          'nilai_batas': {'ipk': 3.5},
          'dapat_dikejar': true,
          'status': 'terpenuhi',
          'catatan': null,
        },
      ],
      'berkas_wajib': [
        {'id': 'x', 'nama_berkas': 'KTP'},
      ],
      'kategori': 'memenuhi',
      'alasan': ['IPK sesuai'],
      'catatan_kekurangan': <String>[],
    };
    final d = BeasiswaDetail.fromJson(j);
    expect(d.toJson(), j);
    expect(d.persyaratan.single.toJson()['jenis'], 'ipk_minimum');
    expect(d.berkasWajib.single.toJson(), {'id': 'x', 'nama_berkas': 'KTP'});
  });
}
