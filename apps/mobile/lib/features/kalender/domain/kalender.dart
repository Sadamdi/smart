import '../../../core/format.dart';
import '../../beasiswa/domain/beasiswa.dart';

class Acara {
  const Acara({
    required this.jenis,
    required this.tanggal,
    required this.judul,
    required this.refId,
    required this.selesai,
  });

  final String jenis; // tenggat atau tugas
  final DateTime tanggal;
  final String judul;
  final String refId;
  final bool selesai;

  bool get tenggat => jenis == 'tenggat';

  factory Acara.fromJson(Map<String, dynamic> j) => Acara(
    jenis: j['jenis'] as String,
    tanggal: urai(j['tanggal'] as String?) ?? DateTime.now(),
    judul: j['judul'] as String,
    refId: j['ref_id'] as String,
    selesai: (j['selesai'] ?? false) as bool,
  );
}

class BerkasChecklist {
  const BerkasChecklist({
    required this.id,
    required this.namaBerkas,
    required this.selesai,
  });

  final String id;
  final String namaBerkas;
  final bool selesai;

  BerkasChecklist ubah(bool selesai) =>
      BerkasChecklist(id: id, namaBerkas: namaBerkas, selesai: selesai);

  factory BerkasChecklist.fromJson(Map<String, dynamic> j) => BerkasChecklist(
    id: j['id'] as String,
    namaBerkas: j['nama_berkas'] as String,
    selesai: (j['selesai'] ?? false) as bool,
  );
}

class ChecklistBeasiswa {
  const ChecklistBeasiswa({required this.beasiswa, required this.berkas});

  final BeasiswaRingkas beasiswa;
  final List<BerkasChecklist> berkas;

  int get jumlahSelesai => berkas.where((b) => b.selesai).length;

  factory ChecklistBeasiswa.fromJson(Map<String, dynamic> j) =>
      ChecklistBeasiswa(
        beasiswa: BeasiswaRingkas.fromJson(
          j['beasiswa'] as Map<String, dynamic>,
        ),
        berkas: [
          for (final x in (j['berkas'] as List? ?? []))
            BerkasChecklist.fromJson(x as Map<String, dynamic>),
        ],
      );
}

class Tugas {
  const Tugas({
    required this.id,
    required this.judul,
    required this.tanggal,
    required this.selesai,
  });

  final String id;
  final String judul;
  final DateTime tanggal;
  final bool selesai;

  factory Tugas.fromJson(Map<String, dynamic> j) => Tugas(
    id: j['id'] as String,
    judul: j['judul'] as String,
    tanggal: urai(j['tanggal'] as String?) ?? DateTime.now(),
    selesai: (j['selesai'] ?? false) as bool,
  );
}
