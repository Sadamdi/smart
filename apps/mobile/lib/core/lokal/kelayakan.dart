/// Lapis kelayakan mesin rekomendasi di perangkat: sama dengan app/rekomendasi/kelayakan.py di server, supaya mode
/// luring menghasilkan penilaian yang sama. Diuji dengan berkas emas yang dihasilkan server (test/golden_lokal.json).
library;

import 'wilayah.dart';

const memenuhi = 'memenuhi';
const hampir = 'hampir_memenuhi';
const belum = 'belum_memenuhi';

const _ok = 'terpenuhi';
const _toleran = 'dalam_toleransi';
const _gagal = 'gagal';
const _tidakTahu = 'tidak_diketahui';

const _tolIpk = 0.25;
const _tolSemester = 1;
const _tolBahasa = 0.10;

class ProfilKelayakan {
  const ProfilKelayakan({
    this.jenjang,
    this.semester,
    this.ipk,
    this.jenisKampus,
    this.kotaDomisili,
    this.negaraDomisili,
    this.provinsiDomisili,
    this.daerahAsal = const [],
    this.tanggalLahir,
    this.penghasilanOrangTua,
    this.skorBahasa,
    this.kewarganegaraan,
    this.berkasDiunggah = const {},
    this.jenjangTuju = const [],
  });

  final String? jenjang;
  final int? semester;
  final double? ipk;
  final String? jenisKampus;
  final String? kotaDomisili;
  final String? negaraDomisili;
  final String? provinsiDomisili;
  final List<String> daerahAsal;
  final DateTime? tanggalLahir;
  final num? penghasilanOrangTua;
  final Map<String, dynamic>? skorBahasa;
  final String? kewarganegaraan;
  final Set<String> berkasDiunggah;
  final List<String> jenjangTuju;
}

class HasilSyarat {
  HasilSyarat(
    this.jenis,
    this.status,
    this.nilai, {
    this.alasan,
    this.kekurangan,
  });

  final String jenis;
  final String status;
  final double nilai;
  final String? alasan;
  final String? kekurangan;
}

class HasilKelayakan {
  HasilKelayakan(
    this.kategori,
    this.skor,
    this.alasan,
    this.catatan, [
    this.rincian = const [],
  ]);

  /// Penilaian tiap syarat (null bila syarat hanya informasi), sejajar dengan daftar syarat masukan.
  final List<HasilSyarat?> rincian;

  final String kategori;
  final double skor;
  final List<String> alasan;
  final List<String> catatan;
}

typedef Syarat = (String, Map<String, dynamic>?);

/// Pembulatan seperti round() Python: separuh ke genap.
int bulatGenap(double x) {
  final f = x.floorToDouble();
  final d = x - f;
  if (d < 0.5) return f.toInt();
  if (d > 0.5) return f.toInt() + 1;
  return f.toInt().isEven ? f.toInt() : f.toInt() + 1;
}

double bulatDesimal(double x, int n) {
  var p = 1.0;
  for (var i = 0; i < n; i++) {
    p *= 10;
  }
  return bulatGenap(x * p) / p;
}

/// Format ala Python `{x:g}`.
String fmtG(double x) {
  if (x == x.truncateToDouble() && x.abs() < 1e6) return x.toInt().toString();
  var s = x.toStringAsPrecision(6);
  if (s.contains('.') && !s.contains('e')) {
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}

String _f2(double x) => x.toStringAsFixed(2);

int usia(DateTime lahir, DateTime hariIni) {
  final sebelum =
      hariIni.month < lahir.month ||
      (hariIni.month == lahir.month && hariIni.day < lahir.day);
  return hariIni.year - lahir.year - (sebelum ? 1 : 0);
}

double? _angka(Map<String, dynamic>? batas, [String k = 'nilai']) {
  final v = batas?[k];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

List<String> _daftar(Map<String, dynamic>? batas) {
  final v = batas?['nilai'];
  if (v == null) return [];
  if (v is String) return [v];
  if (v is List) return [for (final x in v) '$x'];
  return ['$v'];
}

const jenjangSah = ['D3', 'D4', 'S1', 'S2', 'S3'];

List<Syarat> denganJenjangBeasiswa(
  List<Syarat> syarat,
  List<String>? jenjangBeasiswa,
) {
  final jenjang = [
    for (final x in jenjangBeasiswa ?? <String>[])
      if (jenjangSah.contains(x)) x,
  ];
  final tercatat = syarat.any(
    (s) => s.$1 == 'jenjang' && _daftar(s.$2).isNotEmpty,
  );
  if (tercatat) {
    final diminta = {
      for (final s in syarat)
        if (s.$1 == 'jenjang') ..._daftar(s.$2),
    };
    if (jenjang.isNotEmpty && diminta.intersection(jenjang.toSet()).isEmpty) {
      return [
        ...syarat.where((s) => s.$1 != 'jenjang'),
        ('jenjang', {'nilai': jenjang}),
      ];
    }
    return syarat;
  }
  if (jenjang.isEmpty) return syarat;
  return [
    ...syarat,
    ('jenjang', {'nilai': jenjang}),
  ];
}

HasilSyarat _tidakDiketahui(String jenis, String label) => HasilSyarat(
  jenis,
  _tidakTahu,
  0.5,
  kekurangan: 'Lengkapi $label di profil agar syarat ini dapat diperiksa',
);

HasilSyarat? _ipk(
  String jenis,
  Map<String, dynamic>? batas,
  ProfilKelayakan p,
) {
  final minimum = _angka(batas);
  if (minimum == null) return null;
  final ipk = p.ipk;
  if (ipk == null) return _tidakDiketahui(jenis, 'IPK');
  if (ipk >= minimum) {
    return HasilSyarat(
      jenis,
      _ok,
      1.0,
      alasan: 'IPK ${_f2(ipk)} memenuhi syarat minimum ${_f2(minimum)}',
    );
  }
  final selisih = bulatDesimal(minimum - ipk, 2);
  if (selisih <= _tolIpk) {
    return HasilSyarat(
      jenis,
      _toleran,
      1 - selisih / (_tolIpk * 2),
      kekurangan: 'IPK kurang ${_f2(selisih)} dari syarat ${_f2(minimum)}',
    );
  }
  return HasilSyarat(
    jenis,
    _gagal,
    0.0,
    kekurangan: 'IPK ${_f2(ipk)} di bawah syarat ${_f2(minimum)}',
  );
}

HasilSyarat? _semester(
  String jenis,
  Map<String, dynamic>? batas,
  ProfilKelayakan p,
) {
  final b = _angka(batas);
  if (b == null) return null;
  final sem = p.semester;
  if (sem == null) return _tidakDiketahui(jenis, 'semester');
  if (jenis == 'semester_minimum') {
    if (sem >= b) {
      return HasilSyarat(
        jenis,
        _ok,
        1.0,
        alasan: 'Semester $sem memenuhi batas minimum ${b.truncate()}',
      );
    }
    if ((b - sem).truncate() <= _tolSemester) {
      return HasilSyarat(
        jenis,
        _toleran,
        0.5,
        kekurangan: 'Dapat mendaftar mulai semester ${b.truncate()}',
      );
    }
    return HasilSyarat(
      jenis,
      _gagal,
      0.0,
      kekurangan: 'Syarat semester minimum ${b.truncate()}',
    );
  }
  if (sem <= b) {
    return HasilSyarat(
      jenis,
      _ok,
      1.0,
      alasan: 'Semester $sem dalam batas maksimum ${b.truncate()}',
    );
  }
  return HasilSyarat(
    jenis,
    _gagal,
    0.0,
    kekurangan: 'Melewati batas semester maksimum ${b.truncate()}',
  );
}

HasilSyarat? _pilihan(
  String jenis,
  Map<String, dynamic>? batas,
  String? nilai,
  String label,
  String teksOk,
) {
  final diminta = _daftar(batas);
  if (diminta.isEmpty) return null;
  if (nilai == null || nilai.isEmpty) return _tidakDiketahui(jenis, label);
  final sama = diminta
      .map((d) => d.toLowerCase())
      .contains(nilai.toLowerCase());
  if (sama) {
    return HasilSyarat(
      jenis,
      _ok,
      1.0,
      alasan: teksOk.replaceAll('{nilai}', nilai),
    );
  }
  return HasilSyarat(
    jenis,
    _gagal,
    0.0,
    kekurangan: 'Untuk $label ${diminta.join(', ')}',
  );
}

const _terbuka = [
  'all countries',
  'semua negara',
  'seluruh negara',
  'international',
  'internasional',
  'mancanegara',
];
final _pengecuali = RegExp(r'\b(bukan|selain|kecuali|non|asing|foreign)\b');

String _kanonNegara(String teks) {
  final t = teks.toLowerCase().trim();
  return RegExp(r'\bwni\b|indonesia').hasMatch(t) ? 'indonesia' : t;
}

Wilayah _wilayahProfil(ProfilKelayakan p) => Wilayah(
  negara: p.negaraDomisili,
  provinsi: p.provinsiDomisili,
  kota: p.kotaDomisili,
  tambahan: [
    for (final x in p.daerahAsal)
      if (x.isNotEmpty) x,
  ],
);

List<String> _kata(String s) =>
    s.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

HasilSyarat? _domisiliKhusus(
  TabelWilayah t,
  Map<String, dynamic>? batas,
  ProfilKelayakan p,
) {
  final diminta = _daftar(batas);
  if (diminta.isEmpty) return null;
  for (final d in diminta) {
    final dl = d.toLowerCase().trim();
    if (dl == 'indonesia' ||
        dl == 'wilayah indonesia' ||
        dl == 'seluruh indonesia' ||
        dl.startsWith('berdomisili di indonesia')) {
      final negara = t.negaraKanonik(p.negaraDomisili);
      if (negara != null && negara != t.negaraAsal) {
        return HasilSyarat(
          'domisili',
          _gagal,
          0.0,
          kekurangan: 'Untuk domisili di Indonesia',
        );
      }
      return HasilSyarat(
        'domisili',
        _ok,
        1.0,
        alasan: 'Berdomisili di Indonesia',
      );
    }
    if (dl.startsWith('tidak ') || dl.startsWith('bukan ')) {
      return HasilSyarat(
        'domisili',
        _ok,
        1.0,
        alasan: 'Syarat domisili tidak membatasi domisili Anda',
      );
    }
    if (RegExp(r'pesantren|pondok|sekolah|naungan|organisasi').hasMatch(dl) ||
        _kata(dl).length > 5) {
      return HasilSyarat(
        'domisili',
        _toleran,
        0.7,
        kekurangan: 'Periksa syarat domisili di laman resmi',
      );
    }
  }
  return null;
}

HasilSyarat? _domisili(
  TabelWilayah t,
  Map<String, dynamic>? batas,
  ProfilKelayakan p,
) {
  final diminta = _daftar(batas);
  if (diminta.isEmpty) return null;
  final khusus = _domisiliKhusus(t, batas, p);
  if (khusus != null) return khusus;
  final w = _wilayahProfil(p);
  if (w.kosong) {
    return _tidakDiketahui('domisili', 'negara, provinsi, dan kota domisili');
  }
  final hasil = [for (final d in diminta) cocokWilayah(t, d, w)];
  if (hasil.contains(cocok)) {
    return HasilSyarat(
      'domisili',
      _ok,
      1.0,
      alasan: 'Domisili atau daerah asal sesuai',
    );
  }
  if (hasil.contains(beda)) {
    return HasilSyarat(
      'domisili',
      _gagal,
      0.0,
      kekurangan: 'Untuk domisili ${diminta.join(', ')}',
    );
  }
  return _tidakDiketahui('domisili', 'negara, provinsi, dan kota domisili');
}

HasilSyarat? _warga(String jenis, Map<String, dynamic>? batas, String? nilai) {
  final diminta = _daftar(batas);
  if (diminta.isEmpty) return null;
  if (diminta.any((d) => _terbuka.any((k) => d.toLowerCase().contains(k)))) {
    return HasilSyarat(
      jenis,
      _ok,
      1.0,
      alasan: 'Terbuka untuk berbagai kewarganegaraan',
    );
  }
  if (nilai == null || nilai.isEmpty) {
    return _tidakDiketahui(jenis, 'kewarganegaraan');
  }
  final k = _kanonNegara(nilai);
  final deskriptif = [
    for (final d in diminta)
      if (!_pengecuali.hasMatch(d.toLowerCase()) &&
          (_kata(d).length > 4 ||
              RegExp(r'\b(negara|countries|country|dropdown|daftar|list)\b')
                  .hasMatch(d.toLowerCase())))
        d,
  ];
  for (final d in diminta) {
    final dl = d.toLowerCase();
    if (k != _kanonNegara(d) && !dl.contains(k)) continue;
    if (_pengecuali.hasMatch(dl) && dl.contains(k)) continue;
    return HasilSyarat(jenis, _ok, 1.0, alasan: 'Kewarganegaraan sesuai');
  }
  if (deskriptif.isNotEmpty) {
    return HasilSyarat(
      jenis,
      _toleran,
      0.7,
      kekurangan: 'Periksa daftar negara yang memenuhi syarat di laman resmi',
    );
  }
  return HasilSyarat(
    jenis,
    _gagal,
    0.0,
    kekurangan: 'Untuk warga negara ${diminta.join(', ')}',
  );
}

double? _skorBahasa(Map<String, dynamic>? skor, String nama) {
  for (final e in (skor ?? const <String, dynamic>{}).entries) {
    if (e.key.trim().toLowerCase() != nama) continue;
    final a = double.tryParse('${e.value}'.replaceAll(',', '.').trim());
    if (a == null) return null;
    return (!a.isNaN && a >= 0) ? a : null;
  }
  return null;
}

HasilSyarat? _bahasa(
  String jenis,
  Map<String, dynamic>? batas,
  ProfilKelayakan p,
) {
  final minimum = _angka(batas);
  final nama = '${batas?['jenis'] ?? 'bahasa'}'.toLowerCase();
  if (minimum == null) return null;
  final skor = _skorBahasa(p.skorBahasa, nama);
  final up = nama.toUpperCase();
  if (skor == null) {
    return HasilSyarat(
      jenis,
      _toleran,
      0.5,
      kekurangan: 'Perlu sertifikat $up dengan skor ${fmtG(minimum)}',
    );
  }
  if (skor >= minimum) {
    return HasilSyarat(
      jenis,
      _ok,
      1.0,
      alasan: 'Skor $up ${fmtG(skor)} memenuhi syarat ${fmtG(minimum)}',
    );
  }
  if ((minimum - skor) / minimum <= _tolBahasa) {
    return HasilSyarat(
      jenis,
      _toleran,
      0.6,
      kekurangan:
          'Perlu skor $up ${fmtG(minimum)}, skor saat ini ${fmtG(skor)}',
    );
  }
  return HasilSyarat(
    jenis,
    _gagal,
    0.0,
    kekurangan: 'Skor $up ${fmtG(skor)} jauh di bawah ${fmtG(minimum)}',
  );
}

final _calonBaru = RegExp(
  r'\b(siswa|pelajar|lulusan (sma|smk|ma|smp|satuan pendidikan)|lulusan sma|sederajat|calon mahasiswa)\b',
);
final _profesi = RegExp(
  r'\b(santri|pondok pesantren|pesantren|guru|pendidik|tenaga kependidikan|nuptk|ustadz|ustadzah|pns|profesional|'
  r'dosen|pegawai|karyawan|atlet|penyandang)\b',
);

HasilSyarat? _kelompokSasaran(Map<String, dynamic>? batas, ProfilKelayakan p) {
  final teks = '${batas?['teks'] ?? ''}'.toLowerCase();
  if (teks.isEmpty) return null;
  if (_calonBaru.hasMatch(teks) && (p.semester ?? 0) >= 1) {
    return HasilSyarat(
      'lainnya',
      _toleran,
      0.3,
      kekurangan: 'Ditujukan bagi calon mahasiswa baru atau pelajar, periksa laman resmi',
    );
  }
  if (teks.startsWith('khusus mahasiswa ')) {
    return HasilSyarat(
      'lainnya',
      _toleran,
      0.3,
      kekurangan: 'Ditujukan bagi mahasiswa kampus penyelenggara, pastikan kampus Anda sesuai',
    );
  }
  if (_profesi.hasMatch(teks)) {
    return HasilSyarat(
      'lainnya',
      _toleran,
      0.3,
      kekurangan: 'Ditujukan bagi kelompok tertentu (santri, pendidik, profesional, dll.), pastikan Anda termasuk',
    );
  }
  return null;
}

const _lanjut = {'S1': ('S2', 7), 'D4': ('S2', 7), 'S2': ('S3', 3)};

HasilSyarat? _jenjang(
  String jenis,
  Map<String, dynamic>? batas,
  ProfilKelayakan p,
) {
  final diminta = _daftar(batas);
  if (diminta.isEmpty) return null;
  if ((p.jenjang == null || p.jenjang!.isEmpty) && p.jenjangTuju.isEmpty) {
    return _tidakDiketahui(jenis, 'jenjang');
  }
  if (p.jenjang != null && diminta.contains(p.jenjang)) {
    return HasilSyarat(jenis, _ok, 1.0, alasan: 'Jenjang ${p.jenjang} sesuai');
  }
  final tuju = [
    for (final t in p.jenjangTuju)
      if (diminta.contains(t)) t,
  ];
  if (tuju.isNotEmpty) {
    return HasilSyarat(
      jenis,
      _ok,
      1.0,
      alasan: 'Jenjang tujuan ${tuju.first} sesuai',
    );
  }
  final lanjut = _lanjut[p.jenjang ?? ''];
  if (lanjut != null &&
      diminta.contains(lanjut.$1) &&
      (p.semester ?? 0) >= lanjut.$2) {
    return HasilSyarat(
      jenis,
      _toleran,
      0.8,
      kekurangan:
          'Program ${lanjut.$1}: kamu perlu lulus ${p.jenjang} lebih dulu',
    );
  }
  return HasilSyarat(
    jenis,
    _gagal,
    0.0,
    kekurangan: 'Untuk jenjang ${diminta.join(', ')}',
  );
}

HasilSyarat? periksaSyarat(
  TabelWilayah t,
  String jenis,
  Map<String, dynamic>? batas,
  ProfilKelayakan p,
  DateTime hariIni,
) {
  switch (jenis) {
    case 'ipk_minimum':
      return _ipk(jenis, batas, p);
    case 'semester_minimum':
    case 'semester_maksimum':
      return _semester(jenis, batas, p);
    case 'jenjang':
      return _jenjang(jenis, batas, p);
    case 'jenis_kampus':
      return _pilihan(
        jenis,
        batas,
        p.jenisKampus,
        'kampus',
        'Kampus {nilai} sesuai',
      );
    case 'domisili':
      return _domisili(t, batas, p);
    case 'kewarganegaraan':
      return _warga(jenis, batas, p.kewarganegaraan);
    case 'usia_maksimum':
      final maks = _angka(batas);
      if (maks == null) return null;
      if (p.tanggalLahir == null) {
        return _tidakDiketahui(jenis, 'tanggal lahir');
      }
      final u = usia(p.tanggalLahir!, hariIni);
      if (u <= maks) {
        return HasilSyarat(
          jenis,
          _ok,
          1.0,
          alasan: 'Usia $u tahun dalam batas ${maks.truncate()} tahun',
        );
      }
      return HasilSyarat(
        jenis,
        _gagal,
        0.0,
        kekurangan: 'Batas usia ${maks.truncate()} tahun',
      );
    case 'penghasilan_maksimum':
      final maks = _angka(batas);
      if (maks == null) return null;
      if (p.penghasilanOrangTua == null) {
        return _tidakDiketahui(jenis, 'penghasilan orang tua');
      }
      if (p.penghasilanOrangTua! <= maks) {
        return HasilSyarat(
          jenis,
          _ok,
          1.0,
          alasan: 'Penghasilan orang tua dalam batas',
        );
      }
      return HasilSyarat(
        jenis,
        _gagal,
        0.0,
        kekurangan: 'Penghasilan orang tua melebihi batas',
      );
    case 'sertifikat_bahasa':
      return _bahasa(jenis, batas, p);
    case 'lainnya':
      return _kelompokSasaran(batas, p);
    case 'berkas_pendukung':
      final nama = '${batas?['nama'] ?? ''}'.trim();
      if (nama.isEmpty) return null;
      if (p.berkasDiunggah
          .map((b) => b.toLowerCase())
          .contains(nama.toLowerCase())) {
        return HasilSyarat(
          jenis,
          _ok,
          1.0,
          alasan: 'Berkas $nama sudah tersedia',
        );
      }
      return HasilSyarat(
        jenis,
        _toleran,
        0.7,
        kekurangan: 'Siapkan berkas $nama',
      );
  }
  return null;
}

const _lemah = {'jenjang', 'berkas_pendukung'};
const syaratKuatMinimum = 1;

HasilKelayakan nilaiKelayakan(
  TabelWilayah t,
  List<Syarat> syarat,
  ProfilKelayakan p,
  DateTime hariIni,
) {
  final hasil = <HasilSyarat>[];
  final rincian = <HasilSyarat?>[];
  for (final s in syarat) {
    final h = periksaSyarat(t, s.$1, s.$2, p, hariIni);
    rincian.add(h);
    if (h != null) hasil.add(h);
  }
  if (hasil.isEmpty) {
    return HasilKelayakan(hampir, 0.4, [], [
      'Syarat belum tercatat, periksa laman resmi',
    ], rincian);
  }
  final alasan = [
    for (final h in hasil)
      if (h.status == _ok && (h.alasan?.isNotEmpty ?? false)) h.alasan!,
  ];
  final kurang = [
    for (final h in hasil)
      if ((h.status == _toleran || h.status == _tidakTahu) &&
          (h.kekurangan?.isNotEmpty ?? false))
        h.kekurangan!,
  ];
  final skor = hasil.fold<double>(0, (a, h) => a + h.nilai) / hasil.length;
  final gagal = hasil.where((h) => h.status == _gagal).toList();
  if (gagal.isNotEmpty) {
    return HasilKelayakan(belum, skor, alasan, [
      for (final h in gagal)
        if (h.kekurangan?.isNotEmpty ?? false) h.kekurangan!,
      ...kurang,
    ], rincian);
  }
  if (hasil.every((h) => h.status == _ok)) {
    final kuat = hasil.where((h) => !_lemah.contains(h.jenis)).toList();
    final batasSkor = skor < 0.5 ? skor : 0.5;
    if (kuat.isEmpty) {
      return HasilKelayakan(hampir, batasSkor, alasan, [
        'Hanya jenjang yang tercatat, periksa syarat lain di laman resmi',
      ], rincian);
    }
    if (kuat.length < syaratKuatMinimum) {
      return HasilKelayakan(hampir, batasSkor, alasan, [
        'Syarat terukur masih sedikit, periksa syarat lain di laman resmi',
      ], rincian);
    }
    return HasilKelayakan(memenuhi, skor, alasan, [], rincian);
  }
  return HasilKelayakan(hampir, skor, alasan, kurang, rincian);
}
