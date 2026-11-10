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

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'penyelenggara': penyelenggara,
    'negara': negara,
    'jenjang': jenjang?.split(', '),
    'tenggat': tenggat == null ? null : tanggalApi(tenggat!),
    'tautan_resmi': tautanResmi,
  };
}

class Persyaratan {
  const Persyaratan({
    required this.jenis,
    this.nilaiBatas,
    required this.dapatDikejar,
    this.status,
    this.catatan,
  });

  final String jenis;
  final Map<String, dynamic>? nilaiBatas;
  final bool dapatDikejar;

  /// Penilaian terhadap profil pengguna: terpenuhi, dalam_toleransi, gagal, tidak_diketahui.
  final String? status;
  final String? catatan;

  factory Persyaratan.fromJson(Map<String, dynamic> j) => Persyaratan(
    jenis: j['jenis'] as String,
    nilaiBatas: j['nilai_batas'] is Map<String, dynamic>
        ? j['nilai_batas'] as Map<String, dynamic>
        : null,
    dapatDikejar: (j['dapat_dikejar'] ?? false) as bool,
    status: j['status'] as String?,
    catatan: j['catatan'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'jenis': jenis,
    'nilai_batas': nilaiBatas,
    'dapat_dikejar': dapatDikejar,
    'status': status,
    'catatan': catatan,
  };

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

  Map<String, dynamic> toJson() => {'id': id, 'nama_berkas': namaBerkas};
}

class BeasiswaDetail {
  const BeasiswaDetail({
    required this.ringkas,
    this.manfaat,
    this.tanggalDiperiksa,
    this.persyaratan = const [],
    this.berkasWajib = const [],
    this.kategori,
    this.alasan = const [],
    this.catatanKekurangan = const [],
  });

  final String? kategori;
  final List<String> alasan;
  final List<String> catatanKekurangan;
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
    kategori: j['kategori'] as String?,
    alasan: [for (final x in (j['alasan'] as List? ?? [])) '$x'],
    catatanKekurangan: [
      for (final x in (j['catatan_kekurangan'] as List? ?? [])) '$x',
    ],
  );

  /// Bentuk datar seperti respons API: kolom ringkasan berada di tingkat atas.
  Map<String, dynamic> toJson() => {
    ...ringkas.toJson(),
    'manfaat': manfaat,
    'tanggal_diperiksa': tanggalDiperiksa == null
        ? null
        : tanggalApi(tanggalDiperiksa!),
    'persyaratan': [for (final p in persyaratan) p.toJson()],
    'berkas_wajib': [for (final b in berkasWajib) b.toJson()],
    'kategori': kategori,
    'alasan': alasan,
    'catatan_kekurangan': catatanKekurangan,
  };
}

class HalamanBeasiswa {
  const HalamanBeasiswa(this.items, this.kursorBerikut);

  final List<BeasiswaRingkas> items;
  final String? kursorBerikut;
}
