import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/lokal/kelayakan.dart';
import 'package:smart_mobile/core/lokal/peluang.dart';
import 'package:smart_mobile/core/lokal/wilayah.dart';

/// Mesin luring di perangkat harus menghasilkan angka yang sama dengan server. Berkas emas dibuat server
/// (apps/backend/scripts/ekspor_lokal.py) dari kode Python yang sebenarnya.
void main() {
  final tabel = TabelWilayah.dariJson(
    jsonDecode(File('assets/data/wilayah.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final emas = jsonDecode(
    File('test/golden_lokal.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final hari = DateTime.parse(emas['hari_ini'] as String);

  ProfilKelayakan profil(Map<String, dynamic> p) => ProfilKelayakan(
    jenjang: p['jenjang'] as String?,
    semester: p['semester'] as int?,
    ipk: (p['ipk'] as num?)?.toDouble(),
    jenisKampus: p['jenis_kampus'] as String?,
    kotaDomisili: p['kota_domisili'] as String?,
    negaraDomisili: p['negara_domisili'] as String?,
    provinsiDomisili: p['provinsi_domisili'] as String?,
    daerahAsal: [...?(p['daerah_asal'] as List?)?.cast<String>()],
    tanggalLahir: p['tanggal_lahir'] == null
        ? null
        : DateTime.parse(p['tanggal_lahir'] as String),
    penghasilanOrangTua: p['penghasilan_orang_tua'] as num?,
    skorBahasa: (p['skor_bahasa'] as Map?)?.cast<String, dynamic>(),
    kewarganegaraan: p['kewarganegaraan'] as String?,
    berkasDiunggah: {...?(p['berkas_diunggah'] as List?)?.cast<String>()},
    jenjangTuju: [...?(p['jenjang_tuju'] as List?)?.cast<String>()],
  );

  test('kelayakan dan estimasi peluang sama dengan server', () {
    final kasus = (emas['kasus'] as List).cast<Map<String, dynamic>>();
    expect(kasus, isNotEmpty);
    final selisih = <String>[];
    for (final k in kasus) {
      final p = k['profil'] as Map<String, dynamic>;
      final syarat = <Syarat>[
        for (final s in (k['syarat'] as List))
          ((s as List)[0] as String, (s[1] as Map?)?.cast<String, dynamic>()),
      ];
      final h = nilaiKelayakan(tabel, syarat, profil(p), hari);
      final e = k['hasil'] as Map<String, dynamic>;
      final m = metrik(h.skor, h.alasan, h.catatan);
      final b = k['beasiswa'] as Map<String, dynamic>;
      final kuat = kekuatanProfil(
        (p['ipk'] as num?)?.toDouble(),
        (k['lanjutan'] as Map?)?.cast<String, dynamic>(),
        (p['skor_bahasa'] as Map?)?.cast<String, dynamic>(),
      );
      final est = estimasiPeluang(
        kategori: h.kategori,
        adaSyaratTerukur: m.total > 0,
        nama: b['nama'] as String,
        penyelenggara: b['penyelenggara'] as String?,
        luarNegeri: b['luar_negeri'] as bool,
        kekuatan: kuat,
        dasarStatistik: (b['dasar_statistik'] as num?)?.toDouble(),
        jumlahSyarat: m.total,
      );
      final em = e['metrik'] as Map<String, dynamic>;
      final ok =
          h.kategori == e['kategori'] &&
          (h.skor - (e['skor'] as num).toDouble()).abs() < 1e-9 &&
          jsonEncode(h.alasan) == jsonEncode(e['alasan']) &&
          jsonEncode(h.catatan) == jsonEncode(e['catatan']) &&
          m.skor == em['skor_kelayakan'] &&
          m.terpenuhi == em['syarat_terpenuhi'] &&
          m.total == em['syarat_total'] &&
          (kuat - (e['kekuatan'] as num).toDouble()).abs() < 1e-9 &&
          est == e['estimasi'];
      if (!ok) {
        selisih.add(
          '${jsonEncode(k['syarat'])} | $p\n  dart: ${h.kategori} ${h.skor} ${h.alasan} ${h.catatan} $est\n  py:   ${e['kategori']} ${e['skor']} ${e['alasan']} ${e['catatan']} ${e['estimasi']}',
        );
      }
    }
    expect(
      selisih,
      isEmpty,
      reason:
          '${selisih.length} dari ${kasus.length} kasus berbeda:\n${selisih.take(5).join('\n')}',
    );
  });
}
