// Data palsu dan pemuat huruf bersama untuk tes tangkapan layar (tangkap_test dan tangkap2_test).
// Isinya meniru contoh pada desain FigCraft: nama beasiswa, tenggat, dan tiga angka ringkasan.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:smart_mobile/core/format.dart';

import 'helpers.dart';

String hariKe(int n) => tanggalApi(DateTime.now().add(Duration(days: n)));

Map<String, dynamic> _b(
  String id,
  String nama,
  String penyelenggara,
  String jenjang,
  int hari,
) => {
  ...beasiswaJson(id, nama, tenggat: hariKe(hari)),
  'penyelenggara': penyelenggara,
  'jenjang': jenjang,
};

Map<String, Penangan> ruteTangkap() {
  final unggul = _b(
    '1',
    'Beasiswa Prestasi Akademik',
    'Penyelenggara Contoh',
    'S1',
    3,
  );
  final riset = _b('2', 'Beasiswa Riset Mahasiswa', 'Lembaga Contoh', 'S2', 9);
  final pimpin = _b('3', 'Beasiswa Kepemimpinan', 'Yayasan Contoh', 'S1', 21);
  final pengguna = {
    ...penggunaJson(nama: 'Adam Rahmadi'),
    'email': 'adam@kampus.ac.id',
  };
  return {
    'GET /me': (o) => Balasan.ok(pengguna),
    'GET /notifikasi': (o) => Balasan.ok([
      {
        'id': 'n1',
        'judul': 'Tenggat dekat',
        'isi': 'Beasiswa Prestasi Akademik ditutup 3 hari lagi.',
        'dibaca': false,
        'dibuat_pada': DateTime.now().toIso8601String(),
      },
    ]),
    'GET /me/tersimpan': (o) => Balasan.ok([
      {'beasiswa': unggul, 'status_rencana': null},
      {'beasiswa': pimpin, 'status_rencana': null},
    ]),
    'GET /me/checklist': (o) => Balasan.ok([
      {
        'beasiswa': unggul,
        'berkas': [
          {'id': 'b1', 'nama_berkas': 'Transkrip nilai', 'selesai': true},
          {'id': 'b2', 'nama_berkas': 'Surat rekomendasi', 'selesai': false},
        ],
      },
    ]),
    'GET /me/kalender': (o) => Balasan.ok([
      {
        'jenis': 'tenggat',
        'tanggal': hariKe(3),
        'judul': 'Beasiswa Prestasi Akademik',
        'ref_id': '1',
        'selesai': false,
      },
      {
        'jenis': 'tenggat',
        'tanggal': hariKe(9),
        'judul': 'Beasiswa Riset Mahasiswa',
        'ref_id': '2',
        'selesai': false,
      },
    ]),
    'GET /rekomendasi/ringkasan': (o) => Balasan.ok({
      'memenuhi': 12,
      'hampir_memenuhi': 31,
      'belum_memenuhi': 104,
    }),
    'GET /rekomendasi': (o) => Balasan.ok([
      {
        'beasiswa': unggul,
        'kategori': 'memenuhi',
        'alasan': ['IPK 3,60 memenuhi batas minimum 3,50. Jenjang S1 sesuai.'],
        'catatan_kekurangan': <String>[],
        'tenggat': hariKe(3),
      },
      {
        'beasiswa': riset,
        'kategori': 'hampir_memenuhi',
        'alasan': <String>[],
        'catatan_kekurangan': [
          'Semester 4 dari minimal 5. Syarat lain terpenuhi.',
        ],
        'tenggat': hariKe(9),
      },
    ]),
    'GET /beasiswa': (o) =>
        Balasan.ok([unggul, riset, pimpin], meta: {'next_cursor': null}),
    'GET /beasiswa/1': (o) => Balasan.ok({
      ...unggul,
      'manfaat': 'Biaya pendidikan penuh dan tunjangan hidup bulanan selama masa studi.',
      'tanggal_diperiksa': hariKe(-1),
      'kategori': 'memenuhi',
      'alasan': [
        'IPK dan jenjangmu sesuai dengan persyaratan',
        'Satu dokumen perlu kamu siapkan sebelum mendaftar',
      ],
      'catatan_kekurangan': <String>[],
      'persyaratan': [
        {
          'jenis': 'ipk_minimum',
          'nilai_batas': {'nilai': 3.5},
          'dapat_dikejar': false,
          'status': 'terpenuhi',
          'catatan': null,
        },
        {
          'jenis': 'jenjang',
          'nilai_batas': {'nilai': 'S1'},
          'dapat_dikejar': false,
          'status': 'terpenuhi',
          'catatan': null,
        },
        {
          'jenis': 'dokumen',
          'nilai_batas': {'nilai': 'transkrip'},
          'dapat_dikejar': true,
          'status': 'belum_diketahui',
          'catatan': null,
        },
      ],
      'berkas_wajib': [
        {'id': 'b1', 'nama_berkas': 'Transkrip nilai'},
        {'id': 'b2', 'nama_berkas': 'Surat rekomendasi'},
      ],
    }),
    'GET /me/dokumen': (o) => Balasan.ok([
      {
        'id': 'd1',
        'jenis': 'cv',
        'nama_berkas': 'Transkrip Nilai Semester 5.pdf',
        'status_baca': 'selesai',
        'hasil_baca': {'ipk': '3.80'},
      },
      {
        'id': 'd2',
        'jenis': 'sertifikat',
        'nama_berkas': 'Sertifikat TOEFL.pdf',
        'status_baca': 'selesai',
        'hasil_baca': {
          'skor_bahasa': {'toefl': 520},
        },
      },
      {
        'id': 'd3',
        'jenis': 'cv',
        'nama_berkas': 'CV Adam.pdf',
        'status_baca': 'menunggu',
        'hasil_baca': null,
      },
    ]),
    'GET /chat/status': (o) => Balasan.ok({'tersedia': true}),
    'GET /chat/riwayat': (o) => Balasan.ok([
      {
        'id': 'c1',
        'pesan': 'Beasiswa apa yang tenggatnya dekat?',
        'jawaban': 'Ada 2 beasiswa dengan tenggat kurang dari 7 hari: Beasiswa Prestasi Akademik (3 hari) dan Beasiswa Riset (6 hari).',
        'rujukan': [
          {'id': '1', 'nama': 'Beasiswa Prestasi Akademik'},
        ],
      },
    ]),
  };
}

Future<void> muatHurufTangkap() async {
  final data = File('assets/google_fonts/PlusJakartaSans-Medium.ttf')
      .readAsBytesSync();
  final f = FontLoader('Roboto')
    ..addFont(Future.value(ByteData.view(data.buffer)));
  await f.load();
  final ikon = File(
    '${Platform.environment['USERPROFILE']}/flutter/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (ikon.existsSync()) {
    final g = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(ikon.readAsBytesSync().buffer)));
    await g.load();
  }
}
