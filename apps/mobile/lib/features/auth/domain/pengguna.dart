class Pengguna {
  const Pengguna({
    required this.id,
    required this.email,
    required this.nama,
    this.tanggalLahir,
    this.kotaDomisili,
    this.kampus,
    this.jenisKampus,
    this.programStudi,
    this.jenjang,
    this.semester,
    this.ipk,
    this.ipsTerakhir,
    this.minat = const [],
    this.penghasilanOrangTua,
    this.kewarganegaraan,
    this.kondisiKhusus = const [],
    this.catatanTambahan,
    this.notifEmail = true,
    this.notifPush = true,
    this.profilLanjutan = const {},
    this.skorBahasa = const {},
  });

  final String id;
  final String email;
  final String nama;
  final String? tanggalLahir;
  final String? kotaDomisili;
  final String? kampus;
  final String? jenisKampus;
  final String? programStudi;
  final String? jenjang;
  final int? semester;
  final String? ipk;
  final String? ipsTerakhir;
  final List<String> minat;
  final int? penghasilanOrangTua;
  final String? kewarganegaraan;
  final List<String> kondisiKhusus;
  final String? catatanTambahan;
  final bool notifEmail;
  final bool notifPush;
  final Map<String, dynamic> profilLanjutan;
  final Map<String, dynamic> skorBahasa;

  /// Kelengkapan profil dari tujuh syarat yang paling sering diminta beasiswa (sama dengan web). Kolom lain opsional.
  ({int terisi, int total}) get kelengkapan {
    final nilai = <bool>[
      (jenjang ?? '').isNotEmpty,
      semester != null,
      (ipk ?? '').isNotEmpty,
      (jenisKampus ?? '').isNotEmpty,
      (kotaDomisili ?? '').isNotEmpty,
      (kewarganegaraan ?? '').isNotEmpty,
      (tanggalLahir ?? '').isNotEmpty,
    ];
    return (terisi: nilai.where((x) => x).length, total: nilai.length);
  }

  bool get profilLengkap => kelengkapan.terisi == kelengkapan.total;

  String get namaDepan => nama.trim().split(RegExp(r'\s+')).first;

  factory Pengguna.fromJson(Map<String, dynamic> j) => Pengguna(
    id: j['id'] as String,
    email: j['email'] as String,
    nama: j['nama'] as String,
    tanggalLahir: j['tanggal_lahir'] as String?,
    kotaDomisili: j['kota_domisili'] as String?,
    kampus: j['kampus'] as String?,
    jenisKampus: j['jenis_kampus'] as String?,
    programStudi: j['program_studi'] as String?,
    jenjang: j['jenjang'] as String?,
    semester: j['semester'] as int?,
    ipk: j['ipk']?.toString(),
    ipsTerakhir: j['ips_terakhir']?.toString(),
    minat: [for (final x in (j['minat'] as List? ?? [])) '$x'],
    penghasilanOrangTua: j['penghasilan_orang_tua'] as int?,
    kewarganegaraan: j['kewarganegaraan'] as String?,
    kondisiKhusus: [for (final x in (j['kondisi_khusus'] as List? ?? [])) '$x'],
    catatanTambahan: j['catatan_tambahan'] as String?,
    notifEmail: (j['preferensi_notifikasi'] as Map?)?['email'] as bool? ?? true,
    notifPush: (j['preferensi_notifikasi'] as Map?)?['push'] as bool? ?? true,
    profilLanjutan: Map<String, dynamic>.from(
      j['profil_lanjutan'] as Map? ?? {},
    ),
    skorBahasa: Map<String, dynamic>.from(j['skor_bahasa'] as Map? ?? {}),
  );
}

/// Masukan pembaruan profil (PUT /me/profil). Hanya kolom non-null yang dikirim.
class ProfilMasukan {
  const ProfilMasukan({
    this.nama,
    this.kampus,
    this.jenisKampus,
    this.programStudi,
    this.jenjang,
    this.semester,
    this.ipk,
    this.kotaDomisili,
    this.minat,
    this.kondisiKhusus,
    this.catatanTambahan,
    this.profilLanjutan,
    this.tanggalLahir,
    this.ipsTerakhir,
    this.penghasilanOrangTua,
    this.kewarganegaraan,
    this.skorBahasa,
  });

  final String? tanggalLahir;
  final double? ipsTerakhir;
  final int? penghasilanOrangTua;
  final String? kewarganegaraan;
  final Map<String, dynamic>? skorBahasa;
  final String? nama;
  final String? kampus;
  final String? jenisKampus;
  final String? programStudi;
  final String? jenjang;
  final int? semester;
  final double? ipk;
  final String? kotaDomisili;
  final List<String>? minat;
  final List<String>? kondisiKhusus;
  final String? catatanTambahan;
  final Map<String, dynamic>? profilLanjutan;

  Map<String, dynamic> toJson() => {
    if (nama != null) 'nama': nama,
    if (kampus != null) 'kampus': kampus,
    if (jenisKampus != null) 'jenis_kampus': jenisKampus,
    if (programStudi != null) 'program_studi': programStudi,
    if (jenjang != null) 'jenjang': jenjang,
    if (semester != null) 'semester': semester,
    if (ipk != null) 'ipk': ipk,
    if (kotaDomisili != null) 'kota_domisili': kotaDomisili,
    if (minat != null) 'minat': minat,
    if (kondisiKhusus != null) 'kondisi_khusus': kondisiKhusus,
    if (catatanTambahan != null) 'catatan_tambahan': catatanTambahan,
    if (profilLanjutan != null) 'profil_lanjutan': profilLanjutan,
    if (tanggalLahir != null) 'tanggal_lahir': tanggalLahir,
    if (ipsTerakhir != null) 'ips_terakhir': ipsTerakhir,
    if (penghasilanOrangTua != null)
      'penghasilan_orang_tua': penghasilanOrangTua,
    if (kewarganegaraan != null) 'kewarganegaraan': kewarganegaraan,
    if (skorBahasa != null && skorBahasa!.isNotEmpty) 'skor_bahasa': skorBahasa,
  };
}
