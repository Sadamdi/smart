import '../data/chat_repository.dart';

/// Saran pertanyaan lanjutan yang disusun di ponsel (tanpa jaringan, tanpa model) dari konteks percakapan:
/// beasiswa yang baru dirujuk, topik pertanyaan dan jawaban terakhir, serta ada tidaknya lampiran.
/// Pertanyaan yang sudah pernah diajukan di sesi ini tidak disarankan lagi.
List<String> saranBerikut(List<PesanChat> riwayat, {bool lampiran = false}) {
  const awal = [
    'Beasiswa apa yang cocok untuk saya?',
    'Tenggat terdekat minggu ini',
    'Berkas apa saja yang biasanya diminta?',
    'Cara menaikkan peluang lolos',
  ];
  const awalLampiran = [
    'Analisis CV saya, apa kekurangannya?',
    'Beasiswa apa yang paling cocok dengan dokumen ini?',
    'Apa yang perlu saya perbaiki?',
  ];
  if (riwayat.isEmpty) return lampiran ? awalLampiran : awal;

  final terakhir = riwayat.last;
  final konteks = '${terakhir.pesan} ${terakhir.jawaban ?? ''}'.toLowerCase();
  final dahulu = {for (final p in riwayat) p.pesan.trim().toLowerCase()};
  final calon = <String>[];

  final nama = terakhir.rujukan.isNotEmpty ? terakhir.rujukan.first.nama : null;
  if (nama != null) {
    final pendek = nama.length > 32 ? '${nama.substring(0, 30)}…' : nama;
    calon.add('Syarat lengkap $pendek');
    calon.add('Kapan tenggat $pendek?');
    calon.add('Peluang saya di $pendek');
  }
  bool ada(List<String> kata) => kata.any(konteks.contains);

  if (ada(['ipk', 'nilai'])) calon.add('Bagaimana jika IPK saya kurang?');
  if (ada(['ielts', 'toefl', 'bahasa inggris', 'itp'])) {
    calon.add('Cara menyiapkan skor bahasa dengan cepat');
  }
  if (ada(['esai', 'motivasi', 'personal statement'])) {
    calon.add('Contoh kerangka esai motivasi');
  }
  if (ada(['berkas', 'dokumen', 'cv', 'transkrip'])) {
    calon.add('Buatkan daftar periksa berkas');
  }
  if (ada(['tenggat', 'deadline', 'batas'])) {
    calon.add('Susun jadwal persiapan sampai tenggat');
  }
  if (ada(['luar negeri', 's2', 's3', 'master', 'doktor', 'pascasarjana'])) {
    calon.add('Beasiswa luar negeri yang masih dibuka');
  }
  if (ada(['wawancara', 'interview'])) {
    calon.add('Pertanyaan wawancara yang sering muncul');
  }
  if (ada(['daerah', 'provinsi', 'pemda'])) {
    calon.add('Beasiswa dari daerah saya');
  }
  if (lampiran) calon.add('Apa yang perlu saya perbaiki dari dokumen ini?');
  calon.addAll(const [
    'Bandingkan dua beasiswa teratas untuk saya',
    'Apa langkah saya berikutnya?',
    'Tenggat terdekat minggu ini',
  ]);

  final hasil = <String>[];
  for (final c in calon) {
    if (dahulu.contains(c.toLowerCase()) || hasil.contains(c)) continue;
    hasil.add(c);
    if (hasil.length == 4) break;
  }
  return hasil;
}
