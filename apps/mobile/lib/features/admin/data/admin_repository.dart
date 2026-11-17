import '../../../core/api_client.dart';

class SumberAdmin {
  const SumberAdmin({
    required this.id,
    required this.nama,
    required this.url,
    required this.jenis,
    required this.status,
    required this.aktif,
  });

  final String id;
  final String nama;
  final String url;
  final String jenis;
  final String status;
  final bool aktif;

  bool get bisaDipantau => jenis == 'pantau_otomatis';

  factory SumberAdmin.fromJson(Map<String, dynamic> j) => SumberAdmin(
    id: j['id'] as String,
    nama: j['nama'] as String,
    url: (j['url'] ?? '') as String,
    jenis: (j['jenis'] ?? '') as String,
    status: (j['status_terakhir'] ?? 'belum_pernah') as String,
    aktif: (j['aktif'] ?? true) as bool,
  );
}

class AntreanAdmin {
  const AntreanAdmin({
    required this.id,
    required this.nama,
    this.penyelenggara,
    this.namaSumber,
    this.alasanDitandai,
  });

  final String id;
  final String nama;
  final String? penyelenggara;
  final String? namaSumber;
  final String? alasanDitandai;

  factory AntreanAdmin.fromJson(Map<String, dynamic> j) => AntreanAdmin(
    id: j['id'] as String,
    nama: j['nama'] as String,
    penyelenggara: j['penyelenggara'] as String?,
    namaSumber: j['nama_sumber'] as String?,
    alasanDitandai: j['alasan_ditandai'] as String?,
  );
}

class LaporanAdmin {
  const LaporanAdmin({
    required this.beasiswa,
    required this.sumber,
    required this.jumlahSumber,
    required this.jumlahMahasiswa,
  });

  final Map<String, int> beasiswa;
  final Map<String, int> sumber;
  final int jumlahSumber;
  final int jumlahMahasiswa;

  int get menunggu => beasiswa['menunggu_validasi'] ?? 0;
  int get terbit => beasiswa['terbit'] ?? 0;
  int get sumberGagal => sumber['gagal'] ?? 0;
  int get sumberBelum => sumber['belum_pernah'] ?? 0;

  /// Pekerjaan admin yang menunggu, tiap butir menyebut tab tujuan: 'antrean' atau 'sumber'.
  List<({String teks, String tab})> get tindakan => [
    if (menunggu > 0)
      (teks: '$menunggu beasiswa menunggu validasi', tab: 'antrean'),
    if (sumberGagal > 0)
      (teks: '$sumberGagal sumber gagal diperiksa', tab: 'sumber'),
    if (sumberBelum > 0)
      (teks: '$sumberBelum sumber belum pernah dipantau', tab: 'sumber'),
  ];

  static Map<String, int> _peta(Object? v) => {
    for (final e in ((v as Map?) ?? {}).entries)
      '${e.key}': (e.value as num).toInt(),
  };

  factory LaporanAdmin.fromJson(Map<String, dynamic> j) => LaporanAdmin(
    beasiswa: _peta(j['beasiswa_per_status']),
    sumber: _peta(j['sumber_per_status']),
    jumlahSumber: ((j['jumlah_sumber'] ?? 0) as num).toInt(),
    jumlahMahasiswa: ((j['jumlah_mahasiswa'] ?? 0) as num).toInt(),
  );
}

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<LaporanAdmin> laporan() async {
    final r = await _api.get('/admin/laporan');
    return LaporanAdmin.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<AntreanAdmin>> antrean() async {
    final r = await _api.get('/admin/antrean-validasi');
    return [
      for (final x in r.data as List)
        AntreanAdmin.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<void> terbitkan(String id) =>
      _api.post('/admin/beasiswa/$id/terbitkan');

  Future<void> tolak(String id, String alasan) =>
      _api.post('/admin/beasiswa/$id/tolak', body: {'alasan': alasan});

  Future<List<SumberAdmin>> sumber() async {
    final r = await _api.get('/admin/sumber');
    return [
      for (final x in r.data as List)
        SumberAdmin.fromJson(x as Map<String, dynamic>),
    ];
  }

  Future<void> aturAktif(String id, bool aktif) =>
      _api.put('/admin/sumber/$id', body: {'aktif': aktif});

  /// Memantau satu sumber; mengembalikan teks hasil, mis. "12 ditemukan, 3 baru".
  Future<String> pantau(String id) async {
    final r = await _api.post('/admin/sumber/$id/pantau');
    final d = (r.data as Map?) ?? {};
    return '${d['ditemukan'] ?? 0} ditemukan, ${d['baru'] ?? 0} baru';
  }
}
