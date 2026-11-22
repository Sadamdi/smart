import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/lokal/chat_lokal.dart';

ChatLokal _baru({
  List<(String, String, Object?)>? antrean,
  Map<String, Object?>? berkas,
}) => ChatLokal(
  tulis: (nama, isi) => berkas?[nama] = isi,
  antre: (m, j, b) => antrean?.add((m, j, b)),
  batalAntre: (cocok) {},
);

Map<String, dynamic> _pesan(
  String id,
  String? sesi,
  String teks, {
  bool lokal = true,
  String? waktu,
}) => {
  'id': id,
  'sesi_id': sesi,
  'pesan': teks,
  'jawaban': 'jawab $teks',
  'waktu': waktu ?? DateTime.now().toIso8601String(),
  'rujukan': const [],
  'sumber': 'ponsel',
  'lokal': lokal,
};

void main() {
  test('pesan tanpa sesi masuk sesi terbaru atau membuat sesi, judul sementara dari pesan', () {
    final c = _baru();
    c.catatChat(
      _pesan(
        'lokal-1',
        null,
        'Cari beasiswa S2 ke Jepang untuk teknik informatika',
      ),
    );
    final s = c.daftarSesi();
    expect(s, hasLength(1));
    expect(s.first['judul'], 'Cari beasiswa S2 ke Jepang untuk teknik ...');
    expect(s.first['jumlah'], 1);
    c.catatChat(_pesan('lokal-2', s.first['id'] as String, 'Syaratnya?'));
    expect(c.pesanSesi(s.first['id'] as String), hasLength(2));
    expect(c.daftarSesi(), hasLength(1));
  });

  test('riwayat terpisah per sesi dan hapus sesi ikut menghapus pesannya', () {
    final c = _baru();
    final a = c.buatSesi(judul: 'A')['id'] as String;
    final b = c.buatSesi(judul: 'B')['id'] as String;
    c.catatChat(_pesan('lokal-1', a, 'satu'));
    c.catatChat(_pesan('lokal-2', b, 'dua'));
    expect(c.pesanSesi(a).map((m) => m['pesan']), ['satu']);
    expect(c.pesanSesi(b).map((m) => m['pesan']), ['dua']);
    c.hapusSesi(a);
    expect(c.pesanSesi(a), isEmpty);
    expect(c.daftarSesi().map((s) => s['id']), [b]);
  });

  test('cermin dari server tidak menghapus jawaban model ponsel yang belum tersalin', () {
    final c = _baru();
    c.cerminSesi([
      {
        'id': 'sv-1',
        'judul': 'Dari server',
        'diubah_pada': '2026-11-22T10:00:00Z',
        'jumlah': 1,
      },
    ]);
    c.cerminRiwayat('sv-1', [
      {
        'id': 'p1',
        'pesan': 'halo',
        'jawaban': 'hai',
        'waktu': '2026-11-22T10:00:00Z',
        'rujukan': [],
      },
    ]);
    c.catatChat(_pesan('lokal-9', 'sv-1', 'jawaban dari ponsel'));
    // riwayat server dimuat ulang tanpa butir ponsel: butir ponsel harus tetap ada
    c.cerminRiwayat('sv-1', [
      {
        'id': 'p1',
        'pesan': 'halo',
        'jawaban': 'hai',
        'waktu': '2026-11-22T10:00:00Z',
        'rujukan': [],
      },
    ]);
    expect(
      c.pesanSesi('sv-1').map((m) => m['pesan']),
      containsAll(['halo', 'jawaban dari ponsel']),
    );
    expect(c.belumSinkron().map((m) => m['id']), ['lokal-9']);
    c.tandaiSinkron('lokal-9');
    expect(c.belumSinkron(), isEmpty);
  });

  test('sesi buatan ponsel bertahan saat daftar server dimuat dan berganti id setelah tersalin', () {
    final c = _baru();
    final lokal = c.buatSesi()['id'] as String;
    c.catatChat(_pesan('lokal-1', lokal, 'tanya'));
    c.cerminSesi([]); // server belum mengenalnya
    expect(c.adaSesi(lokal), isTrue);
    c.gantiIdSesi(lokal, 'sv-7');
    expect(c.adaSesi(lokal), isFalse);
    expect(c.pesanSesi('sv-7'), hasLength(1));
    c.cerminSesi([
      {
        'id': 'sv-7',
        'judul': 'Judul AI',
        'diubah_pada': '2026-11-22T10:00:00Z',
      },
    ]);
    expect(c.daftarSesi().single['judul'], 'Judul AI');
  });

  test('layani offline: buat, ganti nama, hapus sesi dengan antrean hanya untuk id server', () {
    final antre = <(String, String, Object?)>[];
    final c = _baru(antrean: antre);
    final dibuat = c.layaniTulis('POST', '/chat/sesi', {})!.data as Map;
    final id = dibuat['id'] as String;
    expect(id, startsWith('lokal-'));
    c.layaniTulis('PATCH', '/chat/sesi/$id', {'judul': 'Baru'});
    expect(antre, isEmpty); // sesi lokal disalin lewat sinkron, bukan antrean
    c.cerminSesi([
      {'id': 'sv-1', 'judul': 'S', 'diubah_pada': '2026-11-22T10:00:00Z'},
    ]);
    c.layaniTulis('PATCH', '/chat/sesi/sv-1', {'judul': 'Ganti'});
    c.layaniTulis('DELETE', '/chat/sesi/sv-1', null);
    expect(antre.map((e) => '${e.$1} ${e.$2}'), [
      'PATCH /chat/sesi/sv-1',
      'DELETE /chat/sesi/sv-1',
    ]);
    // permintaan sinkron (membawa klien_id) tidak boleh menjadi sesi lokal baru
    expect(c.layaniTulis('POST', '/chat/sesi', {'klien_id': id}), isNull);
    final daftar = c.layaniGet('/chat/sesi', null)!.data as List;
    expect(daftar.single['judul'], 'Baru');
  });

  test('Memori Pintar: salinan dibaca offline, diubah offline masuk antrean, dipakai model ponsel', () {
    final antre = <(String, String, Object?)>[];
    final c = _baru(antrean: antre);
    expect(
      c.layaniGet('/me/memori', null),
      isNull,
    ); // belum pernah dimuat dari server
    c.catatMemori([
      {
        'id': 'm1',
        'jenis': 'minat',
        'isi': 'Mencari beasiswa S2 ke Jepang',
        'aktif': true,
        'sumber': 'chat',
      },
      {
        'id': 'm2',
        'jenis': 'prestasi',
        'isi': 'Juara debat',
        'aktif': false,
        'sumber': 'manual',
      },
    ], aktif: true);
    expect(c.ringkasMemori(), [
      'minat: Mencari beasiswa S2 ke Jepang',
    ]); // butir nonaktif dilewati
    final stat = c.layaniGet('/me/memori/statistik', null)!.data as Map;
    expect(stat['jumlah'], 2);
    expect(stat['jumlah_dipakai'], 1);
    c.layaniTulis('PATCH', '/me/memori/m2', {'aktif': true});
    expect(c.ringkasMemori(), hasLength(2));
    c.layaniTulis('POST', '/me/memori', {
      'jenis': 'keahlian',
      'isi': 'Flutter',
    });
    c.layaniTulis('DELETE', '/me/memori/m1', null);
    expect(antre.map((e) => '${e.$1} ${e.$2}'), [
      'PATCH /me/memori/m2',
      'POST /me/memori',
      'DELETE /me/memori/m1',
    ]);
    c.layaniTulis('PUT', '/me/memori/pengaturan', {'aktif': false});
    expect(c.ringkasMemori(), isEmpty); // saklar utama mati: tidak dipakai
  });

  test(
    'cadangan menyertakan judul sesi dan pemulihan membuat sesi bernama',
    () {
      final c = _baru();
      final a = c.buatSesi(judul: 'Jepang')['id'] as String;
      c.catatChat(_pesan('lokal-1', a, 'satu', waktu: '2026-11-22T10:00:00'));
      final cadangan = c.ekspor();
      expect(cadangan.single['sesi'], 'Jepang');
      final lain = _baru();
      expect(lain.impor(cadangan), 1);
      expect(lain.impor(cadangan), 0); // tidak ganda
      expect(lain.daftarSesi().single['judul'], 'Jepang');
    },
  );

  test('migrasi: pesan lama tanpa sesi hanya ditandai belum tersalin bila buatan ponsel', () {
    final c = _baru();
    c.muat(
      pesan: [
        {..._pesan('a', null, 'dari server', lokal: false), 'sumber': 'server'}..remove('lokal'),
        {..._pesan('b', null, 'dari ponsel', lokal: false)}..remove('lokal'),
      ],
      sesi: const [],
    );
    final s = c.daftarSesi().single;
    expect(s['judul'], 'Percakapan sebelumnya');
    expect(s['lokal'], isTrue);
    expect(c.belumSinkron().map((m) => m['id']), ['b']);

    final d = _baru();
    d.muat(
      pesan: [
        {..._pesan('a', null, 'dari server', lokal: false), 'sumber': 'server'}..remove('lokal'),
      ],
      sesi: const [],
    );
    expect(d.daftarSesi().single['lokal'], isFalse);
    expect(d.belumSinkron(), isEmpty);
  });

  test('cermin riwayat mempertahankan label ponsel pada jawaban model ponsel', () {
    final c = _baru();
    c.cerminRiwayat('s1', [
      {
        'id': 'x',
        'pesan': 'hai',
        'jawaban': 'halo (Dijawab model AI di ponsel. Estimasi hanya perkiraan.)',
        'sumber': 'server',
        'waktu': DateTime.now().toIso8601String(),
      },
    ]);
    expect(c.pesanSesi('s1').single['sumber'], 'ponsel');
  });
}
