/// Estimasi peluang diterima di perangkat: sama dengan app/rekomendasi/peluang.py dan app/services/kartu.py di server.
/// Perkiraan, bukan jaminan; nilai dibatasi 1 sampai 90 persen.
library;

import 'kelayakan.dart';

const _bobotTingkat = {
  'sekolah': 0.2,
  'kota': 0.35,
  'provinsi': 0.5,
  'nasional': 0.8,
  'internasional': 1.0,
};

const tingkatNilai = {
  'sangat_ketat': 0.02,
  'ketat': 0.15,
  'sedang': 0.30,
  'longgar': 0.50,
};

const _sangatKetat = [
  'gates',
  'rhodes',
  'chevening',
  'tanoto',
  'teladan',
  'djarum',
  'schwarzman',
  'clarendon',
  'knight-hennessy',
  'marshall scholarship',
  'presidential',
];
const _ketat = [
  'lpdp',
  'iisma',
  'fulbright',
  'aminef',
  'daad',
  'mext',
  'monbukagakusho',
  'gks',
  'korean government',
  'global korea',
  'erasmus',
  'commonwealth',
  'australia awards',
  'turkiye',
  'türkiye',
  'turkey',
  'csc',
  'china government',
  'stipendium hungaricum',
  'unggulan',
  'full scholarship',
  'fully funded',
  'fully-funded',
  'penuh',
];
const _longgar = [
  'kip kuliah',
  'bidikmisi',
  'bantuan',
  'peningkatan prestasi',
  'ppa',
  'pemerintah daerah',
  'pemda',
  'kampus',
];

const syaratCukup = 3;
const faktorDataTipis = 0.8;
const faktorKategori = {
  'memenuhi': 1.0,
  'hampir_memenuhi': 0.55,
  'belum_memenuhi': 0.15,
};

String tingkatPersaingan(String nama, String? penyelenggara, bool luarNegeri) {
  final teks = '$nama ${penyelenggara ?? ''}'.toLowerCase();
  if (_sangatKetat.any(teks.contains)) return 'sangat_ketat';
  if (_ketat.any(teks.contains)) return 'ketat';
  if (_longgar.any(teks.contains) && !luarNegeri) return 'longgar';
  return luarNegeri ? 'ketat' : 'sedang';
}

double _banyak(Object? nilai, int maks) {
  final n = nilai is List ? nilai.length : 0;
  return (n < maks ? n : maks) / maks;
}

/// Kekuatan profil 0 sampai 1 (IPK, prestasi, organisasi, sertifikat, pengalaman, skor bahasa).
double kekuatanProfil(
  double? ipk,
  Map<String, dynamic>? profilLanjutan,
  Map<String, dynamic>? skorBahasa,
) {
  final pl = profilLanjutan ?? const <String, dynamic>{};
  final nilaiIpk = ipk == null ? 0.4 : ((ipk - 2.75) / 1.25).clamp(0.0, 1.0);
  final prestasi = (pl['prestasi'] is List) ? pl['prestasi'] as List : const [];
  var jumlah = 0.0;
  for (final p in prestasi) {
    if (p is Map) {
      jumlah += _bobotTingkat['${p['tingkat'] ?? ''}'] ?? 0.15;
    }
  }
  final skorPrestasi = jumlah < 1.0 ? jumlah : 1.0;
  final nilai =
      0.30 * nilaiIpk +
      0.25 * skorPrestasi +
      0.15 * _banyak(pl['organisasi'], 3) +
      0.10 * _banyak(pl['sertifikat'], 3) +
      0.10 * _banyak(pl['pengalaman'], 2) +
      0.10 * ((skorBahasa != null && skorBahasa.isNotEmpty) ? 1.0 : 0.0);
  return bulatDesimal(nilai, 3);
}

/// Persen 1 sampai 90, atau null bila belum ada syarat terukur.
int? estimasiPeluang({
  required String? kategori,
  required bool adaSyaratTerukur,
  required String nama,
  required String? penyelenggara,
  required bool luarNegeri,
  required double kekuatan,
  double? dasarStatistik,
  int jumlahSyarat = 3,
}) {
  if (kategori == null || !adaSyaratTerukur) return null;
  final dasar =
      dasarStatistik ??
      tingkatNilai[tingkatPersaingan(nama, penyelenggara, luarNegeri)]!;
  final faktorProfil = 0.6 + 0.8 * kekuatan.clamp(0.0, 1.0);
  var nilai = dasar * (faktorKategori[kategori] ?? 0.15) * faktorProfil * 100;
  if (jumlahSyarat < syaratCukup) nilai *= faktorDataTipis;
  return bulatGenap(nilai.clamp(1.0, 90.0));
}

const _catatanBukanSyarat = [
  'Syarat belum tercatat',
  'Hanya jenjang yang tercatat',
  'Syarat terukur masih sedikit',
];

class MetrikKartu {
  const MetrikKartu(this.skor, this.terpenuhi, this.total);

  final int? skor;
  final int terpenuhi;
  final int total;
}

/// Skor kelayakan 0 sampai 100 (null bila belum ada syarat terukur), serta jumlah syarat terpenuhi dan total.
MetrikKartu metrik(double? skor, List<String> alasan, List<String> catatan) {
  if (catatan.any((c) => _catatanBukanSyarat.any(c.startsWith))) {
    return const MetrikKartu(null, 0, 0);
  }
  final kurang = catatan.where((c) => c.isNotEmpty).toList();
  final total = alasan.length + kurang.length;
  if (total == 0 || skor == null) return const MetrikKartu(null, 0, 0);
  return MetrikKartu(
    bulatGenap(skor * 100).clamp(0, 100),
    alasan.length,
    total,
  );
}

bool luarNegeri(String? negara) {
  final n = (negara ?? '').trim().toLowerCase();
  return n.isNotEmpty && !n.contains('indonesia');
}
