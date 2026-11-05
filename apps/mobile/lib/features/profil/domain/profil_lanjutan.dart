/// Pengubah isian "nama | kolom kedua | tahun" (satu butir per baris) dari dan ke daftar peta
/// untuk profil lanjutan (organisasi, prestasi, sertifikat, pengalaman).
List<Map<String, dynamic>> uraiBaris(String teks, List<String> kolom) {
  final hasil = <Map<String, dynamic>>[];
  for (final baris in teks.split('\n')) {
    final bagian = baris.split('|').map((e) => e.trim()).toList();
    if (bagian.isEmpty || bagian.first.isEmpty) continue;
    final butir = <String, dynamic>{};
    for (var i = 0; i < kolom.length && i < bagian.length; i++) {
      final nilai = bagian[i];
      if (nilai.isEmpty) continue;
      butir[kolom[i]] = kolom[i] == 'tahun' ? int.tryParse(nilai) : nilai;
    }
    butir.removeWhere((_, v) => v == null);
    hasil.add(butir);
  }
  return hasil;
}

String formatBaris(List<dynamic> daftar, List<String> kolom) {
  return [
    for (final x in daftar)
      if (x is Map)
        kolom
            .map((k) => '${x[k] ?? ''}')
            .join(' | ')
            .replaceAll(RegExp(r'(\s\|\s)+$'), ''),
  ].join('\n');
}

List<String> uraiDaftarKoma(String teks) =>
    teks.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
