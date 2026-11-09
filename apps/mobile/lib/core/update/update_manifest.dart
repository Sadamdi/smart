class CatatanRilis {
  const CatatanRilis({
    required this.version,
    required this.build,
    this.date,
    required this.notes,
  });

  final String version;
  final int build;
  final String? date;
  final String notes;

  factory CatatanRilis.fromJson(Map<String, dynamic> j) => CatatanRilis(
    version: j['version'] as String? ?? '',
    build: (j['build'] as num?)?.toInt() ?? 0,
    date: j['date'] as String?,
    notes: j['notes'] as String? ?? '',
  );
}

/// Isi `latest.json`: versi terbaru, APK per arsitektur beserta SHA-256, aturan wajib atau opsional, dan riwayat.
class UpdateManifest {
  const UpdateManifest({
    required this.version,
    required this.build,
    required this.minBuild,
    required this.blockedBuilds,
    required this.notes,
    required this.apks,
    required this.sha256,
    required this.certSha256,
    required this.history,
  });

  final String version;
  final int build;
  final int minBuild;
  final List<int> blockedBuilds;
  final String notes;
  final Map<String, String> apks;
  final Map<String, String> sha256;
  final String? certSha256;
  final List<CatatanRilis> history;

  factory UpdateManifest.fromJson(Map<String, dynamic> j) {
    Map<String, String> peta(Object? v) => {
      for (final e in (v as Map? ?? const {}).entries) '${e.key}': '${e.value}',
    };
    return UpdateManifest(
      version: j['version'] as String? ?? '',
      build: (j['build'] as num?)?.toInt() ?? 0,
      minBuild: (j['minBuild'] as num?)?.toInt() ?? 0,
      blockedBuilds: [
        for (final b in (j['blockedBuilds'] as List? ?? const []))
          (b as num).toInt(),
      ],
      notes: j['notes'] as String? ?? '',
      apks: peta(j['apks']),
      sha256: peta(j['sha256']),
      certSha256: (j['certSha256'] as String?)?.toLowerCase(),
      history: [
        for (final r in (j['history'] as List? ?? const []))
          if (r is Map) CatatanRilis.fromJson(Map<String, dynamic>.from(r)),
      ],
    );
  }

  bool lebihBaruDari(int terpasang) => build > terpasang;

  /// Wajib bila build terpasang di bawah batas minimum atau diblokir (rilis bermasalah).
  bool wajibUntuk(int terpasang) =>
      terpasang < minBuild || blockedBuilds.contains(terpasang);

  /// Arsitektur yang dipakai: milik ponsel bila tersedia di manifest, selain itu arm64.
  String abiDipakai(String abi) => apks.containsKey(abi) ? abi : 'arm64';

  String? apkUntuk(String abi) => apks[abiDipakai(abi)];

  String? sha256Untuk(String abi) => sha256[abiDipakai(abi)];

  /// Semua catatan rilis dari yang terbaru, selalu memuat build terbaru.
  List<CatatanRilis> get riwayat {
    final peta = {for (final r in history) r.build: r};
    peta.putIfAbsent(
      build,
      () => CatatanRilis(version: version, build: build, notes: notes),
    );
    return peta.values.toList()..sort((a, b) => b.build.compareTo(a.build));
  }
}

/// Bandingkan nama versi `a.b.c`; negatif bila [a] lebih rendah dari [b].
int bandingkanVersi(String a, String b) {
  List<int> bagian(String v) =>
      v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final x = bagian(a), y = bagian(b);
  for (var i = 0; i < 3; i++) {
    final d = (i < x.length ? x[i] : 0) - (i < y.length ? y[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}
