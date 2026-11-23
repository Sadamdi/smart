import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart' hide Response;

import '../../../core/api_client.dart';
import '../../../core/async_state.dart';
import '../../../core/dependensi.dart';
import '../../../core/lokal/chat_lokal.dart' show judulBawaan;
import '../../../core/lokal/mesin_lokal.dart';
import '../../../core/lokal/ekstrak_dokumen.dart';
import '../../../core/lokal/ekstrak_teks.dart';
import '../../dokumen/data/dokumen_repository.dart';
import '../data/chat_repository.dart';
import 'lampiran_ui.dart';

/// Dokumen yang dilampirkan pada pertanyaan berikutnya (sudah diunggah dan dibaca server).
class LampiranChat {
  const LampiranChat({
    required this.id,
    required this.nama,
    this.teks,
    this.catatan,
    this.ukuran,
  });

  final String id;
  final String nama;
  final int? ukuran;

  /// Teks hasil bacaan di ponsel (tanpa server). Kosong bila dokumen dibaca server.
  final String? teks;
  final String? catatan;

  bool get lokal => teks != null;
}

class ChatController extends GetxController {
  ChatRepository get _repo => Get.find<ChatRepository>();

  late final tersedia = Muatan<bool>(_repo.tersedia);

  /// Sesi (utas) yang sedang dibuka; kosong berarti percakapan baru yang belum disimpan.
  final sesiId = RxnString();
  final sesiJudul = judulBawaan.obs;
  late final daftarSesi = Muatan<List<SesiChat>>(_repo.daftarSesi);
  late final riwayat = Muatan<List<PesanChat>>(
    () => _repo.riwayat(sesiId.value),
  );

  /// Catatan singkat untuk pengguna (mis. lampiran memaksa jawaban dari server).
  final catatan = RxnString();

  /// Sedang menerima jawaban (aliran), dan galat pengirimannya.
  final mengirim = false.obs;
  final galat = RxnString();

  /// Pertanyaan yang sedang dijawab dan jawaban yang baru sebagian (tampil bertahap).
  final pesanSementara = RxnString();
  final jawabanSementara = ''.obs;

  /// Lampiran (maksimal 3) dan status unggah.
  final lampiran = <LampiranChat>[].obs;
  final mengunggah = false.obs;

  /// Nama berkas yang sedang dibaca atau diunggah (untuk kartu "Membaca...").
  final mengunggahNama = RxnString();

  /// Lampiran pertanyaan yang sedang dikirim; tampil di gelembung sebelum riwayat dimuat ulang.
  final lampiranSementara = <({String nama, String? teks})>[].obs;

  static const lampiranMaks = 3;

  /// Jenis yang dibaca server; selain ini (dan semua jenis saat luring) dibaca di ponsel.
  static const jenisServer = ['pdf', 'docx', 'txt', 'png', 'jpg', 'jpeg'];

  /// Semua jenis yang bisa dilampirkan: yang dibaca server ditambah yang dibaca di ponsel.
  static const jenisDidukung = [
    'pdf', 'docx', 'txt', 'png', 'jpg', 'jpeg', 'md', 'csv', 'tsv', 'json', //
    'xml', 'html', 'htm', 'rtf', 'pptx', 'xlsx', 'odt', 'ods', 'odp', 'epub',
    'webp', 'bmp', 'yaml', 'yml', 'log',
  ];
  static const keteranganJenis =
      'PDF, Word, PowerPoint, Excel, OpenDocument, EPUB, teks (TXT, MD, CSV, JSON, HTML, RTF), dan gambar. '
      'Format lama .doc, .xls, .ppt dan audio atau video belum didukung.';

  /// Jenis dokumen dari nama berkas: CV atau sertifikat (termasuk penghargaan dan piagam).
  static String jenisDari(String nama) {
    final n = nama.toLowerCase();
    if (n.contains('cv') || n.contains('resume') || n.contains('riwayat')) {
      return 'cv';
    }
    return 'sertifikat';
  }

  /// Memilih berkas lalu melampirkannya. Online dan jenis yang dikenali server: diunggah dan dibaca server.
  /// Luring, jaringan putus, atau jenis lain: dibaca di ponsel (teks disisipkan ke konteks model ponsel), dan
  /// berkas yang dikenali server diantrekan untuk diunggah saat ada jaringan.
  Future<void> lampirkan() async {
    if (mengunggah.value) return;
    if (lampiran.length >= lampiranMaks) {
      galat.value = 'Maksimal $lampiranMaks berkas per pertanyaan. Lepas salah satu dulu.';
      return;
    }
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: jenisDidukung,
    );
    final berkas = hasil.isEmpty ? null : hasil.first;
    if (berkas?.path == null) return;
    final byte = File(berkas!.path!).lengthSync();
    if (byte > lampiranMaksByte) {
      galat.value =
          '${berkas.name} berukuran ${ukuranTeks(byte)}. Maksimal ${ukuranTeks(lampiranMaksByte)} per berkas.';
      return;
    }
    mengunggah.value = true;
    mengunggahNama.value = berkas.name;
    galat.value = null;
    try {
      final ext = ekstensiDari(berkas.name);
      final luring = Get.find<MesinLokal>().aktif.value;
      if (!luring && jenisServer.contains(ext)) {
        try {
          final d = await Get.find<DokumenRepository>().unggah(
            jenis: jenisDari(berkas.name),
            path: berkas.path!,
            nama: berkas.name,
          );
          lampiran.add(
            LampiranChat(id: d.id, nama: d.namaBerkas, ukuran: byte, catatan: 'Dibaca server'),
          );
          return;
        } on ApiException catch (e) {
          if (!e.galatJaringan) rethrow; // jaringan putus: dibaca di ponsel
        }
      }
      final h = await EkstrakDokumen.baca(berkas.path!, berkas.name);
      lampiran.add(
        LampiranChat(
          id: 'lokal-${DateTime.now().microsecondsSinceEpoch}',
          nama: berkas.name,
          teks: h.teks,
          ukuran: byte,
          catatan: h.catatan == null ? 'Dibaca di ponsel' : 'Dibaca di ponsel. ${h.catatan}',
        ),
      );
      if (jenisServer.contains(ext)) {
        await Get.find<DokumenRepository>().antrekan(
          jenis: jenisDari(berkas.name),
          path: berkas.path!,
          nama: berkas.name,
        );
      }
    } on EkstrakGagal catch (e) {
      galat.value = e.pesan;
    } catch (e) {
      galat.value = pesanGalat(e);
    } finally {
      mengunggah.value = false;
      mengunggahNama.value = null;
    }
  }

  void lepas(LampiranChat l) => lampiran.remove(l);

  StreamSubscription<KejadianChat>? _langganan;
  CancelToken? _batal;
  final _penampung = StringBuffer();
  Timer? _penyiram;

  /// Chatbot dianggap tersedia sampai terbukti sebaliknya.
  bool get bisaMenjawab => tersedia.value ?? true;

  Worker? _pendengarSinkron;
  Worker? _pendengarRiwayat;

  /// Saran lanjutan dari model (server); kosong berarti klien memakai saran lokal.
  final saranModel = <String>[].obs;

  /// Saran dari basis data di ponsel (beasiswa paling cocok, tenggat terdekat); ikut tampil saat luring.
  final saranData = <String>[].obs;
  int _tandaSaran = 0;

  Future<void> _muatSaran() async {
    final tanda = ++_tandaSaran;
    final daftar = await _repo.saran(sesiId.value);
    if (tanda == _tandaSaran) saranModel.assignAll(daftar);
  }

  @override
  void onInit() {
    super.onInit();
    // Setelah sesi ponsel tersalin ke server (id dan judul berubah), daftar dan layar ikut diperbarui.
    // Saran model diperbarui setiap kali riwayat sesi selesai dimuat; saran lama dibuang agar tak salah konteks.
    _pendengarRiwayat = ever(riwayat.state, (s) {
      saranModel.clear();
      if (!s.hasValue) return;
      saranData.assignAll(_repo.saranData());
      if (!mengirim.value && (s.value?.isNotEmpty ?? false)) _muatSaran();
    });
    _pendengarSinkron = ever(_repo.versiSinkron, (_) async {
      final lama = sesiId.value;
      if (lama != null && _repo.penggantianSesi[lama] != null) {
        sesiId.value = _repo.penggantianSesi[lama];
      }
      await daftarSesi.muat();
      _selaraskanJudul();
      if (!mengirim.value && sesiId.value != lama) await riwayat.muat();
    });
  }

  @override
  void onClose() {
    _pendengarSinkron?.dispose();
    _pendengarRiwayat?.dispose();
    super.onClose();
  }

  Future<void> buka() async {
    await Future.wait([tersedia.muat(), daftarSesi.muat()]);
    // Buka sesi terbaru bila belum ada yang dipilih.
    if (sesiId.value == null) {
      final d = daftarSesi.value ?? const <SesiChat>[];
      if (d.isNotEmpty) _setAktif(d.first);
    } else {
      _selaraskanJudul();
    }
    await riwayat.muat();
  }

  void _setAktif(SesiChat s) {
    sesiId.value = s.id;
    sesiJudul.value = s.judul;
  }

  void _selaraskanJudul() {
    for (final s in daftarSesi.value ?? const <SesiChat>[]) {
      if (s.id == sesiId.value) sesiJudul.value = s.judul;
    }
  }

  /// Membuka sesi lain dari daftar.
  Future<void> pilihSesi(SesiChat s) async {
    await batalkan();
    galat.value = null;
    catatan.value = null;
    lampiran.clear();
    _setAktif(s);
    await riwayat.muat();
  }

  /// Memulai percakapan baru; sesinya baru dibuat saat pesan pertama dikirim.
  Future<void> sesiBaru() async {
    await batalkan();
    galat.value = null;
    catatan.value = null;
    lampiran.clear();
    sesiId.value = null;
    sesiJudul.value = judulBawaan;
    await riwayat.muat();
  }

  Future<void> ubahJudul(String judul) async {
    final id = sesiId.value;
    if (id == null || judul.trim().isEmpty) return;
    await _repo.ubahJudulSesi(id, judul.trim());
    sesiJudul.value = judul.trim();
    await daftarSesi.muat();
  }

  /// Mengganti nama sesi mana pun dari daftar.
  Future<void> ubahJudulSesi(SesiChat s, String judul) async {
    if (judul.trim().isEmpty) return;
    await _repo.ubahJudulSesi(s.id, judul.trim());
    if (s.id == sesiId.value) sesiJudul.value = judul.trim();
    await daftarSesi.muat();
  }

  /// Menghapus satu sesi; bila itu yang sedang dibuka, pindah ke sesi terbaru lainnya.
  Future<void> hapusSesi(SesiChat s) async {
    final aktifDihapus = s.id == sesiId.value;
    if (aktifDihapus) await batalkan();
    try {
      cadanganHapus.value = (await _repo.ekspor())
          .where((x) => (x as Map)['sesi'] == s.judul)
          .toList();
    } catch (_) {
      cadanganHapus.value = null;
    }
    await _repo.hapusSesi(s.id);
    await daftarSesi.muat();
    if (aktifDihapus) {
      final d = daftarSesi.value ?? const <SesiChat>[];
      if (d.isEmpty) {
        sesiId.value = null;
        sesiJudul.value = judulBawaan;
      } else {
        _setAktif(d.first);
      }
      await riwayat.muat();
    }
  }

  /// Menyalin potongan yang terkumpul ke layar paling sering 12 kali per detik agar tidak berat saat model cepat.
  void _jadwalkanSiram() {
    _penyiram ??= Timer(const Duration(milliseconds: 80), () {
      _penyiram = null;
      jawabanSementara.value = _penampung.toString();
    });
  }

  /// Mengirim pesan dan menampilkan jawaban bertahap. Mengembalikan true bila pengiriman dimulai
  /// (kolom teks boleh dikosongkan); jawaban masuk lewat [jawabanSementara] lalu riwayat dimuat ulang.
  Future<bool> kirim(String teks) async {
    if (teks.isEmpty || mengirim.value) return false;
    mengirim.value = true;
    galat.value = null;
    catatan.value = null;
    pesanSementara.value = teks;
    jawabanSementara.value = '';
    _penampung.clear();
    _batal = CancelToken();
    final ids = [for (final l in lampiran) if (!l.lokal) l.id];
    final teksLampiran = [
      for (final l in lampiran)
        if (l.lokal) (nama: l.nama, teks: l.teks!),
    ];
    lampiranSementara.assignAll([
      for (final l in lampiran) (nama: l.nama, teks: l.teks),
    ]);
    lampiran.clear();
    if (ids.isNotEmpty && Get.find<MesinLokal>().aiLokalAktif) {
      catatan.value = 'Pertanyaan berlampiran dijawab server karena dokumennya dibaca di sana.';
    }
    // Percakapan baru: sesinya dibuat dulu (di server bila ada jaringan, selain itu di ponsel).
    if (sesiId.value == null) {
      try {
        final s = await _repo.buatSesi();
        _setAktif(s);
      } catch (e) {
        galat.value = pesanGalat(e);
        _bersihkanAliran();
        return false;
      }
    }
    final selesai = Completer<void>();
    _langganan = _repo
        .kirimAlir(
          teks,
          sesiId: sesiId.value,
          batal: _batal,
          dokumenIds: ids,
          teksLampiran: teksLampiran,
        )
        .listen(
          (k) {
            if (k is TokenChat) {
              _penampung.write(k.t);
              _jadwalkanSiram();
            } else if (k is SesiBergantiChat) {
              if (sesiId.value == k.sesiLama) sesiId.value = k.sesiBaru;
            } else if (k is JudulChat) {
              if (sesiId.value == k.sesiId) sesiJudul.value = k.judul;
            }
          },
          onError: (Object e) {
            galat.value = pesanGalat(e);
            if (!selesai.isCompleted) selesai.complete();
          },
          onDone: () {
            if (!selesai.isCompleted) selesai.complete();
          },
          cancelOnError: true,
        );
    unawaited(
      selesai.future.then((_) async {
        _penyiram?.cancel();
        _penyiram = null;
        final dibatalkan = _langganan == null;
        _langganan = null;
        if (!dibatalkan && galat.value == null) await riwayat.muat();
        _bersihkanAliran();
        unawaited(daftarSesi.muat().then((_) => _selaraskanJudul()));
      }),
    );
    return true;
  }

  void _bersihkanAliran() {
    mengirim.value = false;
    pesanSementara.value = null;
    lampiranSementara.clear();
    jawabanSementara.value = '';
    _penampung.clear();
  }

  /// Menghentikan jawaban yang sedang mengalir (koneksi server diputus dan model berhenti menghasilkan teks).
  Future<void> batalkan() async {
    if (!mengirim.value) return;
    _batal?.cancel();
    final l = _langganan;
    _langganan = null;
    await l?.cancel();
    _penyiram?.cancel();
    _penyiram = null;
    _bersihkanAliran();
  }

  /// Cadangan sesaat dari riwayat yang baru dihapus, agar dapat diurungkan.
  final cadanganHapus = Rxn<List<dynamic>>();

  Future<void> hapusRiwayat() async {
    await batalkan();
    try {
      cadanganHapus.value = await _repo.ekspor();
    } catch (_) {
      cadanganHapus.value = null;
    }
    await _repo.hapusRiwayat();
    sesiId.value = null;
    sesiJudul.value = judulBawaan;
    await riwayat.muat();
    await daftarSesi.muat();
  }

  Future<String> urungkanHapus() async {
    final c = cadanganHapus.value;
    if (c == null || c.isEmpty) return 'Tidak ada yang dipulihkan';
    final n = await _repo.impor(c);
    cadanganHapus.value = null;
    await daftarSesi.muat();
    if (sesiId.value == null) {
      final d = daftarSesi.value ?? const <SesiChat>[];
      if (d.isNotEmpty) _setAktif(d.first);
    }
    await riwayat.muat();
    return '$n percakapan dipulihkan';
  }

  Future<Map<String, dynamic>> statistik() => _repo.statistik();

  Map<String, dynamic> statistikLokal() => _repo.statistikLokal();

  /// Menyimpan cadangan riwayat sebagai berkas JSON ke lokasi pilihan pengguna.
  Future<String> cadangkan() async {
    final butir = await _repo.ekspor();
    if (butir.isEmpty) return 'Belum ada riwayat untuk dicadangkan';
    final uri = await FilePicker.saveFile(
      fileName: 'cadangan-chat-smart.json',
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(butir))),
      mimeType: 'application/json',
    );
    return uri == null ? 'Dibatalkan' : 'Cadangan disimpan';
  }

  /// Memulihkan riwayat dari berkas cadangan JSON (butir yang sama tidak digandakan).
  Future<String> pulihkan() async {
    final hasil = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    final berkas = hasil.isEmpty ? null : hasil.first;
    if (berkas?.path == null) return 'Dibatalkan';
    try {
      final butir = jsonDecode(await File(berkas!.path!).readAsString());
      if (butir is! List) return 'Berkas cadangan tidak valid';
      final n = await _repo.impor(butir);
      await daftarSesi.muat();
      if (sesiId.value == null) {
        final d = daftarSesi.value ?? const <SesiChat>[];
        if (d.isNotEmpty) _setAktif(d.first);
      }
      await riwayat.muat();
      return '$n percakapan dipulihkan';
    } catch (_) {
      return 'Berkas cadangan tidak valid';
    }
  }

  void bersihkan() {
    unawaited(batalkan());
    tersedia.reset();
    riwayat.reset();
    daftarSesi.reset();
    sesiId.value = null;
    sesiJudul.value = judulBawaan;
    galat.value = null;
    catatan.value = null;
  }
}
