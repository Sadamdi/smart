import '../../../core/format.dart';

class Notifikasi {
  const Notifikasi({
    required this.id,
    required this.jenis,
    required this.dibaca,
    required this.tanggalAcuan,
    required this.judul,
    required this.pesan,
    required this.beasiswaId,
  });

  final String id;
  final String jenis; // tenggat atau beasiswa_baru
  final bool dibaca;
  final DateTime tanggalAcuan;
  final String judul;
  final String pesan;
  final String beasiswaId;

  Notifikasi tandaiDibaca() => Notifikasi(
    id: id,
    jenis: jenis,
    dibaca: true,
    tanggalAcuan: tanggalAcuan,
    judul: judul,
    pesan: pesan,
    beasiswaId: beasiswaId,
  );

  factory Notifikasi.fromJson(Map<String, dynamic> j) => Notifikasi(
    id: j['id'] as String,
    jenis: j['jenis'] as String,
    dibaca: (j['dibaca'] ?? false) as bool,
    tanggalAcuan: urai(j['tanggal_acuan'] as String?) ?? DateTime.now(),
    judul: j['judul'] as String,
    pesan: j['pesan'] as String,
    beasiswaId: j['beasiswa_id'] as String,
  );
}
