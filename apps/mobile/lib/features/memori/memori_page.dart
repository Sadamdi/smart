import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/api_client.dart';
import '../../core/dependensi.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/tombol_bulat.dart';

class ButirMemori {
  const ButirMemori({
    required this.id,
    required this.jenis,
    required this.isi,
    required this.aktif,
    this.sumber,
  });

  final String id;
  final String jenis;
  final String isi;
  final bool aktif;
  final String? sumber;

  /// Asal butir: dibuat otomatis oleh AI dari percakapan atau dokumen, atau ditulis sendiri.
  String get asal => switch (sumber) {
    'chat' => 'otomatis dari percakapan',
    'manual' => 'ditulis sendiri',
    null => 'ditulis sendiri',
    _ => 'otomatis dari dokumen',
  };

  factory ButirMemori.fromJson(Map<String, dynamic> j) => ButirMemori(
    id: j['id'] as String,
    jenis: j['jenis'] as String,
    isi: j['isi'] as String,
    aktif: (j['aktif'] ?? true) as bool,
    sumber: j['sumber'] as String?,
  );
}

/// Halaman Memori AI: apa yang dipelajari asisten dari dokumen dan percakapan. Setiap butir dapat dinyalakan atau
/// dimatikan, disunting, atau dihapus; ada saklar utama dan perkiraan beban (token) yang ditambahkan ke tiap pertanyaan.
class MemoriPage extends StatefulWidget {
  const MemoriPage({super.key});

  @override
  State<MemoriPage> createState() => _MemoriPageState();
}

class _MemoriPageState extends State<MemoriPage> {
  final _api = Get.find<ApiClient>();
  List<ButirMemori>? _daftar;
  Map<String, dynamic> _stat = const {};
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final r = await _api.get('/me/memori');
      final s = await _api.get('/me/memori/statistik');
      if (!mounted) return;
      setState(() {
        _daftar = [
          for (final x in r.data as List)
            ButirMemori.fromJson(x as Map<String, dynamic>),
        ];
        _stat = s.data as Map<String, dynamic>;
        _galat = null;
      });
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    }
  }

  Future<void> _jalankan(Future<void> Function() f) async {
    try {
      await f();
      await _muat();
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    }
  }

  /// Mengubah saklar langsung di layar (tanpa menunggu server), lalu menyelaraskan; dikembalikan bila gagal.
  Future<void> _ubahAktif(ButirMemori b, bool v) async {
    final d = _daftar;
    if (d == null) return;
    setState(() {
      _daftar = [
        for (final x in d)
          if (x.id == b.id)
            ButirMemori(
              id: x.id,
              jenis: x.jenis,
              isi: x.isi,
              aktif: v,
              sumber: x.sumber,
            )
          else
            x,
      ];
    });
    try {
      await _api.patch('/me/memori/${b.id}', body: {'aktif': v});
      await _muat();
    } catch (e) {
      if (!mounted) return;
      setState(() => _daftar = d);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
  }

  Future<void> _sunting(ButirMemori b) async {
    final c = TextEditingController(text: b.isi);
    final baru = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sunting memori'),
        content: TextField(
          controller: c,
          maxLines: 4,
          maxLength: 480,
          autofocus: true,
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
    await _jalankan(
      () => _api.patch('/me/memori/${b.id}', body: {'isi': baru}),
    );
  }

  Future<void> _tambah() async {
    final c = TextEditingController();
    var jenis = 'lainnya';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Tambah memori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: jenis,
                isExpanded: true,
                items: [
                  for (final j in [
                    'keahlian',
                    'prestasi',
                    'organisasi',
                    'sertifikat',
                    'pengalaman',
                    'minat',
                    'kepribadian',
                    'lainnya',
                  ])
                    DropdownMenuItem(value: j, child: Text(j)),
                ],
                onChanged: (v) => setD(() => jenis = v ?? jenis),
              ),
              TextField(
                controller: c,
                maxLines: 3,
                maxLength: 480,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Aktif sebagai relawan mengajar 2 tahun',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    await _jalankan(
      () => _api.post('/me/memori', body: {'jenis': jenis, 'isi': c.text}),
    );
  }

  Future<void> _hapusSemua() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus seluruh memori?'),
        content: const Text(
          'Asisten tidak lagi mengingat hal-hal ini. Dokumenmu tidak ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus semua'),
          ),
        ],
      ),
    );
    if (ya == true) await _jalankan(() => _api.delete('/me/memori'));
  }

  IconData _ikon(String jenis) => switch (jenis) {
    'keahlian' => Icons.build_outlined,
    'prestasi' => Icons.emoji_events_outlined,
    'organisasi' => Icons.groups_outlined,
    'sertifikat' => Icons.workspace_premium_outlined,
    'pengalaman' => Icons.work_outline_rounded,
    'minat' => Icons.favorite_border_rounded,
    'kepribadian' => Icons.psychology_outlined,
    _ => Icons.sticky_note_2_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = _daftar;
    final utama = (_stat['memori_aktif'] ?? true) as bool;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TombolBulat.kembali(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah memori',
            onPressed: _tambah,
            icon: const Icon(Icons.add_rounded),
          ),
          if (d != null && d.isNotEmpty)
            TextButton(
              onPressed: _hapusSemua,
              child: const Text('Hapus semua'),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text('Memori AI', style: t.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Hal-hal yang dipelajari asisten dari dokumen yang kamu unggah (CV, sertifikat, penghargaan) dan percakapan. '
              'Dipakai untuk menilai kecocokan dan kekurangan profilmu. Disimpan terenkripsi di server dan hanya kamu yang bisa melihatnya.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Warna.kartu,
                borderRadius: BorderRadius.circular(Jari.kartu),
                border: Border.all(color: Warna.container4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Pakai memori saat menjawab',
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Hidup: jawaban lebih personal dan pintar, tetapi sedikit lebih lambat dan lebih berat. Mati: jawaban umum, lebih cepat.',
                      style: t.bodySmall,
                    ),
                    value: utama,
                    onChanged: (v) => _jalankan(
                      () =>
                          _api.put('/me/memori/pengaturan', body: {'aktif': v}),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Dipakai ${_stat['jumlah_dipakai'] ?? 0} dari ${_stat['jumlah'] ?? 0} butir, '
                    'menambah sekitar ${_stat['perkiraan_token'] ?? 0} token pada tiap pertanyaan.',
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_galat != null)
              Text(_galat!, style: t.bodyMedium?.copyWith(color: Warna.error))
            else if (d == null)
              const Center(child: CircularProgressIndicator())
            else if (d.isEmpty)
              Text(
                'Belum ada memori. Lampirkan CV atau sertifikat di chatbot, atau unggah di Dokumen Saya.',
                style: t.bodyMedium,
              )
            else
              for (final b in d)
                Opacity(
                  opacity: utama && b.aktif ? 1 : 0.5,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    decoration: BoxDecoration(
                      color: Warna.kartu,
                      borderRadius: BorderRadius.circular(Jari.kartu),
                      border: Border.all(color: Warna.container4),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_ikon(b.jenis), color: Warna.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _sunting(b),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${b.jenis} · ${b.asal}',
                                  style: t.labelSmall?.copyWith(
                                    color: Warna.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(b.isi, style: t.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                        Switch(
                          value: b.aktif,
                          onChanged: (v) => _ubahAktif(b, v),
                        ),
                        IconButton(
                          tooltip: 'Hapus',
                          onPressed: () => _jalankan(
                            () => _api.delete('/me/memori/${b.id}'),
                          ),
                          icon: Icon(Icons.close_rounded, color: Warna.muted),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
