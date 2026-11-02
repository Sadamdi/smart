import '../../beasiswa/domain/beasiswa.dart';

enum Kategori {
  memenuhi('memenuhi', 'Memenuhi'),
  hampirMemenuhi('hampir_memenuhi', 'Hampir memenuhi'),
  belumMemenuhi('belum_memenuhi', 'Belum memenuhi');

  const Kategori(this.kode, this.label);

  final String kode;
  final String label;

  static Kategori dari(String s) => Kategori.values.firstWhere(
    (k) => k.kode == s,
    orElse: () => Kategori.belumMemenuhi,
  );
}

class Rekomendasi {
  const Rekomendasi({
    required this.beasiswa,
    required this.kategori,
    required this.alasan,
    required this.catatanKekurangan,
  });

  final BeasiswaRingkas beasiswa;
  final Kategori kategori;
  final List<String> alasan;
  final List<String> catatanKekurangan;

  factory Rekomendasi.fromJson(Map<String, dynamic> j) => Rekomendasi(
    beasiswa: BeasiswaRingkas.fromJson(j['beasiswa'] as Map<String, dynamic>),
    kategori: Kategori.dari(j['kategori'] as String),
    alasan: [for (final x in (j['alasan'] as List? ?? [])) '$x'],
    catatanKekurangan: [
      for (final x in (j['catatan_kekurangan'] as List? ?? [])) '$x',
    ],
  );
}

class RingkasanRekomendasi {
  const RingkasanRekomendasi({
    required this.memenuhi,
    required this.hampirMemenuhi,
    required this.belumMemenuhi,
  });

  final int memenuhi;
  final int hampirMemenuhi;
  final int belumMemenuhi;

  factory RingkasanRekomendasi.fromJson(Map<String, dynamic> j) =>
      RingkasanRekomendasi(
        memenuhi: (j['memenuhi'] ?? 0) as int,
        hampirMemenuhi: (j['hampir_memenuhi'] ?? 0) as int,
        belumMemenuhi: (j['belum_memenuhi'] ?? 0) as int,
      );
}
