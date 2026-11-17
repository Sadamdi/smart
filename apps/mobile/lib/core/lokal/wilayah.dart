/// Pencocokan wilayah untuk syarat domisili, dipindah dari server (app/rekomendasi/wilayah.py) agar
/// perhitungan kelayakan dapat berjalan di perangkat saat luring. Tabelnya diekspor server ke assets/data/wilayah.json.
library;

final _awalan = RegExp(
  r'^(kota administrasi|kota adm\.?|kota|kabupaten|kab\.?|provinsi|prov\.?|city of|negara)\s+',
);

const _tepi = ' \t.,;:()';

String _pangkas(String t) {
  var a = 0;
  var b = t.length;
  while (a < b && _tepi.contains(t[a])) {
    a++;
  }
  while (b > a && _tepi.contains(t[b - 1])) {
    b--;
  }
  return t.substring(a, b);
}

/// Bentuk pembanding: huruf kecil, spasi tunggal, tanpa tanda baca di tepi dan tanpa awalan Kota atau Provinsi.
String kunci(String? teks) {
  final t = _pangkas((teks ?? '').toLowerCase().trim())
      .replaceAll(RegExp(r'\s+'), ' ');
  return t.replaceFirst(_awalan, '').trim();
}

class TabelWilayah {
  TabelWilayah({
    required this.negara,
    required this.provinsi,
    required this.kota,
    required this.negaraAsal,
  });

  factory TabelWilayah.dariJson(Map<String, dynamic> j) => TabelWilayah(
    negara: Map<String, String>.from(j['negara'] as Map),
    provinsi: Map<String, String>.from(j['provinsi'] as Map),
    kota: Map<String, String>.from(j['kota'] as Map),
    negaraAsal: j['negara_asal'] as String,
  );

  final Map<String, String> negara;
  final Map<String, String> provinsi;
  final Map<String, String> kota;
  final String negaraAsal;

  String? negaraKanonik(String? t) => negara[kunci(t)];
  String? provinsiKanonik(String? t) => provinsi[kunci(t)];
  String? provinsiDariKota(String? k) => kota[kunci(k)];
}

class Wilayah {
  const Wilayah({
    this.negara,
    this.provinsi,
    this.kota,
    this.tambahan = const [],
  });

  final String? negara;
  final String? provinsi;
  final String? kota;
  final List<String> tambahan;

  bool get kosong =>
      !((negara?.isNotEmpty ?? false) ||
          (provinsi?.isNotEmpty ?? false) ||
          (kota?.isNotEmpty ?? false) ||
          tambahan.isNotEmpty);
}

const cocok = 'cocok';
const beda = 'beda';
const takTahu = 'tidak_diketahui';

List<String> _bagian(String syarat) => syarat
    .trim()
    .split(
      RegExp(
        r'\s*(?:,|;|/|\bdan\b|\batau\b|\band\b|\bor\b)\s*',
        caseSensitive: false,
      ),
    )
    .where((p) => p.trim().isNotEmpty)
    .toList();

String _cocokSatu(TabelWilayah t, String bagian, Wilayah w) {
  final k = kunci(bagian);
  if (k.isEmpty) return takTahu;
  var negaraW = t.negaraKanonik(w.negara);
  var provinsiW = t.provinsiKanonik(w.provinsi);
  if (provinsiW == null && (negaraW == null || negaraW == t.negaraAsal)) {
    provinsiW = t.provinsiDariKota(w.kota);
  }
  if (negaraW == null && provinsiW != null) negaraW = t.negaraAsal;
  final tambahan = [
    for (final x in w.tambahan)
      if (x.isNotEmpty) kunci(x),
  ];

  final n = t.negaraKanonik(bagian);
  final p = t.provinsiKanonik(bagian);
  if (p != null) {
    if (provinsiW == p || w.tambahan.any((x) => t.provinsiKanonik(x) == p)) {
      return cocok;
    }
    if (provinsiW != null) return beda;
    if (negaraW != null && negaraW != t.negaraAsal) return beda;
    return takTahu;
  }
  if (n != null) {
    if (negaraW != null) return negaraW == n ? cocok : beda;
    return takTahu;
  }
  if (tambahan.contains(k)) return cocok;
  if (w.kota != null && kunci(w.kota).isNotEmpty) {
    return kunci(w.kota) == k ? cocok : beda;
  }
  return takTahu;
}

/// cocok, beda, atau takTahu untuk satu butir syarat domisili terhadap wilayah pengguna.
String cocokWilayah(TabelWilayah t, String syarat, Wilayah w) {
  final bagian = _bagian(syarat);
  final hasil = [for (final b in bagian) _cocokSatu(t, b, w)];
  if (hasil.contains(cocok)) return cocok;
  if (!bagian.any(
    (b) => t.negaraKanonik(b) != null || t.provinsiKanonik(b) != null,
  )) {
    final k = kunci(syarat);
    for (final nilai in [w.kota, w.provinsi, w.negara, ...w.tambahan]) {
      final kn = kunci(nilai);
      if (kn.length >= 4 &&
          RegExp('${r'\b'}${RegExp.escape(kn)}${r'\b'}').hasMatch(k)) {
        return cocok;
      }
    }
  }
  if (hasil.contains(beda)) return beda;
  return takTahu;
}
