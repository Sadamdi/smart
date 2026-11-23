/// Mesin luring: menyimpan paket data beasiswa dan profil di perangkat, menghitung kelayakan dan estimasi peluang
/// sendiri (kode yang sama dengan server, diuji paritasnya), melayani daftar rekomendasi, Jelajah, simpan beasiswa,
/// ubah profil, dan chatbot berbasis data lokal. Perubahan yang dibuat saat luring masuk antrean dan dikirim ke server
/// saat jaringan kembali. Hasil lokal tidak memakai kemiripan teks dan pemeringkat LightGBM, jadi urutan bawaannya
/// memakai skor kelayakan; angka kelayakan dan estimasi peluang sama dengan server.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../api_client.dart';
import 'chat_lokal.dart';
import 'kelayakan.dart';
import 'peluang.dart';
import 'wilayah.dart';

class HasilLokal {
  HasilLokal(this.b, this.h, this.m, this.estimasi);

  final Map<String, dynamic> b;
  final HasilKelayakan h;
  final MetrikKartu m;
  final int? estimasi;

  DateTime? get tenggat =>
      b['tenggat'] == null ? null : DateTime.parse(b['tenggat'] as String);

  Map<String, dynamic> get ringkas => {
    'id': b['id'],
    'nama': b['nama'],
    'penyelenggara': b['penyelenggara'],
    'negara': b['negara'],
    'jenjang': b['jenjang'],
    'tenggat': b['tenggat'],
    'tautan_resmi': b['tautan_resmi'],
  };

  Map<String, dynamic> get kartu => {
    'kategori': h.kategori,
    'skor_kelayakan': m.skor,
    'syarat_terpenuhi': m.terpenuhi,
    'syarat_total': m.total,
    'luar_negeri': b['luar_negeri'],
    'estimasi_peluang': estimasi,
  };
}

class MesinLokal {
  MesinLokal([this._folder, this.otomatis = true]);

  /// Sinkron otomatis di latar belakang (dimatikan pada tes).
  final bool otomatis;

  /// Bila benar, chatbot luring dijawab model AI di ponsel (bukan jawaban berbasis aturan).
  bool Function() adaModelAi = () => false;

  Directory? _folder;
  TabelWilayah? _tabel;
  List<Map<String, dynamic>> _beasiswa = [];
  Map<String, dynamic>? _profil;
  Set<String> _tersimpan = {};
  Set<String> _berkas = {};
  List<Map<String, dynamic>> _antrean = [];
  List<HasilLokal>? _hasil;
  DateTime? _hari;
  double _kekuatan = 0;

  /// Sesi, pesan, dan salinan Memori Pintar di ponsel (lihat chat_lokal.dart).
  late final ChatLokal chat = ChatLokal(
    tulis: _tulis,
    antre: _antre,
    batalAntre: (cocok) {
      _antrean.removeWhere(cocok);
      _simpanAntrean();
    },
  );

  /// Mode luring dipilih pengguna: semua pembacaan dan penulisan dilayani lokal.
  final aktif = ValueNotifier<bool>(false);

  /// Sumber jawaban chatbot: otomatis (server bila ada jaringan, model di ponsel bila tidak), ponsel (selalu model di
  /// ponsel, walau ada internet), atau server. Mode luring selalu memakai ponsel.
  final modeAi = ValueNotifier<String>('otomatis');

  bool get aiLokalAktif => modeAi.value == 'ponsel';

  /// Jumlah perubahan yang menunggu dikirim ke server.
  final menunggu = ValueNotifier<int>(0);
  final terakhirSinkron = ValueNotifier<DateTime?>(null);
  final sedangSinkron = ValueNotifier<bool>(false);

  bool get siap => _tabel != null && _beasiswa.isNotEmpty && _profil != null;
  int get jumlahBeasiswa => _beasiswa.length;

  Future<Directory> _dir() async {
    final d =
        _folder ??
        Directory('${(await getApplicationSupportDirectory()).path}/lokal');
    if (!d.existsSync()) d.createSync(recursive: true);
    return _folder = d;
  }

  Future<File> _berkas_(String nama) async =>
      File('${(await _dir()).path}/$nama');

  Future<void> _tulis(String nama, Object? isi) async {
    try {
      await (await _berkas_(nama)).writeAsString(jsonEncode(isi));
    } on Object {
      // penyimpanan lokal hanya pelengkap
    }
  }

  Future<Object?> _baca(String nama) async {
    try {
      final f = await _berkas_(nama);
      if (!f.existsSync()) return null;
      return jsonDecode(await f.readAsString());
    } on Object {
      return null;
    }
  }

  /// Memuat tabel wilayah (aset) dan data yang sudah pernah disinkronkan.
  Future<void> muat({String? teksWilayah}) async {
    final w =
        teksWilayah ?? await rootBundle.loadString('assets/data/wilayah.json');
    _tabel = TabelWilayah.dariJson(jsonDecode(w) as Map<String, dynamic>);
    final b = await _baca('beasiswa.json');
    if (b is List) {
      _beasiswa = [for (final x in b) Map<String, dynamic>.from(x as Map)];
    }
    final p = await _baca('profil.json');
    if (p is Map) _profil = Map<String, dynamic>.from(p);
    final t = await _baca('tersimpan.json');
    if (t is List) _tersimpan = {for (final x in t) '$x'};
    final d = await _baca('berkas.json');
    if (d is List) _berkas = {for (final x in d) '$x'};
    chat.muat(
      pesan: await _baca('riwayat_chat.json'),
      sesi: await _baca('sesi_chat.json'),
      memori: await _baca('memori.json'),
    );
    final a = await _baca('antrean.json');
    if (a is List) {
      _antrean = [for (final x in a) Map<String, dynamic>.from(x as Map)];
    }
    final s = await _baca('status.json');
    if (s is Map) {
      aktif.value = (s['aktif'] ?? false) as bool;
      modeAi.value =
          (s['mode_ai'] as String?) ??
          ((s['ai_lokal'] ?? false) as bool ? 'ponsel' : 'otomatis');
      final ts = s['sinkron'] as String?;
      terakhirSinkron.value = ts == null ? null : DateTime.tryParse(ts);
    }
    menunggu.value = _antrean.length;
    _hasil = null;
  }

  Future<void> aturAktif(bool nilai) async {
    aktif.value = nilai;
    await _simpanStatus();
  }

  Future<void> aturModeAi(String nilai) async {
    modeAi.value = nilai;
    await _simpanStatus();
  }

  Future<void> _simpanStatus() => _tulis('status.json', {
    'aktif': aktif.value,
    'mode_ai': modeAi.value,
    'sinkron': terakhirSinkron.value?.toIso8601String(),
  });

  /// Menyimpan paket hasil unduhan server.
  Future<void> simpanSinkron({
    required List<Map<String, dynamic>> beasiswa,
    required Map<String, dynamic> profil,
    required Set<String> tersimpan,
    required Set<String> berkas,
  }) async {
    _beasiswa = beasiswa;
    _profil = profil;
    _tersimpan = tersimpan;
    _berkas = berkas;
    _hasil = null;
    terakhirSinkron.value = DateTime.now();
    await _tulis('beasiswa.json', beasiswa);
    await _tulis('profil.json', profil);
    await _tulis('tersimpan.json', tersimpan.toList());
    await _tulis('berkas.json', berkas.toList());
    await _simpanStatus();
  }

  Future<void> bersihkan() async {
    aktif.value = false;
    menunggu.value = 0;
    terakhirSinkron.value = null;
    _beasiswa = [];
    _profil = null;
    _tersimpan = {};
    _berkas = {};
    _antrean = [];
    _hasil = null;
    chat.kosongkan();
    try {
      final d = await _dir();
      if (d.existsSync()) d.deleteSync(recursive: true);
      _folder = null;
    } on Object {
      // abaikan
    }
  }

  // ---------- antrean ----------

  List<Map<String, dynamic>> get antrean => List.unmodifiable(_antrean);

  Future<void> _simpanAntrean() async {
    menunggu.value = _antrean.length;
    await _tulis('antrean.json', _antrean);
  }

  void _antre(String metode, String jalur, Object? body) {
    if (jalur == '/me/profil') {
      // Beberapa perubahan profil berturut-turut digabung menjadi satu kiriman.
      final i = _antrean.lastIndexWhere((e) => e['j'] == jalur);
      if (i >= 0) {
        final lama = Map<String, dynamic>.from(_antrean[i]['b'] as Map);
        _antrean[i] = {
          'm': metode,
          'j': jalur,
          'b': {...lama, ...(body as Map<String, dynamic>)},
        };
        _simpanAntrean();
        return;
      }
    } else if (jalur.contains('/interaksi')) {
      // Simpan lalu batal simpan pada beasiswa yang sama saling meniadakan.
      final id = jalur.split('/')[2];
      _antrean.removeWhere(
        (e) => (e['j'] as String).startsWith('/beasiswa/$id/interaksi'),
      );
    }
    _antrean.add({'m': metode, 'j': jalur, 'b': body});
    _simpanAntrean();
  }

  /// Mengirim antrean memakai [kirim]; berhenti bila jaringan putus, membuang yang ditolak server.
  Future<void> kosongkanAntrean(
    Future<void> Function(String metode, String jalur, Object? body) kirim,
  ) async {
    while (_antrean.isNotEmpty) {
      final e = _antrean.first;
      try {
        await kirim(e['m'] as String, e['j'] as String, e['b']);
      } on ApiException catch (x) {
        if (x.galatJaringan) return;
        // ditolak server (mis. beasiswa sudah dihapus): lewati agar antrean tidak macet
      }
      _antrean.removeAt(0);
      await _simpanAntrean();
    }
  }

  // ---------- profil ----------

  ProfilKelayakan _profilKelayakan() {
    final p = _profil ?? const {};
    final pl = (p['profil_lanjutan'] as Map?)?.cast<String, dynamic>() ?? {};
    final tuju =
        ((pl['target_studi'] as Map?)?['jenjang'] as List?) ?? const [];
    String? s(String k) => p[k] as String?;
    return ProfilKelayakan(
      jenjang: s('jenjang'),
      semester: p['semester'] as int?,
      ipk: p['ipk'] == null ? null : double.tryParse('${p['ipk']}'),
      jenisKampus: s('jenis_kampus'),
      kotaDomisili: s('kota_domisili'),
      negaraDomisili: s('negara_domisili'),
      provinsiDomisili: s('provinsi_domisili'),
      daerahAsal: [
        for (final x in [pl['kota_asal'], pl['provinsi_asal']])
          if (x is String && x.isNotEmpty) x,
      ],
      tanggalLahir: s('tanggal_lahir') == null
          ? null
          : DateTime.tryParse(s('tanggal_lahir')!),
      penghasilanOrangTua: p['penghasilan_orang_tua'] as num?,
      skorBahasa: (p['skor_bahasa'] as Map?)?.cast<String, dynamic>(),
      kewarganegaraan: s('kewarganegaraan'),
      berkasDiunggah: _berkas,
      jenjangTuju: [
        for (final x in tuju)
          if (x is String) x,
      ],
    );
  }

  /// Saran pertanyaan dari basis data di ponsel (tanpa jaringan, tanpa model): beasiswa paling cocok dan tenggat terdekat.
  List<String> saranData() {
    if (!siap) return const [];
    String pendek(String n) => n.length > 32 ? '${n.substring(0, 30)}…' : n;
    final hasil = hitung();
    if (hasil.isEmpty) return const [];
    final cocok = [...hasil]..sort((a, b) => (b.m.skor ?? 0).compareTo(a.m.skor ?? 0));
    final sekarang = DateTime.now();
    final dekat = hasil.where((x) => x.tenggat?.isAfter(sekarang) ?? false).toList()
      ..sort((a, b) => a.tenggat!.compareTo(b.tenggat!));
    return [
      'Syarat lengkap ${pendek('${cocok.first.b['nama']}')}',
      if (dekat.isNotEmpty)
        'Kapan tenggat ${pendek('${dekat.first.b['nama']}')}?',
      if (cocok.length > 1) 'Bandingkan ${pendek('${cocok[0].b['nama']}')} dan ${pendek('${cocok[1].b['nama']}')}',
    ];
  }

  List<HasilLokal> hitung([DateTime? sekarang]) {
    final hari0 = sekarang ?? DateTime.now();
    final hari = DateTime(hari0.year, hari0.month, hari0.day);
    if (_hasil != null && _hari == hari) return _hasil!;
    final profil = _profilKelayakan();
    final pl = (_profil?['profil_lanjutan'] as Map?)?.cast<String, dynamic>();
    final kuat = kekuatanProfil(
      profil.ipk,
      pl,
      profil.skorBahasa == null || profil.skorBahasa!.isEmpty
          ? null
          : profil.skorBahasa,
    );
    _kekuatan = kuat;
    final hasil = <HasilLokal>[];
    for (final b in _beasiswa) {
      final tg = b['tenggat'] == null
          ? null
          : DateTime.parse(b['tenggat'] as String);
      if (tg != null && tg.isBefore(hari)) continue;
      final syarat = <Syarat>[
        for (final s in (b['syarat'] as List? ?? const []))
          ((s as List)[0] as String, (s[1] as Map?)?.cast<String, dynamic>()),
      ];
      final h = nilaiKelayakan(_tabel!, syarat, profil, hari);
      final m = metrik(h.skor, h.alasan, h.catatan);
      final est = estimasiPeluang(
        kategori: h.kategori,
        adaSyaratTerukur: m.total > 0,
        nama: b['nama'] as String,
        penyelenggara: b['penyelenggara'] as String?,
        luarNegeri: (b['luar_negeri'] ?? false) as bool,
        kekuatan: kuat,
        dasarStatistik: (b['dasar_statistik'] as num?)?.toDouble(),
        jumlahSyarat: m.total,
      );
      hasil.add(HasilLokal(b, h, m, est));
    }
    const urutan = {memenuhi: 0, hampir: 1, belum: 2};
    hasil.sort((a, b) {
      final k = urutan[a.h.kategori]!.compareTo(urutan[b.h.kategori]!);
      if (k != 0) return k;
      final s = b.h.skor.compareTo(a.h.skor);
      if (s != 0) return s;
      return (a.tenggat ?? DateTime(9999)).compareTo(
        b.tenggat ?? DateTime(9999),
      );
    });
    _hari = hari;
    return _hasil = hasil;
  }

  bool _wilayahSesuai(HasilLokal x, String? wilayah) {
    final luar = (x.b['luar_negeri'] ?? false) as bool;
    if (wilayah == 'luar') return luar;
    if (wilayah == 'dalam') return !luar;
    return true;
  }

  // ---------- pembacaan ----------

  Respons? layaniGet(String jalur, Map<String, dynamic>? query) {
    final c = chat.layaniGet(jalur, query);
    if (c != null) return c;
    if (!siap) return null;
    final q = query ?? const <String, dynamic>{};
    switch (jalur) {
      case '/me':
        return Respons(_profil, null);
      case '/rekomendasi':
        var daftar = hitung()
            .where((x) => _wilayahSesuai(x, q['wilayah'] as String?))
            .toList();
        final kat = q['kategori'] as String?;
        if (kat != null && kat.isNotEmpty) {
          daftar = daftar.where((x) => x.h.kategori == kat).toList();
        }
        final minP = int.tryParse('${q['min_peluang'] ?? 0}') ?? 0;
        if (minP > 0) {
          daftar = daftar.where((x) => (x.estimasi ?? 0) >= minP).toList();
        }
        final urut = (q['urut'] ?? 'peluang') as String;
        if (urut == 'peluang') {
          daftar.sort((a, b) => (b.estimasi ?? -1).compareTo(a.estimasi ?? -1));
        } else if (urut == 'tenggat') {
          daftar.sort(
            (a, b) => (a.tenggat ?? DateTime(9999)).compareTo(
              b.tenggat ?? DateTime(9999),
            ),
          );
        }
        final batas = int.tryParse('${q['batas'] ?? 0}') ?? 0;
        if (batas > 0 && daftar.length > batas) {
          daftar = daftar.sublist(0, batas);
        }
        return Respons([
          for (final x in daftar)
            {
              'beasiswa': x.ringkas,
              ...x.kartu,
              'alasan': x.h.alasan,
              'catatan_kekurangan': x.h.catatan,
              'tenggat': x.b['tenggat'],
            },
        ], null);
      case '/rekomendasi/ringkasan':
        final hasil = {memenuhi: 0, hampir: 0, belum: 0};
        for (final x in hitung().where(
          (x) => _wilayahSesuai(x, q['wilayah'] as String?),
        )) {
          hasil[x.h.kategori] = hasil[x.h.kategori]! + 1;
        }
        return Respons(hasil, null);
      case '/beasiswa':
        return _jelajah(q);
      case '/me/tersimpan':
        return Respons([
          for (final x in hitung().where((x) => _tersimpan.contains(x.b['id'])))
            {'beasiswa': x.ringkas},
        ], null);
      case '/chat/status':
        return Respons({'tersedia': true}, null);
      case '/me/kalender':
        return _kalender(q);
    }
    final d = RegExp(r'^/beasiswa/([^/]+)$').firstMatch(jalur);
    if (d != null) return _detail(d.group(1)!);
    return null;
  }

  static const _dapatDikejar = {
    'ipk_minimum',
    'sertifikat_bahasa',
    'semester_minimum',
    'berkas_pendukung',
  };

  /// Detail beasiswa dari paket lokal, dinilai terhadap profil di ponsel.
  Respons? _detail(String id) {
    final x = hitung().where((e) => e.b['id'] == id).firstOrNull;
    if (x == null) return null;
    final syarat = (x.b['syarat'] as List? ?? const []);
    final dasar = (x.b['dasar_statistik'] as num?)?.toDouble();
    final tingkat = dasar != null
        ? null
        : tingkatPersaingan(
            '${x.b['nama']}',
            x.b['penyelenggara'] as String?,
            (x.b['luar_negeri'] ?? false) as bool,
          );
    return Respons({
      ...x.ringkas,
      ...x.kartu,
      'manfaat': x.b['manfaat'],
      'tanggal_diperiksa': x.b['tanggal_diperiksa'],
      'persyaratan': [
        for (var i = 0; i < syarat.length; i++)
          {
            'jenis': (syarat[i] as List)[0],
            'nilai_batas': syarat[i][1],
            'dapat_dikejar': _dapatDikejar.contains((syarat[i] as List)[0]),
            'status': i < x.h.rincian.length ? x.h.rincian[i]?.status : null,
            'catatan': i < x.h.rincian.length
                ? (x.h.rincian[i]?.status == 'terpenuhi'
                      ? x.h.rincian[i]?.alasan
                      : x.h.rincian[i]?.kekurangan)
                : null,
          },
      ],
      'berkas_wajib': x.b['berkas_wajib'] ?? const [],
      'alasan': x.h.alasan,
      'catatan_kekurangan': x.h.catatan,
      'alasan_peluang': x.estimasi == null
          ? const <String>[]
          : alasanPeluang(
              x.h.kategori,
              tingkat,
              _kekuatan,
              dasar != null,
              x.m.total < syaratCukup,
            ),
      'dasar_peluang': dasar != null ? 'statistik' : 'perkiraan',
      'statistik_seleksi': x.b['statistik'] ?? const [],
      'tingkat_persaingan': tingkat,
    }, null);
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Kalender: tenggat beasiswa tersimpan dan rekomendasi (memenuhi atau hampir) pada rentang yang diminta.
  Respons _kalender(Map<String, dynamic> q) {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final dari = DateTime.tryParse('${q['dari'] ?? ''}') ?? hariIni;
    final sampai =
        DateTime.tryParse('${q['sampai'] ?? ''}') ??
        hariIni.add(const Duration(days: 120));
    final acara = <Map<String, dynamic>>[];
    var rekom = 0;
    for (final x in hitung()) {
      final tg = x.tenggat;
      if (tg == null || tg.isBefore(dari) || tg.isAfter(sampai)) continue;
      final simpan = _tersimpan.contains(x.b['id']);
      if (simpan) {
        acara.add({
          'jenis': 'tenggat',
          'tanggal': _iso(tg),
          'judul': x.b['nama'],
          'ref_id': x.b['id'],
          'selesai': false,
        });
      } else if (x.h.kategori != belum && !tg.isBefore(hariIni) && rekom < 60) {
        rekom++;
        acara.add({
          'jenis': 'rekomendasi',
          'tanggal': _iso(tg),
          'judul': x.b['nama'],
          'ref_id': x.b['id'],
          'selesai': false,
          'kategori': x.h.kategori,
        });
      }
    }
    acara.sort((a, b) => '${a['tanggal']}'.compareTo('${b['tanggal']}'));
    return Respons(acara, null);
  }

  Respons _jelajah(Map<String, dynamic> q) {
    var daftar = hitung()
        .where((x) => _wilayahSesuai(x, q['wilayah'] as String?))
        .toList();
    final kata = ('${q['q'] ?? ''}').toLowerCase().trim();
    if (kata.isNotEmpty) {
      daftar = daftar
          .where(
            (x) => '${x.b['nama']} ${x.b['penyelenggara'] ?? ''}'
                .toLowerCase()
                .contains(kata),
          )
          .toList();
    }
    final jenjang = '${q['jenjang'] ?? ''}';
    if (jenjang.isNotEmpty) {
      daftar = daftar
          .where(
            (x) => ((x.b['jenjang'] as List?) ?? const []).contains(jenjang),
          )
          .toList();
    }
    daftar.sort(
      (a, b) =>
          (a.tenggat ?? DateTime(9999)).compareTo(b.tenggat ?? DateTime(9999)),
    );
    final batas = int.tryParse('${q['batas'] ?? 20}') ?? 20;
    final awal = int.tryParse('${q['kursor'] ?? 0}') ?? 0;
    final halaman = daftar.skip(awal).take(batas).toList();
    final berikut = awal + batas < daftar.length ? '${awal + batas}' : null;
    return Respons(
      [
        for (final x in halaman) {...x.ringkas, ...x.kartu},
      ],
      {'kursor_berikut': berikut},
    );
  }

  // ---------- penulisan ----------

  Respons? layaniTulis(String metode, String jalur, Object? body) {
    final c = chat.layaniTulis(metode, jalur, body);
    if (c != null) return c;
    if (!siap) return null;
    if (metode == 'PUT' &&
        jalur == '/me/profil' &&
        body is Map<String, dynamic>) {
      _profil = {..._profil!, ...body};
      _hasil = null;
      _tulis('profil.json', _profil);
      _antre(metode, jalur, body);
      return Respons(_profil, null);
    }
    final m = RegExp(r'^/beasiswa/([^/]+)/interaksi(/simpan)?$')
        .firstMatch(jalur);
    if (m != null) {
      final id = m.group(1)!;
      if (metode == 'POST' && body is Map && body['aksi'] == 'simpan') {
        _tersimpan.add(id);
      } else if (metode == 'DELETE' && m.group(2) != null) {
        _tersimpan.remove(id);
      } else {
        return null; // klik dan rencana daftar tidak dilayani lokal
      }
      _tulis('tersimpan.json', _tersimpan.toList());
      _antre(metode, jalur, body);
      return Respons({}, null);
    }
    if (metode == 'POST' && jalur == '/rekomendasi/hitung-ulang') {
      _hasil = null;
      return layaniGet('/rekomendasi', const {});
    }
    if (metode == 'POST' && jalur == '/chat' && body is Map) {
      if (adaModelAi() && !aktif.value) {
        return null; // jaringan putus tetapi model siap: biarkan jalur model menjawab
      }
      final j = _jawabChat('${body['pesan'] ?? ''}');
      chat.catatChat({...j, 'sesi_id': body['sesi_id'], 'lokal': true});
      return Respons(j, null);
    }
    return null;
  }

  // ---------- chatbot lokal ----------

  /// Tautan laman resmi beasiswa yang namanya sama dengan [nama], dari paket lokal.
  String? tautanResmi(String nama) {
    for (final b in _beasiswa) {
      if (b['nama'] == nama) return b['tautan_resmi'] as String?;
    }
    return null;
  }

  /// Beasiswa yang dipakai pada konteks terakhir (untuk ditampilkan sebagai sumber jawaban).
  List<Map<String, dynamic>> sumberTerakhir = const [];

  /// Alat simulasi: hitung ulang rekomendasi bila IPK diganti, tanpa mengubah profil.
  String _simulasiIpk(double ipk) {
    final hari0 = DateTime.now();
    final hari = DateTime(hari0.year, hari0.month, hari0.day);
    final profil = _profilKelayakan().salin(ipk: ipk);
    final hitungan = {memenuhi: 0, hampir: 0, belum: 0};
    final baru = <(String, String, int?)>[];
    final lama = {for (final x in hitung()) '${x.b['id']}': x.h.kategori};
    for (final b in _beasiswa) {
      final tg = b['tenggat'] == null
          ? null
          : DateTime.parse(b['tenggat'] as String);
      if (tg != null && tg.isBefore(hari)) continue;
      final syarat = <Syarat>[
        for (final x in (b['syarat'] as List? ?? const []))
          ((x as List)[0] as String, (x[1] as Map?)?.cast<String, dynamic>()),
      ];
      final h = nilaiKelayakan(_tabel!, syarat, profil, hari);
      hitungan[h.kategori] = hitungan[h.kategori]! + 1;
      if (lama['${b['id']}'] != null &&
          lama['${b['id']}'] != memenuhi &&
          h.kategori == memenuhi) {
        baru.add(('${b['nama']}', h.kategori, null));
      }
    }
    final buf = StringBuffer(
      'HASIL ALAT SIMULASI (dihitung di ponsel): bila IPK $ipk, memenuhi ${hitungan[memenuhi]}, hampir memenuhi ${hitungan[hampir]}, belum memenuhi ${hitungan[belum]}.',
    );
    if (baru.isNotEmpty) {
      buf.write(
        ' Beasiswa yang baru menjadi memenuhi: ${baru.take(5).map((e) => e.$1).join('; ')}.',
      );
    }
    return buf.toString();
  }

  /// Ringkasan data untuk model AI: profil singkat dan beasiswa yang relevan dengan [pesan].
  String konteksChat(String pesan) {
    final t = pesan.toLowerCase();
    final semua = hitung();
    final p = _profil ?? const {};
    final buf = StringBuffer(
      'Profil: jenjang ${p['jenjang'] ?? '-'}, semester ${p['semester'] ?? '-'}, IPK ${p['ipk'] ?? '-'}, kota ${p['kota_domisili'] ?? '-'}.\n',
    );
    final memori = chat.ringkasMemori();
    if (memori.isNotEmpty) {
      buf.writeln('Memori tentang pengguna:\n- ${memori.join('\n- ')}');
    }
    final disebut = semua
        .where((x) {
          final kata = ('${x.b['nama']}')
              .toLowerCase()
              .split(RegExp(r'\s+'))
              .where(
                (k) =>
                    k.length > 3 &&
                    !{'beasiswa', 'program', 'untuk', 'tahun'}.contains(k),
              )
              .take(2)
              .toList();
          return kata.isNotEmpty && kata.every(t.contains);
        })
        .take(2)
        .toList();
    final pilih = <HasilLokal>[...disebut];
    final urut =
        semua.where((x) => x.h.kategori != belum && !pilih.contains(x)).toList()
          ..sort((a, b) => (b.estimasi ?? -1).compareTo(a.estimasi ?? -1));
    if (RegExp(r'tenggat|deadline|kapan').hasMatch(t)) {
      final dekat =
          semua
              .where(
                (x) =>
                    x.tenggat != null &&
                    x.h.kategori != belum &&
                    !pilih.contains(x),
              )
              .toList()
            ..sort((a, b) => a.tenggat!.compareTo(b.tenggat!));
      pilih.addAll(dekat.take(4));
    }
    pilih.addAll(urut.take(6 - pilih.length.clamp(0, 5)));
    buf.writeln('Beasiswa:');
    for (final x in pilih) {
      final syarat = [
        for (final s in (x.b['syarat'] as List? ?? const []).take(
          disebut.contains(x) ? 12 : 4,
        ))
          '${(s as List)[0]} ${jsonEncode(s[1])}',
      ];
      buf.writeln(
        '- ${x.b['nama']} | ${x.b['penyelenggara'] ?? 'penyelenggara belum tercatat'} | tenggat ${_tgl(x.b['tenggat'] as String?)} | kategori ${x.h.kategori.replaceAll('_', ' ')} | estimasi peluang ${x.estimasi ?? 'belum ada'} persen (perkiraan) | syarat: ${syarat.join('; ')}',
      );
    }
    sumberTerakhir = [
      for (final x in pilih)
        {
          'id': x.b['id'],
          'nama': x.b['nama'],
          'tautan_resmi': x.b['tautan_resmi'],
        },
    ];
    final m = RegExp(
      r'ipk\s*(?:menjadi|jadi|naik|=|di|ke)?\s*(\d)[.,](\d{1,2})',
    ).firstMatch(t);
    if (m != null &&
        RegExp(r'jika|kalau|andai|seandainya|bagaimana').hasMatch(t)) {
      final ipk = double.tryParse('${m.group(1)}.${m.group(2)}');
      if (ipk != null && ipk >= 0 && ipk <= 4) buf.writeln(_simulasiIpk(ipk));
    }
    return buf.toString();
  }

  String _tgl(String? iso) {
    if (iso == null) return 'belum diumumkan';
    final d = DateTime.parse(iso);
    const bln = [
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
    return '${d.day} ${bln[d.month - 1]} ${d.year}';
  }

  Map<String, dynamic> _jawabChat(String pesan) {
    final t = pesan.toLowerCase();
    final semua = hitung();
    final rujukan = <HasilLokal>[];
    String jawab;
    final sebut = semua
        .where((x) {
          final nama = ('${x.b['nama']}').toLowerCase();
          final kata = nama
              .split(RegExp(r'\s+'))
              .where(
                (k) =>
                    k.length > 3 &&
                    !{'beasiswa', 'program', 'untuk', 'tahun'}.contains(k),
              )
              .toList();
          return t.contains(nama) ||
              (kata.isNotEmpty && kata.take(2).every(t.contains));
        })
        .take(2)
        .toList();
    String baris(HasilLokal x) =>
        '- ${x.b['nama']} (${x.b['penyelenggara'] ?? 'penyelenggara belum tercatat'}), tenggat ${_tgl(x.b['tenggat'] as String?)}'
        '${x.estimasi == null ? '' : ', estimasi peluang sekitar ${x.estimasi} persen (perkiraan)'}';
    if (sebut.isNotEmpty &&
        (t.contains('syarat') ||
            t.contains('info') ||
            t.contains('detail') ||
            t.contains('tentang') ||
            sebut.length == 1)) {
      final x = sebut.first;
      rujukan.add(x);
      final syarat = [
        for (final s in (x.b['syarat'] as List? ?? const []))
          '${(s as List)[0]}: ${jsonEncode(s[1])}',
      ];
      jawab =
          '${x.b['nama']} diselenggarakan ${x.b['penyelenggara'] ?? 'penyelenggara belum tercatat'}. Tenggat ${_tgl(x.b['tenggat'] as String?)}. '
          'Kategori untukmu: ${x.h.kategori.replaceAll('_', ' ')}. '
          '${syarat.isEmpty ? 'Syarat belum tercatat, periksa laman resmi.' : 'Syarat tercatat: ${syarat.join('; ')}.'}';
    } else if (RegExp(r'tenggat|deadline|kapan|batas').hasMatch(t)) {
      final dekat =
          semua
              .where((x) => x.tenggat != null && x.h.kategori != belum)
              .toList()
            ..sort((a, b) => a.tenggat!.compareTo(b.tenggat!));
      rujukan.addAll(dekat.take(3));
      jawab = dekat.isEmpty
          ? 'Belum ada beasiswa bertenggat yang sesuai di data lokal.'
          : 'Tenggat terdekat yang sesuai untukmu:\n${dekat.take(3).map(baris).join('\n')}';
    } else if (RegExp(r'luar negeri|abroad|overseas').hasMatch(t)) {
      final l = semua
          .where(
            (x) =>
                (x.b['luar_negeri'] ?? false) as bool && x.h.kategori != belum,
          )
          .take(3)
          .toList();
      rujukan.addAll(l);
      jawab = l.isEmpty
          ? 'Belum ada beasiswa luar negeri yang sesuai di data lokal.'
          : 'Beasiswa luar negeri yang mungkin cocok:\n${l.map(baris).join('\n')}';
    } else {
      final urut = semua.where((x) => x.h.kategori != belum).toList()
        ..sort((a, b) => (b.estimasi ?? -1).compareTo(a.estimasi ?? -1));
      rujukan.addAll(urut.take(3));
      jawab = urut.isEmpty
          ? 'Belum ada rekomendasi di data lokal. Lengkapi profil lalu sinkronkan saat ada jaringan.'
          : 'Mode luring: saya menjawab dari data di perangkat, bukan dari layanan AI. Beasiswa yang paling mungkin cocok:\n${urut.take(3).map(baris).join('\n')}';
    }
    jawab += '\nEstimasi hanya perkiraan dan bukan jaminan diterima. Saat ada jaringan, chatbot AI dapat menjawab lebih lengkap.';
    return {
      'id':
          '00000000-0000-4000-8000-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0')}',
      'pesan': pesan,
      'jawaban': jawab,
      'sumber': 'lokal',
      'waktu': DateTime.now().toIso8601String(),
      'rujukan': [
        for (final x in rujukan)
          {
            'id': x.b['id'],
            'nama': x.b['nama'],
            'tautan_resmi': x.b['tautan_resmi'],
          },
      ],
    };
  }
}
