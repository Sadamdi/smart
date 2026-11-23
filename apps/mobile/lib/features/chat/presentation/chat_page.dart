import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cache_lokal.dart';
import '../../../core/lokal/mesin_lokal.dart';
import '../../../core/lokal/model_ai.dart';
import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chips.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../data/chat_repository.dart';
import 'lampiran_ui.dart';
import 'saran_chat.dart';
import 'statistik_chat.dart';
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
        Get.find<MesinLokal>().aiLokalAktif ||
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
    List<({String nama, String? teks, String? path})> lampiran = const [],
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
            if (saya && lampiran.isNotEmpty) ...[
              for (final l in lampiran)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: ChipLampiranPesan(
                    nama: l.nama,
                    teks: l.teks,
                    path: l.path,
                  ),
                ),
              if (teks.trim().isNotEmpty) const SizedBox(height: 2),
            ],
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
        case 'ganti_nama':
          await _gantiNama();
        case 'hapus_sesi':
          await _hapusSesiIni();
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
          await tampilkanStatistikChat(
            context,
            awal: _c.statistikLokal(),
            muat: _c.statistik,
          );
      }
    } catch (e) {
      _info(pesanGalat(e));
    }
  }

  Future<void> _gantiNama() async {
    if (_c.sesiId.value == null) {
      _info('Kirim pesan dulu agar percakapan ini punya nama.');
      return;
    }
    final c = TextEditingController(text: _c.sesiJudul.value);
    final baru = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti nama percakapan'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 60,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, c.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (baru == null || baru.trim().isEmpty) return;
    await _c.ubahJudul(baru);
  }

  Future<void> _hapusSesiIni() async {
    final id = _c.sesiId.value;
    if (id == null) return;
    final s = (_c.daftarSesi.value ?? const <SesiChat>[]).firstWhere(
      (x) => x.id == id,
      orElse: () =>
          SesiChat(id: id, judul: _c.sesiJudul.value, diubah: DateTime.now()),
    );
    await _c.hapusSesi(s);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Percakapan dihapus'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () async => _info(await _c.urungkanHapus()),
        ),
      ),
    );
  }

  /// Baris di bawah kepala halaman: percakapan yang dibuka (ketuk untuk memilih), sumber jawaban AI, baru, dan menu.
  Widget _barisSesi(TextTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push('/chat/sesi'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Warna.kartu,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Warna.container4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _c.sesiJudul.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _PilihanAi(),
          IconButton(
            tooltip: 'Percakapan baru',
            onPressed: _c.mengirim.value ? null : _c.sesiBaru,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu chat',
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'ganti_nama',
                child: Text('Ganti nama percakapan'),
              ),
              PopupMenuItem(
                value: 'hapus_sesi',
                child: Text('Hapus percakapan ini'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(value: 'statistik', child: Text('Statistik chat')),
              PopupMenuItem(value: 'memori', child: Text('Memori Pintar')),
              PopupMenuItem(value: 'cadang', child: Text('Cadangkan riwayat')),
              PopupMenuItem(value: 'pulih', child: Text('Pulihkan riwayat')),
              PopupMenuItem(value: 'hapus', child: Text('Hapus semua riwayat')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tersedia = _c.bisaMenjawab;
    final riwayat = _c.riwayat.state.value;
    final kirim = _c.mengirim.value;
    final galat = _c.galat.value;
    final papan = MediaQuery.viewInsetsOf(context).bottom > 0; // papan ketik terbuka: sembunyikan hiasan

    return Scaffold(
      appBar: const SmartAppBar(),
      body: Column(
        children: [
          _barisSesi(t),
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
                    _gelembung(p.pesan, saya: true, lampiran: p.lampiran),
                    _gelembung(
                      p.jawaban ?? 'Belum ada jawaban.',
                      saya: false,
                      gaya: t.bodyMedium,
                      rujukan: p.rujukan,
                      sumber: p.sumber,
                    ),
                  ],
                  if (_c.pesanSementara.value != null) ...[
                    _gelembung(
                      _c.pesanSementara.value!,
                      saya: true,
                      lampiran: _c.lampiranSementara.toList(),
                    ),
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
          if (_c.catatan.value != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_c.catatan.value!, style: t.bodySmall),
            ),
          if (!papan)
            SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final q in _c.saranModel.isNotEmpty && _c.lampiran.isEmpty
                    ? _c.saranModel
                    : saranBerikut(
                        riwayat.value ?? const [],
                        lampiran: _c.lampiran.isNotEmpty,
                        data: _c.saranData,
                      ))
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
          if (_c.lampiran.isNotEmpty || _c.mengunggah.value) ...[
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final l in _c.lampiran)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: KartuLampiran(
                        nama: l.nama,
                        ukuran: l.ukuran,
                        status: l.catatan,
                        onHapus: () => _c.lepas(l),
                        onTap: () => tampilkanPratinjauLampiran(
                          context,
                          nama: l.nama,
                          teks: l.teks,
                          path: l.pathAsli,
                        ),
                      ),
                    ),
                  if (_c.mengunggah.value)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: KartuLampiran(
                        nama: _c.mengunggahNama.value ?? 'Berkas',
                        membaca: true,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_c.lampiran.length}/$lampiranMaksBerkas berkas  ·  maks ${ukuranTeks(lampiranMaksByte)} per berkas',
                  style: t.bodySmall?.copyWith(fontSize: 11),
                ),
              ),
            ),
          ],
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip:
                        'Lampirkan berkas (maks $lampiranMaksBerkas berkas, ${ukuranTeks(lampiranMaksByte)} per berkas). ${ChatController.keteranganJenis}',
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
          if (!papan)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Jawaban AI bisa keliru dan bukan jaminan diterima beasiswa.',
                  maxLines: 1,
                  style: t.bodySmall?.copyWith(fontSize: 11, color: Warna.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
                  // Model dimuat sekarang agar jawaban pertama tidak menunggu.
                  if (k == 'ponsel') ai.siapkanDiLatarBelakang();
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
