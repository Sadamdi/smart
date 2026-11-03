class Dokumen {
  const Dokumen({
    required this.id,
    required this.jenis,
    required this.namaBerkas,
    required this.statusBaca,
    this.hasilBaca,
  });

  final String id;
  final String jenis;
  final String namaBerkas;
  final String statusBaca;
  final Map<String, dynamic>? hasilBaca;

  /// Ringkasan nilai yang terbaca (IPK, semester, skor bahasa) untuk ditampilkan.
  List<String> get ringkasan {
    final h = hasilBaca ?? const <String, dynamic>{};
    return [
      if (h['ipk'] != null) 'IPK ${h['ipk']}',
      if (h['semester'] != null) 'Semester ${h['semester']}',
      if (h['skor_bahasa'] is Map)
        for (final e in (h['skor_bahasa'] as Map).entries)
          '${'${e.key}'.toUpperCase()} ${e.value}',
    ];
  }

  factory Dokumen.fromJson(Map<String, dynamic> j) => Dokumen(
    id: j['id'] as String,
    jenis: j['jenis'] as String,
    namaBerkas: j['nama_berkas'] as String,
    statusBaca: j['status_baca'] as String,
    hasilBaca: j['hasil_baca'] as Map<String, dynamic>?,
  );
}
