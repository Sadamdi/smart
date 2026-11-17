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

  Directory? _folder;
  TabelWilayah? _tabel;
  List<Map<String, dynamic>> _beasiswa = [];
  Map<String, dynamic>? _profil;
  Set<String> _tersimpan = {};
  Set<String> _berkas = {};
  List<Map<String, dynamic>> _antrean = [];
  List<HasilLokal>? _hasil;
  DateTime? _hari;

  /// Mode luring dipilih pengguna: semua pembacaan dan penulisan dilayani lokal.
  final aktif = ValueNotifier<bool>(false);

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
    final a = await _baca('antrean.json');
    if (a is List) {
      _antrean = [for (final x in a) Map<String, dynamic>.from(x as Map)];
    }
    final s = await _baca('status.json');
    if (s is Map) {
      aktif.value = (s['aktif'] ?? false) as bool;
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

  Future<void> _simpanStatus() => _tulis('status.json', {
    'aktif': aktif.value,
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
    }
    return null;
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
      return Respons(_jawabChat('${body['pesan'] ?? ''}'), null);
    }
    return null;
  }

  // ---------- chatbot lokal ----------

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
