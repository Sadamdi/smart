import '../../../core/format.dart';

/// API mengirim jenjang sebagai daftar (mis. [S1, S2]); ditampilkan sebagai "S1, S2".
String? teksJenjang(Object? v) {
  if (v is List) {
    final t = v.map((e) => '$e').where((e) => e.isNotEmpty).join(', ');
    return t.isEmpty ? null : t;
  }
  return v is String && v.isNotEmpty ? v : null;
}

class BeasiswaRingkas {
  const BeasiswaRingkas({
    required this.id,
    required this.nama,
    this.penyelenggara,
    this.negara,
    this.jenjang,
    this.tenggat,
    required this.tautanResmi,
  });

  final String id;
  final String nama;
  final String? penyelenggara;
  final String? negara;
  final String? jenjang;
  final DateTime? tenggat;
  final String tautanResmi;

  factory BeasiswaRingkas.fromJson(Map<String, dynamic> j) => BeasiswaRingkas(
    id: j['id'] as String,
    nama: j['nama'] as String,
    penyelenggara: j['penyelenggara'] as String?,
    negara: j['negara'] as String?,
    jenjang: teksJenjang(j['jenjang']),
    tenggat: urai(j['tenggat'] as String?),
    tautanResmi: (j['tautan_resmi'] ?? '') as String,
  );
}

class Persyaratan {
  const Persyaratan({
    required this.jenis,
    this.nilaiBatas,
    required this.dapatDikejar,
  });

  final String jenis;
  final Map<String, dynamic>? nilaiBatas;
  final bool dapatDikejar;

  factory Persyaratan.fromJson(Map<String, dynamic> j) => Persyaratan(
    jenis: j['jenis'] as String,
    nilaiBatas: j['nilai_batas'] is Map<String, dynamic>
        ? j['nilai_batas'] as Map<String, dynamic>
        : null,
    dapatDikejar: (j['dapat_dikejar'] ?? false) as bool,
  );

  static const _label = {
    'ipk_minimum': 'IPK minimum',
    'semester_minimum': 'Semester minimum',
    'semester_maksimum': 'Semester maksimum',
    'jenjang': 'Jenjang',
    'jenis_kampus': 'Jenis kampus',
    'domisili': 'Domisili',
    'usia_maksimum': 'Usia maksimum',
    'sertifikat_bahasa': 'Sertifikat bahasa',
    'penghasilan_maksimum': 'Penghasilan orang tua maksimum',
    'kewarganegaraan': 'Kewarganegaraan',
    'berkas_pendukung': 'Berkas pendukung',
    'lainnya': 'Syarat lain',
  };

  String get label => _label[jenis] ?? jenis.replaceAll('_', ' ');

  /// Nilai batas dalam teks; kosong bila server tidak mengirim nilai.
  String get nilai {
    final n = nilaiBatas;
    if (n == null || n.isEmpty) return '';
    return n.values
        .map((v) => v is List ? v.join(', ') : '$v')
        .where((s) => s.isNotEmpty && s != 'null')
        .join(' · ');
  }
}

class BerkasWajib {
  const BerkasWajib({required this.id, required this.namaBerkas});

  final String id;
  final String namaBerkas;

  factory BerkasWajib.fromJson(Map<String, dynamic> j) => BerkasWajib(
    id: j['id'] as String,
    namaBerkas: j['nama_berkas'] as String,
  );
}

class BeasiswaDetail {
  const BeasiswaDetail({
    required this.ringkas,
    this.manfaat,
    this.tanggalDiperiksa,
    this.persyaratan = const [],
    this.berkasWajib = const [],
  });

  final BeasiswaRingkas ringkas;
  final String? manfaat;
  final DateTime? tanggalDiperiksa;
  final List<Persyaratan> persyaratan;
  final List<BerkasWajib> berkasWajib;

  factory BeasiswaDetail.fromJson(Map<String, dynamic> j) => BeasiswaDetail(
    ringkas: BeasiswaRingkas.fromJson(j),
    manfaat: j['manfaat'] as String?,
    tanggalDiperiksa: urai(j['tanggal_diperiksa'] as String?),
    persyaratan: [
      for (final x in (j['persyaratan'] as List? ?? []))
        Persyaratan.fromJson(x as Map<String, dynamic>),
    ],
    berkasWajib: [
      for (final x in (j['berkas_wajib'] as List? ?? []))
        BerkasWajib.fromJson(x as Map<String, dynamic>),
    ],
  );
}

class HalamanBeasiswa {
  const HalamanBeasiswa(this.items, this.kursorBerikut);

  final List<BeasiswaRingkas> items;
  final String? kursorBerikut;
}
