import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'apk_downloader.dart';
import 'app_update_checker.dart';
import 'device_abi.dart';

enum TahapPembaruan { siap, mengunduh, memasang, gagal }

/// Pemegang proses unduh dan pasang pembaruan. Hidup sendiri di luar dialog: menutup atau kehilangan dialog
/// tidak membatalkan unduhan. Kemajuan ditampilkan dialog atau banner, dan begitu selesai pemasang Android
/// dibuka otomatis.
class PembaruanController extends ChangeNotifier {
  PembaruanController._();

  static final PembaruanController instance = PembaruanController._();

  TahapPembaruan tahap = TahapPembaruan.siap;
  double? kemajuan;
  bool menungguJaringan = false;
  String? galat;

  /// Galat jaringan: unduhan tersimpan dan tombolnya berbunyi "Lanjutkan".
  bool bisaLanjut = false;
  HasilPeriksa? hasil;
  bool dialogTerbuka = false;

  CancelToken? _batal;
  File? _berkas;

  bool get sibuk => tahap == TahapPembaruan.mengunduh;

  void setDialogTerbuka(bool nilai) {
    if (dialogTerbuka == nilai) return;
    dialogTerbuka = nilai;
    notifyListeners();
  }

  void _ubah(void Function() f) {
    f();
    notifyListeners();
  }

  /// Mulai (atau ulangi) unduhan. Aman dipanggil berulang: tidak menggandakan unduhan yang sedang jalan.
  Future<void> mulai(HasilPeriksa h) async {
    if (sibuk) return;
    hasil = h;
    final m = h.manifest!;
    _batal = CancelToken();
    _ubah(() {
      tahap = TahapPembaruan.mengunduh;
      kemajuan = null;
      galat = null;
      bisaLanjut = false;
      menungguJaringan = false;
    });
    final abi = deviceApkAbi();
    try {
      final url = m.apkUntuk(abi);
      final sha = m.sha256Untuk(abi);
      if (url == null || sha == null || sha.isEmpty) {
        throw const UpdateDownloadException(UpdateFailure.tidakAda);
      }
      final dir = await getApplicationCacheDirectory();
      final berkas = await ApkDownloader().download(
        url: url,
        target: File('${dir.path}/smart-update-${m.build}.apk'),
        expectedSha256: sha,
        cancelToken: _batal,
        onProgress: (diterima, total) {
          kemajuan = total > 0 ? diterima / total : null;
          notifyListeners();
        },
        onWaitingForNetwork: (menunggu) =>
            _ubah(() => menungguJaringan = menunggu),
      );
      // Pemeriksaan terakhir sebelum pemasang: APK harus ditandatangani kunci yang sama dengan aplikasi ini.
      final kunciApk = await AppUpdateChecker.sidikKunciApk(berkas.path);
      final kunciSendiri = await AppUpdateChecker.sidikKunciSendiri();
      if (kunciApk == null || kunciSendiri == null || kunciApk != kunciSendiri) {
        await berkas.delete();
        _gagal(
          'Berkas pembaruan tidak berasal dari penerbit resmi SMART sehingga tidak dipasang.',
        );
        return;
      }
      _berkas = berkas;
      await pasang();
    } on UpdateDownloadException catch (e) {
      _gagal(switch (e.reason) {
        UpdateFailure.hostDitolak =>
          'Alamat pembaruan tidak dipercaya, jadi unduhan dibatalkan.',
        UpdateFailure.corrupted =>
          'Berkas pembaruan rusak saat diunduh. Tekan "Coba lagi" untuk mengunduh ulang.',
        UpdateFailure.network =>
          'Koneksi terputus terlalu lama. Unduhan tersimpan, tekan "Lanjutkan" saat internet kembali.',
        UpdateFailure.tidakAda =>
          'Berkas pembaruan tidak ditemukan. Tutup lalu buka lagi aplikasinya.',
      }, lanjut: e.reason == UpdateFailure.network);
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      debugPrint('[update] gagal: $e');
      _gagal('Pembaruan gagal dipasang. Tekan "Coba lagi".');
    }
  }

  /// Membuka pemasang Android untuk APK yang sudah diverifikasi.
  Future<void> pasang() async {
    final berkas = _berkas;
    if (berkas == null) return;
    _ubah(() {
      tahap = TahapPembaruan.memasang;
      galat = null;
    });
    try {
      final r = await OpenFilex.open(
        berkas.path,
        type: 'application/vnd.android.package-archive',
      );
      if (r.type != ResultType.done) throw Exception(r.message);
    } catch (e) {
      debugPrint('[update] pemasang gagal dibuka: $e');
      _gagal('Pemasang belum bisa dibuka. Tekan "Coba lagi".');
    }
  }

  void batal() {
    _batal?.cancel();
    _ubah(() {
      tahap = TahapPembaruan.siap;
      menungguJaringan = false;
      kemajuan = null;
    });
  }

  /// Menyembunyikan banner (setelah gagal atau saat pemasang sudah dibuka).
  void tutup() => _ubah(() {
    tahap = TahapPembaruan.siap;
    galat = null;
  });

  /// Dipanggil saat aplikasi kembali ke latar depan: unduhan yang terhenti karena jaringan dilanjutkan sendiri.
  void lanjutkanBilaTerhenti() {
    if (tahap == TahapPembaruan.gagal && bisaLanjut && hasil != null) {
      mulai(hasil!);
    }
  }

  void _gagal(String pesan, {bool lanjut = false}) {
    _ubah(() {
      tahap = TahapPembaruan.gagal;
      menungguJaringan = false;
      galat = pesan;
      bisaLanjut = lanjut;
    });
  }
}
