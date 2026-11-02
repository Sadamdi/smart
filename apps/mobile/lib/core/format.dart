const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _bulanPendek = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String namaBulan(int bulan) => _bulan[bulan - 1];

String bulanPendek(int bulan) => _bulanPendek[bulan - 1];

/// 2026-11-18 menjadi "18 November 2026".
String formatTanggal(DateTime t) => '${t.day} ${namaBulan(t.month)} ${t.year}';

/// Format yang dikirim ke API (yyyy-MM-dd).
String tanggalApi(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

DateTime? urai(String? s) {
  if (s == null || s.isEmpty) return null;
  final t = DateTime.tryParse(s);
  return t == null ? null : DateTime(t.year, t.month, t.day);
}

/// Selisih hari dari [sekarang] ke [tenggat]; negatif bila lewat.
int sisaHari(DateTime tenggat, {DateTime? sekarang}) {
  final n = sekarang ?? DateTime.now();
  final a = DateTime(n.year, n.month, n.day);
  return DateTime(
    tenggat.year,
    tenggat.month,
    tenggat.day,
  ).difference(a).inDays;
}

/// "Tersisa 6 hari", "Hari ini", atau "Sudah lewat".
String teksSisaHari(DateTime? tenggat, {DateTime? sekarang}) {
  if (tenggat == null) return 'Tenggat belum diumumkan';
  final s = sisaHari(tenggat, sekarang: sekarang);
  if (s < 0) return 'Sudah lewat';
  if (s == 0) return 'Hari ini';
  return 'Tersisa $s hari';
}
