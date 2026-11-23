import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/api_client.dart';
import '../../../core/lokal/ekstrak_dokumen.dart';
import '../../../core/lokal/ekstrak_teks.dart';
import 'package:get/get.dart';

import '../../../core/async_state.dart';
import '../data/dokumen_repository.dart';
import '../domain/dokumen.dart';

class DokumenController extends GetxController {
  DokumenRepository get _repo => Get.find<DokumenRepository>();

  late final daftar = Muatan<List<Dokumen>>(_repo.daftar);

  /// Jenis dokumen yang dipilih sebelum mengunggah.
  final jenis = 'cv'.obs;

  /// Sedang mengunggah.
  final mengirim = false.obs;

  /// Mengunggah dokumen. Mengembalikan keterangan untuk pengguna.
  /// Jenis yang tak dibaca server dibaca di ponsel dan diunggah sebagai teks; tanpa jaringan berkas diantrekan.
  Future<String> unggah(String path, String nama) async {
    mengirim.value = true;
    try {
      final ext = ekstensiDari(nama);
      var kirimPath = path;
      var kirimNama = nama;
      File? sementara;
      if (!DokumenRepository.jenisServer.contains(ext)) {
        final h = await EkstrakDokumen.baca(path, nama);
        final dir = await getTemporaryDirectory();
        sementara = File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}.txt');
        await sementara.writeAsString(h.teks);
        kirimPath = sementara.path;
        kirimNama = '${nama.substring(0, nama.contains('.') ? nama.lastIndexOf('.') : nama.length)}.txt';
      }
      try {
        await _repo.unggah(jenis: jenis.value, path: kirimPath, nama: kirimNama);
        await daftar.muat();
        return 'Dokumen diunggah.';
      } on ApiException catch (e) {
        if (!e.galatJaringan) rethrow;
        await _repo.antrekan(jenis: jenis.value, path: kirimPath, nama: kirimNama);
        return 'Tidak ada jaringan. Dokumen disimpan dan diunggah otomatis saat online.';
      } finally {
        if (sementara != null && sementara.existsSync()) sementara.deleteSync();
      }
    } finally {
      mengirim.value = false;
    }
  }

  Future<void> hapus(String id) async {
    await _repo.hapus(id);
    await daftar.muat();
  }

  void bersihkan() {
    daftar.reset();
    jenis.value = 'cv';
  }
}
