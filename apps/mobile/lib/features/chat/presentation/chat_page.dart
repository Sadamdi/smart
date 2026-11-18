import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cache_lokal.dart';
import '../../../core/lokal/mesin_lokal.dart';
import '../../../core/lokal/model_ai.dart';
import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/teks_markdown.dart';
import '../../../core/widgets/state_widgets.dart';
import 'chat_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _c = Get.find<ChatController>();
  final _isi = TextEditingController();

  @override
  void initState() {
    super.initState();
    _c.buka();
    // Model AI luring dimuat di latar belakang hanya bila mode luring aktif atau jaringan putus, bukan saat aplikasi dibuka.
    if (Get.find<MesinLokal>().aktif.value ||
        Get.find<CacheLokal>().luring.value) {
      Get.find<PengelolaModelAi>().siapkanDiLatarBelakang();
    }
  }

  @override
  void dispose() {
    _gulir.dispose();
    _isi.dispose();
    super.dispose();
  }

  final _gulir = ScrollController();

  /// Gelembung jawaban yang sedang mengalir; kosong = model sedang menyiapkan jawaban.
  Widget _gelembungAlir(String teks) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gulir.hasClients) {
        _gulir.jumpTo(_gulir.position.maxScrollExtent);
      }
    });
    if (teks.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Warna.kartu,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Warna.container4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Menyiapkan jawaban',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Warna.kartu,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Warna.container4),
        ),
        child: TeksMarkdown(teks),
      ),
    );
  }

  Future<void> _kirimPesan() async {
    final ok = await _c.kirim(_isi.text.trim());
    if (ok) _isi.clear();
  }

  Widget _gelembung(
    String teks, {
    required bool saya,
    TextStyle? gaya,
    List<({String id, String nama})> rujukan = const [],
    String sumber = 'server',
  }) {
    return Align(
      alignment: saya ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: saya ? Warna.primary : Warna.kartu,
          borderRadius: BorderRadius.circular(18),
          border: saya ? null : Border.all(color: Warna.container4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saya)
              Text(
                teks,
                style: (gaya ?? Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(fontSize: 14, height: 1.45, color: Colors.white),
              )
            else
              TeksMarkdown(teks),
            if (!saya) ...[const SizedBox(height: 8), _LencanaSumber(sumber)],
            if (rujukan.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Sumber data beasiswa SMART',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final r in rujukan.take(3))
                    ActionChip(
                      label: Text(r.nama, overflow: TextOverflow.ellipsis),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/beasiswa/${r.id}'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _pil(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(26),
    borderSide: BorderSide(color: c, width: w),
  );

  void _info(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _menu(String k) async {
    try {
      switch (k) {
        case 'memori':
          context.push('/memori');
        case 'cadang':
          _info(await _c.cadangkan());
        case 'pulih':
          _info(await _c.pulihkan());
        case 'hapus':
          await _c.hapusRiwayat();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Riwayat dihapus'),
              action: SnackBarAction(
                label: 'Urungkan',
                onPressed: () async => _info(await _c.urungkanHapus()),
              ),
            ),
          );
        case 'statistik':
          final d = await _c.statistik();
          if (!mounted) return;
          final top = [
            for (final b in (d['beasiswa_teratas'] as List? ?? []))
              '${(b as Map)['nama']} (${b['jumlah']})',
          ];
          final isi =
              '${d['jumlah']} pertanyaan, ${d['tujuh_hari']} dalam 7 hari terakhir.\n'
              'Rata-rata jawaban ${d['rata_panjang_jawaban']} karakter.'
              '${top.isEmpty ? '' : '\n\nPaling sering dirujuk:\n${top.join('\n')}'}';
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Isi chatbot'),
              content: Text(isi),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          );
      }
    } catch (e) {
      _info(pesanGalat(e));
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tersedia = _c.bisaMenjawab;
    final riwayat = _c.riwayat.state.value;
    final kirim = _c.mengirim.value;
    final galat = _c.galat.value;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Asisten AI', style: t.titleLarge?.copyWith(fontSize: 18)),
        actions: [
          const _PilihanAi(),
          PopupMenuButton<String>(
            tooltip: 'Menu chat',
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'statistik', child: Text('Statistik chat')),
              PopupMenuItem(value: 'memori', child: Text('Memori AI')),
              PopupMenuItem(value: 'cadang', child: Text('Cadangkan riwayat')),
              PopupMenuItem(value: 'pulih', child: Text('Pulihkan riwayat')),
              PopupMenuItem(value: 'hapus', child: Text('Hapus riwayat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!tersedia)
            Container(
              width: double.infinity,
              color: Warna.errorSoft,
              padding: const EdgeInsets.all(12),
              child: Text(
                'Chatbot belum dapat menjawab saat ini. Anda tetap dapat menelusuri beasiswa dan melihat rekomendasi.',
                style: TextStyle(color: Warna.error),
              ),
            ),
          Expanded(
            child: riwayat.when(
              loading: () => const MemuatState(),
              error: (e, _) => Center(child: Text(pesanGalat(e))),
              data: (daftar) => ListView(
                controller: _gulir,
                padding: const EdgeInsets.all(16),
                children: [
                  _gelembung(
                    'Halo! Tanyakan syarat, tenggat, atau berkas beasiswa. Jawaban saya berdasarkan data di SMART.',
                    saya: false,
                    sumber: '',
                    gaya: t.bodyMedium,
                  ),
                  for (final p in daftar) ...[
                    _gelembung(p.pesan, saya: true),
                    _gelembung(
                      p.jawaban ?? 'Belum ada jawaban.',
                      saya: false,
                      gaya: t.bodyMedium,
                      rujukan: p.rujukan,
                      sumber: p.sumber,
                    ),
                  ],
                  if (_c.pesanSementara.value != null) ...[
                    _gelembung(_c.pesanSementara.value!, saya: true),
                    _gelembungAlir(_c.jawabanSementara.value),
                  ],
                ],
              ),
            ),
          ),
          if (galat != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(galat, style: TextStyle(color: Warna.error)),
            ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final q
                    in _c.lampiran.isNotEmpty ? _Saran.lampiran : _Saran.daftar)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChipFilter(
                      label: q,
                      terpilih: false,
                      onTap: () {
                        _isi.text = q;
                        _kirimPesan();
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_c.lampiran.isNotEmpty || _c.mengunggah.value)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final l in _c.lampiran)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        avatar: const Icon(
                          Icons.description_outlined,
                          size: 16,
                        ),
                        label: Text(l.nama, overflow: TextOverflow.ellipsis),
                        onDeleted: () => _c.lepas(l),
                      ),
                    ),
                  if (_c.mengunggah.value)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Chip(label: Text('Membaca dokumen')),
                    ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Lampirkan CV atau dokumen',
                    onPressed:
                        kirim ||
                            _c.lampiran.length >= ChatController.lampiranMaks
                        ? null
                        : _c.lampirkan,
                    icon: Icon(Icons.attach_file_rounded, color: Warna.primary),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _isi,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _kirimPesan(),
                      decoration: InputDecoration(
                        hintText: 'Tulis pertanyaanmu',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: _pil(Warna.outline),
                        enabledBorder: _pil(Warna.outline),
                        focusedBorder: _pil(Warna.primary, 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: kirim ? 'Hentikan jawaban' : 'Kirim',
                    style: IconButton.styleFrom(
                      backgroundColor: Warna.primary,
                      foregroundColor: Warna.putih,
                      minimumSize: const Size(48, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: kirim ? _c.batalkan : _kirimPesan,
                    icon: Icon(kirim ? Icons.stop_rounded : Icons.send),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Jawaban chatbot bukan jaminan diterima pada beasiswa mana pun.',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _Saran {
  static const lampiran = [
    'Analisis CV saya, apa kekurangannya?',
    'Beasiswa apa yang paling cocok dengan dokumen ini?',
    'Apa yang perlu saya perbaiki?',
  ];

  static const daftar = [
    'Syarat IPK',
    'Berkas apa saja?',
    'Tenggat minggu ini',
    'Cocok untuk saya?',
  ];
}

/// Penanda asal jawaban: server, model AI di ponsel, atau data lokal.
class _LencanaSumber extends StatelessWidget {
  const _LencanaSumber(this.sumber);

  final String sumber;

  @override
  Widget build(BuildContext context) {
    final (ikon, teks) = switch (sumber) {
      'ponsel' => (Icons.smartphone_rounded, 'Dijawab model AI di ponsel'),
      'lokal' => (Icons.storage_rounded, 'Dijawab dari data di ponsel'),
      _ => (Icons.cloud_outlined, 'Dijawab layanan AI server'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 14, color: Warna.muted),
        const SizedBox(width: 4),
        Text(teks, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Pilihan sumber jawaban di kepala halaman: Otomatis, Ponsel, atau Server (panel penjelasan saat ditekan).
class _PilihanAi extends StatelessWidget {
  const _PilihanAi();

  static const _label = {
    'otomatis': ('Otomatis', Icons.auto_awesome_rounded),
    'ponsel': ('Di ponsel', Icons.smartphone_rounded),
    'server': ('Server', Icons.cloud_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final mesin = Get.find<MesinLokal>();
    return ListenableBuilder(
      listenable: Listenable.merge([mesin.modeAi, mesin.aktif]),
      builder: (context, _) {
        // Mode luring tidak menghubungi server, jadi jawaban selalu dari ponsel.
        final kunci = mesin.aktif.value ? 'ponsel' : mesin.modeAi.value;
        final (teks, ikon) = _label[kunci]!;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: ActionChip(
            avatar: Icon(ikon, size: 16, color: Warna.primary),
            label: Text(teks),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            visualDensity: VisualDensity.compact,
            onPressed: () => _buka(context, mesin),
          ),
        );
      },
    );
  }

  void _buka(BuildContext context, MesinLokal mesin) {
    final ai = Get.find<PengelolaModelAi>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            mesin.modeAi,
            mesin.aktif,
            ai.status,
            ai.aktifId,
          ]),
          builder: (ctx, _) {
            final t = Theme.of(ctx).textTheme;
            final terpasang = ai.dipakai;
            Widget opsi(
              String k,
              String judul,
              String isi, {
              bool aktifkan = true,
            }) {
              final dipilih = mesin.modeAi.value == k && !mesin.aktif.value;
              return ListTile(
                enabled: aktifkan && !mesin.aktif.value,
                leading: Icon(
                  _label[k]!.$2,
                  color: dipilih ? Warna.primary : null,
                ),
                title: Text(
                  judul,
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(isi, style: t.bodySmall),
                trailing: dipilih
                    ? Icon(Icons.check_circle, color: Warna.primary)
                    : null,
                onTap: () {
                  mesin.aturModeAi(k);
                  Navigator.pop(ctx);
                },
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Jawaban AI dari mana?', style: t.titleMedium),
                  ),
                ),
                if (mesin.aktif.value)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      'Mode luring sedang aktif, jadi jawaban selalu dari ponsel dan tidak menghubungi server SMART.',
                      style: t.bodySmall,
                    ),
                  ),
                opsi(
                  'otomatis',
                  'Otomatis (disarankan)',
                  'Server saat ada jaringan, otomatis pindah ke model di ponsel saat jaringan putus.',
                ),
                opsi(
                  'ponsel',
                  'Di ponsel',
                  terpasang
                      ? 'Selalu memakai model AI di ponsel walau ada internet. Data tidak keluar dari ponsel.'
                      : 'Butuh model AI terpasang. Unduh di Pengaturan, Chatbot AI luring.',
                  aktifkan: terpasang,
                ),
                opsi(
                  'server',
                  'Server',
                  'Selalu memakai layanan AI server. Jawaban lebih lengkap, butuh jaringan.',
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}
