import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_mobile/core/update/apk_downloader.dart';
import 'package:smart_mobile/core/update/update_config.dart';
import 'package:smart_mobile/core/update/update_manifest.dart';

Map<String, dynamic> manifestJson({
  int build = 5,
  int minBuild = 1,
  List<int> blocked = const [],
}) => {
  'version': '1.2.0',
  'build': build,
  'minBuild': minBuild,
  'blockedBuilds': blocked,
  'notes': 'Perbaikan tampilan.',
  'apks': {
    'arm64': 'https://github.com/x/a64.apk',
    'arm32': 'https://github.com/x/a32.apk',
  },
  'sha256': {'arm64': 'aa', 'arm32': 'bb'},
  'certSha256': 'ABCDEF',
  'history': [
    {'version': '1.1.0', 'build': 3, 'date': '2026-11-01', 'notes': 'Awal'},
  ],
};

void main() {
  group('manifest', () {
    test('wajib bila di bawah minBuild atau diblokir', () {
      final m = UpdateManifest.fromJson(
        manifestJson(minBuild: 4, blocked: [2]),
      );
      expect(m.wajibUntuk(3), isTrue); // di bawah minBuild
      expect(m.wajibUntuk(2), isTrue); // diblokir
      expect(m.wajibUntuk(4), isFalse);
      expect(
        UpdateManifest.fromJson(manifestJson(blocked: [3])).wajibUntuk(3),
        isTrue,
      );
    });

    test('hanya build yang lebih tinggi dianggap pembaruan', () {
      final m = UpdateManifest.fromJson(manifestJson());
      expect(m.lebihBaruDari(4), isTrue);
      expect(m.lebihBaruDari(5), isFalse);
      expect(m.lebihBaruDari(9), isFalse);
    });

    test('APK dipilih sesuai arsitektur, arm64 bila tidak tersedia', () {
      final m = UpdateManifest.fromJson(manifestJson());
      expect(m.apkUntuk('arm32'), 'https://github.com/x/a32.apk');
      expect(m.sha256Untuk('arm32'), 'bb');
      expect(m.apkUntuk('arm64'), 'https://github.com/x/a64.apk');
      expect(m.apkUntuk('x64'), 'https://github.com/x/a64.apk');
      expect(m.sha256Untuk('x64'), 'aa');
    });

    test(
      'sidik kunci dinormalkan ke huruf kecil dan riwayat memuat build terbaru',
      () {
        final m = UpdateManifest.fromJson(manifestJson());
        expect(m.certSha256, 'abcdef');
        expect(m.riwayat.map((r) => r.build), [5, 3]);
      },
    );

    test('perbandingan versi', () {
      expect(bandingkanVersi('1.0.10', '1.0.9'), greaterThan(0));
      expect(bandingkanVersi('1.0.0', '1.1.0'), lessThan(0));
      expect(bandingkanVersi('2.0.0', '2.0.0'), 0);
    });
  });

  group('alamat unduhan', () {
    test('hanya HTTPS dari GitHub', () {
      expect(
        hostPembaruanDiizinkan(
          Uri.parse('https://github.com/a/b/releases/download/t/x.apk'),
        ),
        isTrue,
      );
      expect(
        hostPembaruanDiizinkan(
          Uri.parse('https://objects.githubusercontent.com/x'),
        ),
        isTrue,
      );
      expect(
        hostPembaruanDiizinkan(Uri.parse('http://github.com/x.apk')),
        isFalse,
      );
      expect(
        hostPembaruanDiizinkan(Uri.parse('https://evil.example/x.apk')),
        isFalse,
      );
      expect(
        hostPembaruanDiizinkan(
          Uri.parse('https://github.com.evil.example/x.apk'),
        ),
        isFalse,
      );
    });
  });

  group('pengunduh APK', () {
    late HttpServer server;
    late Directory tmp;
    final isi = List<int>.generate(300000, (i) => i % 251);
    var putusSetelah = -1;
    var jumlahPermintaan = 0;
    late String sha;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('smart_update_test');
      sha = sha256.convert(isi).toString();
      putusSetelah = -1;
      jumlahPermintaan = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        jumlahPermintaan++;
        if (req.uri.path == '/hilang.apk') {
          req.response.statusCode = 404;
          await req.response.close();
          return;
        }
        var mulai = 0;
        final range = req.headers.value('range');
        if (range != null) {
          mulai = int.parse(
            RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!,
          );
          req.response.statusCode = 206;
        }
        final bagian = isi.sublist(mulai);
        req.response.contentLength = bagian.length;
        if (putusSetelah >= 0 && range == null) {
          // Menutup respons dengan byte kurang dari Content-Length memutus sambungan di tengah badan respons.
          req.response.bufferOutput = false;
          req.response.add(bagian.sublist(0, putusSetelah));
          try {
            await req.response.close();
          } catch (_) {}
          return;
        }
        req.response.add(bagian);
        await req.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      await tmp.delete(recursive: true);
    });

    ApkDownloader pengunduh() => ApkDownloader(
      dio: Dio(),
      retryDelays: const [
        Duration(milliseconds: 10),
        Duration(milliseconds: 10),
      ],
      cekHost: (_) => true,
    );

    String url(String path) => 'http://127.0.0.1:${server.port}$path';

    test('mengunduh dan memverifikasi SHA-256', () async {
      var terakhir = 0;
      final f = await pengunduh().download(
        url: url('/a.apk'),
        target: File('${tmp.path}/u.apk'),
        expectedSha256: sha,
        onProgress: (d, t) => terakhir = d,
      );
      expect(await f.length(), isi.length);
      expect(terakhir, isi.length);
      expect(File('${tmp.path}/u.apk.part').existsSync(), isFalse);
    });

    test('SHA-256 salah ditolak dan berkas sementara dihapus', () async {
      await expectLater(
        pengunduh().download(
          url: url('/a.apk'),
          target: File('${tmp.path}/u.apk'),
          expectedSha256: 'salah',
          onProgress: (_, _) {},
        ),
        throwsA(
          isA<UpdateDownloadException>().having(
            (e) => e.reason,
            'reason',
            UpdateFailure.corrupted,
          ),
        ),
      );
      expect(File('${tmp.path}/u.apk').existsSync(), isFalse);
      expect(File('${tmp.path}/u.apk.part').existsSync(), isFalse);
    });

    test('putus di tengah unduhan dilanjutkan dengan Range', () async {
      putusSetelah = 120000;
      final f = await pengunduh().download(
        url: url('/a.apk'),
        target: File('${tmp.path}/u.apk'),
        expectedSha256: sha,
        onProgress: (_, _) {},
      );
      expect(sha256.convert(await f.readAsBytes()).toString(), sha);
      expect(jumlahPermintaan, greaterThanOrEqualTo(2));
    });

    test(
      'berkas utuh dari unduhan sebelumnya dipakai ulang tanpa permintaan',
      () async {
        final target = File('${tmp.path}/u.apk')..writeAsBytesSync(isi);
        await pengunduh().download(
          url: url('/a.apk'),
          target: target,
          expectedSha256: sha,
          onProgress: (_, _) {},
        );
        expect(jumlahPermintaan, 0);
      },
    );

    test('404 menjadi tidakAda dan alamat di luar GitHub ditolak sebelum menghubungi server', () async {
      await expectLater(
        pengunduh().download(
          url: url('/hilang.apk'),
          target: File('${tmp.path}/u.apk'),
          expectedSha256: sha,
          onProgress: (_, _) {},
        ),
        throwsA(
          isA<UpdateDownloadException>().having(
            (e) => e.reason,
            'reason',
            UpdateFailure.tidakAda,
          ),
        ),
      );
      final ketat = ApkDownloader(dio: Dio());
      await expectLater(
        ketat.download(
          url: url('/a.apk'),
          target: File('${tmp.path}/x.apk'),
          expectedSha256: sha,
          onProgress: (_, _) {},
        ),
        throwsA(
          isA<UpdateDownloadException>().having(
            (e) => e.reason,
            'reason',
            UpdateFailure.hostDitolak,
          ),
        ),
      );
    });
  });

  test('manifest dapat dibaca dari teks JSON', () {
    final m = UpdateManifest.fromJson(
      jsonDecode(jsonEncode(manifestJson())) as Map<String, dynamic>,
    );
    expect(m.version, '1.2.0');
  });
}
