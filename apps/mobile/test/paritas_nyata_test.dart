import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/lokal/mesin_lokal.dart';

/// Membandingkan mesin luring dengan hasil server pada data dan profil nyata (diambil 18 November 2026).
void main() {
  test('kategori, estimasi, dan syarat sama dengan server pada profil nyata', () async {
    final tmp = Directory.systemTemp.createTempSync('nyata');
    final m = MesinLokal(tmp, false);
    await m.muat(teksWilayah: File('assets/data/wilayah.json').readAsStringSync());
    final data = jsonDecode(File('test/sinkron_nyata.json').readAsStringSync()) as List;
    final acuan = jsonDecode(File('test/paritas_nyata.json').readAsStringSync()) as Map<String, dynamic>;
    await m.simpanSinkron(
      beasiswa: [for (final x in data) Map<String, dynamic>.from(x as Map)],
      profil: Map<String, dynamic>.from(acuan['profil'] as Map),
      tersimpan: {},
      berkas: {...(acuan['berkas'] as List).cast<String>()},
    );
    // Hari acuan: server memakai tanggal hitung 18 November 2026.
    final lokal = m.hitung(DateTime(2026, 11, 18));
    final hasil = (acuan['hasil'] as Map<String, dynamic>);
    var beda = <String>[];
    for (final x in lokal) {
      final s = hasil[x.b['id']] as List?;
      if (s == null) {
        beda.add('${x.b['nama']}: tidak ada di server');
        continue;
      }
      if (x.h.kategori != s[0] || x.estimasi != s[1] || x.m.terpenuhi != s[2] || x.m.total != s[3]) {
        beda.add('${x.b['nama']}: lokal ${x.h.kategori} ${x.estimasi} ${x.m.terpenuhi}/${x.m.total} | server ${s.join(' ')}');
      }
    }
    expect(lokal.length, hasil.length);
    expect(beda, isEmpty, reason: '${beda.length} berbeda:\n${beda.take(8).join('\n')}');
  });
}
