/// Penyimpanan chat di ponsel: sesi (utas) percakapan, pesan, dan salinan Memori Pintar.
///
/// Dipakai mesin luring untuk melayani chat tanpa server dan oleh repositori chat sebagai cermin dari server, sehingga
/// riwayat tetap terbaca saat internet mati. Sesi dan pesan yang dibuat di ponsel diberi tanda `lokal` sampai berhasil
/// disalin ke server; penanda itu dipakai agar jawaban model ponsel tidak hilang saat riwayat server dimuat ulang.
library;

import 'dart:math' as math;

import '../api_client.dart';

typedef Peta = Map<String, dynamic>;

const judulBawaan = 'Percakapan baru';

class ChatLokal {
  ChatLokal({
    required this.tulis,
    required this.antre,
    required this.batalAntre,
  });

  /// Menyimpan berkas JSON (nama, isi).
  final void Function(String nama, Object? isi) tulis;

  /// Memasukkan perubahan ke antrean sinkron ke server.
  final void Function(String metode, String jalur, Object? body) antre;

  /// Membuang item antrean yang cocok (mis. butir memori buatan luring yang dihapus lagi sebelum terkirim).
  final void Function(bool Function(Peta e) cocok) batalAntre;

  static const batasPesan = 400;

  /// Penghitung agar id tetap unik walau dua sesi dibuat dalam waktu yang sama.
  static int _urut = 0;

  List<Peta> _pesan = [];
  List<Peta> _sesi = [];
  List<Peta> _memori = [];
  bool _memoriAktif = true;
  bool _memoriPernah = false;

  void muat({Object? pesan, Object? sesi, Object? memori}) {
    List<Peta> daftar(Object? x) => x is List
        ? [
            for (final e in x)
              if (e is Map) Peta.from(e),
          ]
        : <Peta>[];
    _pesan = daftar(pesan);
    _sesi = daftar(sesi);
    if (memori is Map) {
      _memoriPernah = true;
      _memoriAktif = (memori['aktif'] ?? true) as bool;
      _memori = daftar(memori['butir']);
    }
    // Pesan lama (sebelum ada sesi) dikelompokkan ke satu sesi agar tetap terlihat.
    final tanpaSesi = _pesan.where((m) => m['sesi_id'] == null).toList();
    if (tanpaSesi.isNotEmpty) {
      final s = buatSesi(judul: 'Percakapan sebelumnya');
      for (final m in tanpaSesi) {
        m['sesi_id'] = s['id'];
        // Format lama menandai buatan ponsel lewat sumber; hanya itu yang masih perlu disalin ke server.
        m['lokal'] =
            m['lokal'] == true ||
            m['sumber'] == 'ponsel' ||
            m['sumber'] == 'lokal';
      }
      // Sesi hasil migrasi tanpa pesan tertunda tidak perlu ditandai belum tersalin.
      s['lokal'] = tanpaSesi.any((m) => m['lokal'] == true);
      _simpanSesi();
      _simpanPesan();
    }
  }

  void kosongkan() {
    _pesan = [];
    _sesi = [];
    _memori = [];
    _memoriAktif = true;
    _memoriPernah = false;
  }

  void _simpanPesan() => tulis('riwayat_chat.json', _pesan);
  void _simpanSesi() => tulis('sesi_chat.json', _sesi);
  void _simpanMemori() =>
      tulis('memori.json', {'aktif': _memoriAktif, 'butir': _memori});

  static String _sekarang() => DateTime.now().toIso8601String();

  static DateTime _waktu(Object? x) =>
      DateTime.tryParse('$x') ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Judul sementara dari awal pesan, dipakai di ponsel sampai server memberi judul dari topiknya.
  static String judulDari(String pesan) {
    final kata = pesan.trim().split(RegExp(r'\s+'));
    final t = kata.take(7).join(' ');
    final j = kata.length > 7 ? '$t ...' : t;
    return j.isEmpty ? judulBawaan : (j.length > 60 ? j.substring(0, 60) : j);
  }

  // ---------- sesi ----------

  Peta buatSesi({String? judul}) {
    final j = (judul ?? '').trim();
    final s = <String, dynamic>{
      'id': 'lokal-s-${DateTime.now().microsecondsSinceEpoch}-${_urut++}',
      'judul': j.isEmpty ? judulBawaan : j,
      'dibuat_pada': _sekarang(),
      'diubah_pada': _sekarang(),
      'lokal': true,
    };
    _sesi = [..._sesi, s];
    _simpanSesi();
    return s;
  }

  bool adaSesi(String id) => _sesi.any((s) => s['id'] == id);

  List<Peta> daftarSesi() {
    final hitung = <String, int>{};
    for (final m in _pesan) {
      final k = '${m['sesi_id']}';
      hitung[k] = (hitung[k] ?? 0) + 1;
    }
    final urut = [..._sesi]
      ..sort(
        (a, b) => _waktu(b['diubah_pada']).compareTo(_waktu(a['diubah_pada'])),
      );
    return [
      for (final s in urut)
        {
          ...s,
          'jumlah': math.max(
            hitung['${s['id']}'] ?? 0,
            (s['jumlah'] as num?)?.toInt() ?? 0,
          ),
        },
    ];
  }

  Peta? sesiTerbaru() {
    final d = daftarSesi();
    return d.isEmpty ? null : d.first;
  }

  /// Mengubah judul. [otomatis] benar bila judul berasal dari sistem (bukan diketik pengguna), sehingga server
  /// boleh menggantinya dengan judul dari topik percakapan.
  void ubahJudul(String id, String judul, {bool otomatis = false}) {
    for (final s in _sesi) {
      if (s['id'] == id) {
        s['judul'] = judul;
        s['judul_otomatis'] = otomatis;
      }
    }
    _simpanSesi();
  }

  /// Menyimpan sesi yang baru dibuat di server agar tetap dikenal saat internet mati.
  void terimaSesi(Peta sesi) {
    _sesi = [
      for (final s in _sesi)
        if (s['id'] != sesi['id']) s,
      {...sesi, 'lokal': false},
    ];
    _simpanSesi();
  }

  void hapusSesi(String id) {
    _sesi = _sesi.where((s) => s['id'] != id).toList();
    _pesan = _pesan.where((m) => m['sesi_id'] != id).toList();
    _simpanSesi();
    _simpanPesan();
  }

  /// Menyelaraskan daftar sesi dengan [data] dari server. Sesi buatan ponsel yang belum tersalin tetap dipertahankan.
  void cerminSesi(List<dynamic> data) {
    // Sesi ponsel dipertahankan bila masih kosong (baru dibuat) atau punya pesan yang belum tersalin. Sesi yang semua
    // pesannya sudah di server tidak perlu dipertahankan; ia muncul dari daftar server.
    final lokal = [
      for (final s in _sesi)
        if (s['lokal'] == true && _perluDipertahankan('${s['id']}')) s,
    ];
    final hasil = <Peta>[
      for (final x in data)
        if (x is Map && x['lokal'] != true) {...Peta.from(x), 'lokal': false},
    ];
    _sesi = [...hasil, ...lokal];
    final ada = {for (final s in _sesi) '${s['id']}'};
    _pesan = [
      for (final m in _pesan)
        if (m['lokal'] == true || ada.contains('${m['sesi_id']}')) m,
    ];
    _simpanSesi();
    _simpanPesan();
  }

  bool _perluDipertahankan(String id) {
    final p = _pesan.where((m) => m['sesi_id'] == id).toList();
    return p.isEmpty || p.any((m) => m['lokal'] == true);
  }

  /// Mengganti id sesi buatan ponsel dengan id dari server setelah berhasil disalin.
  void gantiIdSesi(String lama, String baru) {
    for (final s in _sesi) {
      if (s['id'] == lama) {
        s['id'] = baru;
        s['lokal'] = false;
      }
    }
    for (final m in _pesan) {
      if (m['sesi_id'] == lama) m['sesi_id'] = baru;
    }
    _simpanSesi();
    _simpanPesan();
  }

  // ---------- pesan ----------

  List<Peta> pesanSesi(String sesiId) {
    final d = [
      for (final m in _pesan)
        if (m['sesi_id'] == sesiId) m,
    ]..sort((a, b) => _waktu(a['waktu']).compareTo(_waktu(b['waktu'])));
    return d;
  }

  /// Menyimpan satu tanya jawab. [pesan] harus memuat `sesi_id`; bila kosong dipakai sesi terbaru (atau dibuat baru).
  void catatChat(Peta pesan) {
    var sid = pesan['sesi_id'] as String?;
    if (sid == null || !adaSesi(sid)) {
      sid = (sesiTerbaru()?['id'] as String?) ?? buatSesi()['id'] as String;
      pesan['sesi_id'] = sid;
    }
    pesan['waktu'] ??= _sekarang();
    _pesan = [..._pesan, pesan];
    if (_pesan.length > batasPesan) {
      _pesan = _pesan.sublist(_pesan.length - batasPesan);
    }
    for (final s in _sesi) {
      if (s['id'] == sid) {
        s['diubah_pada'] = _sekarang();
        if (s['judul'] == judulBawaan) {
          s['judul'] = judulDari('${pesan['pesan']}');
          s['judul_otomatis'] = true;
        }
      }
    }
    _simpanPesan();
    _simpanSesi();
  }

  /// Menggantikan salinan pesan sesi [sesiId] dengan [data] dari server; pesan buatan ponsel yang belum tersalin tetap.
  void cerminRiwayat(String sesiId, List<dynamic> data) {
    _pesan = [
      for (final m in _pesan)
        if (!(m['sesi_id'] == sesiId && m['lokal'] != true)) m,
    ];
    for (final x in data) {
      if (x is! Map || x['lokal'] == true) continue;
      final m = {...Peta.from(x), 'sesi_id': sesiId, 'lokal': false};
      // Jawaban model ponsel yang sudah tersalin tetap berlabel ponsel, bukan layanan server.
      if ('${m['jawaban']}'.contains('(Dijawab model AI di ponsel')) {
        m['sumber'] = 'ponsel';
      }
      _pesan.add(m);
    }
    _simpanPesan();
  }

  List<Peta> belumSinkron() {
    final d = [
      for (final m in _pesan)
        if (m['lokal'] == true) m,
    ]..sort((a, b) => _waktu(a['waktu']).compareTo(_waktu(b['waktu'])));
    return d;
  }

  void tandaiSinkron(String id) {
    for (final m in _pesan) {
      if (m['id'] == id) m['lokal'] = false;
    }
    _simpanPesan();
  }

  void hapusSemua() {
    _pesan = [];
    _sesi = [];
    _simpanPesan();
    _simpanSesi();
  }

  static const _kataUmum = {
    'yang',
    'dan',
    'untuk',
    'dengan',
    'dari',
    'atau',
    'ini',
    'itu',
    'saya',
    'aku',
    'ingin',
    'mau',
    'apa',
    'apakah',
    'bagaimana',
    'berapa',
    'kapan',
    'adalah',
    'tidak',
    'bisa',
    'dapat',
    'akan',
    'sudah',
    'belum',
    'juga',
    'agar',
    'supaya',
    'dalam',
    'oleh',
    'sebagai',
    'jadi',
    'beasiswa',
    'the',
    'and',
    'for',
  };

  Peta statistik() {
    final sekarang = DateTime.now();
    final minggu = _pesan
        .where(
          (x) =>
              _waktu(x['waktu'])
                  .isAfter(sekarang.subtract(const Duration(days: 7))),
        )
        .length;
    final hitung = <String, int>{};
    for (final x in _pesan) {
      for (final r in (x['rujukan'] as List? ?? const [])) {
        final n = '${(r as Map)['nama']}';
        hitung[n] = (hitung[n] ?? 0) + 1;
      }
    }
    final top = hitung.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final panjang = _pesan.isEmpty
        ? 0
        : _pesan
                  .map((x) => '${x['jawaban'] ?? ''}'.length)
                  .reduce((a, b) => a + b) ~/
              _pesan.length;
    // Rincian sejajar dengan statistik server: token diperkirakan (karakter / 4), asal jawaban, 7 hari, topik.
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final perHari = <DateTime, int>{
      for (var i = 6; i >= 0; i--) hariIni.subtract(Duration(days: i)): 0,
    };
    final kata = <String, int>{};
    var ponsel = 0;
    var masuk = 0;
    var keluar = 0;
    for (final x in _pesan) {
      final w = _waktu(x['waktu']).toLocal();
      final h = DateTime(w.year, w.month, w.day);
      if (perHari.containsKey(h)) perHari[h] = perHari[h]! + 1;
      final j = '${x['jawaban'] ?? ''}';
      final t = '${x['pesan'] ?? ''}';
      masuk += t.length;
      keluar += j.length;
      if (j.contains('(Dijawab model AI di ponsel') ||
          x['sumber'] == 'ponsel') {
        ponsel++;
      }
      for (final m in RegExp(r'[a-zA-Z]{4,}').allMatches(t.toLowerCase())) {
        final k = m.group(0)!;
        if (!_kataUmum.contains(k)) kata[k] = (kata[k] ?? 0) + 1;
      }
    }
    final topik = kata.entries.toList()
      ..sort(
        (a, b) =>
            b.value != a.value ? b.value - a.value : a.key.compareTo(b.key),
      );
    String tgl(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      'jumlah': _pesan.length,
      'tujuh_hari': minggu,
      'rata_panjang_jawaban': panjang,
      'jumlah_sesi': _sesi.length,
      'token_masuk': (masuk / 4).round(),
      'token_keluar': (keluar / 4).round(),
      'dijawab_server': _pesan.length - ponsel,
      'dijawab_ponsel': ponsel,
      'per_hari': [
        for (final e in perHari.entries)
          {'tanggal': tgl(e.key), 'jumlah': e.value},
      ],
      'topik': [
        for (final e in topik.take(6)) {'kata': e.key, 'jumlah': e.value},
      ],
      'beasiswa_teratas': [
        for (final e in top.take(5)) {'nama': e.key, 'jumlah': e.value},
      ],
    };
  }

  List<Peta> ekspor() {
    final judul = {for (final s in _sesi) s['id']: s['judul']};
    final d = [..._pesan]
      ..sort((a, b) => _waktu(a['waktu']).compareTo(_waktu(b['waktu'])));
    return [
      for (final x in d)
        {
          'pesan': x['pesan'],
          'jawaban': x['jawaban'],
          'waktu': x['waktu'],
          'sesi': judul[x['sesi_id']],
        },
    ];
  }

  /// Memulihkan butir cadangan ke sesi bernama [sesi] (atau "Dipulihkan dari cadangan"); butir sama dilewati.
  int impor(List<dynamic> butir) {
    final ada = {for (final x in _pesan) '${x['pesan']}|${x['waktu']}'};
    final peta = {for (final s in _sesi) '${s['judul']}': s};
    var n = 0;
    for (final x in butir.whereType<Map>()) {
      if (ada.contains('${x['pesan']}|${x['waktu']}')) continue;
      n++;
      final nama = '${x['sesi'] ?? ''}'.trim();
      final judul = nama.isEmpty ? 'Dipulihkan dari cadangan' : nama;
      final s = peta[judul] ??= buatSesi(judul: judul);
      catatChat({
        'id': 'lokal-impor-${DateTime.now().microsecondsSinceEpoch}-$n',
        'sesi_id': s['id'],
        'pesan': x['pesan'],
        'jawaban': x['jawaban'],
        'waktu': x['waktu'] ?? _sekarang(),
        'rujukan': const [],
        'sumber': 'ponsel',
        'lokal': true,
      });
    }
    return n;
  }

  // ---------- Memori Pintar (salinan) ----------

  bool get memoriAktif => _memoriAktif;

  /// Salinan memori dari server (dipanggil setiap kali daftar memori berhasil dimuat).
  void catatMemori(List<dynamic> data, {bool? aktif}) {
    _memoriPernah = true;
    if (aktif != null) _memoriAktif = aktif;
    _memori = [
      for (final x in data)
        if (x is Map) Peta.from(x),
    ];
    _simpanMemori();
  }

  /// Butir memori yang dipakai model di ponsel; kosong bila saklar utama mati.
  List<String> ringkasMemori({int batas = 15}) {
    if (!_memoriAktif) return const [];
    return [
      for (final m in _memori)
        if ((m['aktif'] ?? true) == true) '${m['jenis']}: ${m['isi']}',
    ].take(batas).toList();
  }

  Peta _statMemori() {
    final dipakai = _memoriAktif
        ? _memori.where((m) => (m['aktif'] ?? true) == true).toList()
        : <Peta>[];
    final perJenis = <String, int>{};
    for (final m in _memori) {
      perJenis['${m['jenis']}'] = (perJenis['${m['jenis']}'] ?? 0) + 1;
    }
    return {
      'memori_aktif': _memoriAktif,
      'jumlah': _memori.length,
      'jumlah_dipakai': dipakai.length,
      'perkiraan_token':
          dipakai.fold<int>(
            0,
            (a, m) => a + '${m['isi']}'.length + '${m['jenis']}'.length + 4,
          ) ~/
          4,
      'per_jenis': perJenis,
    };
  }

  // ---------- jalur API yang dilayani ----------

  Respons? layaniGet(String jalur, Map<String, dynamic>? q) {
    switch (jalur) {
      case '/chat/sesi':
        return Respons(daftarSesi(), null);
      case '/chat/riwayat':
        final sid = q?['sesi_id'] as String?;
        return Respons(sid == null ? _pesan : pesanSesi(sid), null);
      case '/chat/ekspor':
        return Respons(ekspor(), null);
      case '/chat/statistik':
        return Respons(statistik(), null);
      case '/me/memori':
        return _memoriPernah ? Respons([..._memori], null) : null;
      case '/me/memori/statistik':
        return _memoriPernah ? Respons(_statMemori(), null) : null;
    }
    return null;
  }

  Respons? layaniTulis(String metode, String jalur, Object? body) {
    final b = body is Map ? body : const {};
    if (metode == 'POST' && jalur == '/chat/sesi') {
      // Permintaan sinkron (membawa klien_id) tidak boleh berakhir sebagai sesi lokal baru.
      if (b['klien_id'] != null) return null;
      final s = buatSesi(judul: b['judul'] as String?);
      return Respons({...s, 'jumlah': 0}, null);
    }
    final sesi = RegExp(r'^/chat/sesi/([^/]+)$').firstMatch(jalur);
    if (sesi != null) {
      final id = sesi.group(1)!;
      final server = !id.startsWith('lokal-');
      if (metode == 'PATCH') {
        ubahJudul(id, '${b['judul'] ?? ''}'.trim());
        if (server) antre(metode, jalur, body);
        return Respons({'id': id, 'judul': b['judul']}, null);
      }
      if (metode == 'DELETE') {
        hapusSesi(id);
        if (server) antre(metode, jalur, body);
        return Respons({}, null);
      }
    }
    if (metode == 'DELETE' && jalur == '/chat/riwayat') {
      hapusSemua();
      antre(metode, jalur, body);
      return Respons({}, null);
    }
    if (metode == 'POST' && jalur == '/chat/impor') {
      final n = impor(b['butir'] as List? ?? const []);
      return Respons({'dipulihkan': n}, null);
    }
    if (!_memoriPernah) return null;
    if (metode == 'POST' && jalur == '/me/memori') {
      _memori = [
        {
          'id': 'lokal-m-${DateTime.now().microsecondsSinceEpoch}',
          'jenis': b['jenis'] ?? 'lainnya',
          'isi': b['isi'],
          'aktif': true,
          'sumber': 'manual',
        },
        ..._memori,
      ];
      _simpanMemori();
      antre(metode, jalur, body);
      return Respons({}, null);
    }
    if (metode == 'PUT' && jalur == '/me/memori/pengaturan') {
      _memoriAktif = (b['aktif'] ?? true) as bool;
      _simpanMemori();
      antre(metode, jalur, body);
      return Respons({'aktif': _memoriAktif}, null);
    }
    if (metode == 'DELETE' && jalur == '/me/memori') {
      _memori = [];
      _simpanMemori();
      antre(metode, jalur, body);
      return Respons({}, null);
    }
    final m = RegExp(r'^/me/memori/([^/]+)$').firstMatch(jalur);
    if (m != null && m.group(1) != 'statistik' && m.group(1) != 'pengaturan') {
      final id = m.group(1)!;
      final server = !id.startsWith('lokal-');
      final butir = _memori.where((x) => x['id'] == id).toList();
      if (butir.isEmpty) return null;
      if (metode == 'PATCH') {
        for (final x in butir) {
          if (b['aktif'] != null) x['aktif'] = b['aktif'];
          if (b['isi'] != null && '${b['isi']}'.trim().isNotEmpty) {
            x['isi'] = '${b['isi']}'.trim();
          }
        }
        _simpanMemori();
        if (server) antre(metode, jalur, body);
        return Respons(butir.first, null);
      }
      if (metode == 'DELETE') {
        final isi = butir.first['isi'];
        _memori = _memori.where((x) => x['id'] != id).toList();
        _simpanMemori();
        if (server) {
          antre(metode, jalur, body);
        } else {
          // butir buatan luring yang belum terkirim: batalkan kiriman penambahannya
          batalAntre(
            (e) =>
                e['m'] == 'POST' &&
                e['j'] == '/me/memori' &&
                (e['b'] as Map?)?['isi'] == isi,
          );
        }
        return Respons({}, null);
      }
    }
    return null;
  }
}
