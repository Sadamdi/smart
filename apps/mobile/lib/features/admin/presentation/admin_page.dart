import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/dependensi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ilustrasi_gerak.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../core/widgets/tombol_bulat.dart';
import '../data/admin_repository.dart';

/// Panel admin ringan: Ringkasan (pekerjaan yang menunggu), Antrean validasi (terbitkan atau tolak), dan Sumber
/// (saklar aktif dan Pantau sekarang). Ubah data beasiswa yang rinci tetap di web.
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
  AdminRepository get _repo => Get.find<AdminRepository>();

  LaporanAdmin? _laporan;
  List<AntreanAdmin>? _antrean;
  List<SumberAdmin>? _sumber;
  Object? _galat;
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final hasil = await Future.wait([
        _repo.laporan(),
        _repo.antrean(),
        _repo.sumber(),
      ]);
      if (!mounted) return;
      setState(() {
        _laporan = hasil[0] as LaporanAdmin;
        _antrean = hasil[1] as List<AntreanAdmin>;
        _sumber = hasil[2] as List<SumberAdmin>;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = e;
        _memuat = false;
      });
    }
  }

  Future<void> _jalankan(Future<void> Function() aksi, String berhasil) async {
    final pesan = ScaffoldMessenger.of(context);
    try {
      await aksi();
      pesan.showSnackBar(SnackBar(content: Text(berhasil)));
    } catch (e) {
      pesan.showSnackBar(SnackBar(content: Text(pesanGalat(e))));
    }
    await _muat();
  }

  Future<void> _tolak(AntreanAdmin a) async {
    final alasan = TextEditingController();
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak beasiswa'),
        content: TextField(
          controller: alasan,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Alasan penolakan',
            hintText: 'Contoh: laman menolak robot (403)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    final teks = alasan.text.trim();
    alasan.dispose();
    if (ya != true || !mounted) return;
    if (teks.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan penolakan wajib diisi.')),
      );
      return;
    }
    await _jalankan(() => _repo.tolak(a.id, teks), 'Beasiswa ditolak.');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TombolBulat.kembali(context),
        ),
        title: Text('Panel admin', style: t.titleMedium),
        bottom: TabBar(
          controller: _tab,
          tabs: [
            const Tab(text: 'Ringkasan'),
            Tab(text: 'Antrean (${_antrean?.length ?? 0})'),
            Tab(text: 'Sumber (${_sumber?.length ?? 0})'),
          ],
        ),
      ),
      body: _memuat && _laporan == null
          ? const MemuatHalaman()
          : _galat != null && _laporan == null
          ? GalatState(pesan: pesanGalat(_galat!), cobaLagi: _muat)
          : RefreshIndicator(
              onRefresh: _muat,
              child: TabBarView(
                controller: _tab,
                children: [_ringkasan(t), _daftarAntrean(t), _daftarSumber(t)],
              ),
            ),
    );
  }

  Widget _bantuan(String judul, List<String> baris) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Warna.container1,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Warna.container4),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline_rounded, size: 18, color: Warna.primary),
            const SizedBox(width: 6),
            Text(judul, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        for (final b in baris) ...[
          const SizedBox(height: 6),
          Text(b, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );

  Widget _angka(String label, int nilai, {Color? warna}) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Warna.container4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$nilai',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: warna ?? Warna.navy,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );

  Widget _ringkasan(TextTheme t) {
    final l = _laporan;
    if (l == null) return const SizedBox.shrink();
    final tindakan = l.tindakan;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bantuan('Alur kerja admin', const [
          '1. Di tab Sumber, tekan Pantau sekarang agar sistem membaca laman resmi.',
          '2. Di tab Antrean, terbitkan atau tolak beasiswa yang masuk.',
          '3. Hanya beasiswa terbit yang tampil ke mahasiswa. Laman yang menolak robot (403) otomatis ditolak dan tidak dicoba lagi.',
        ]),
        Row(
          children: [
            _angka(
              'Menunggu',
              l.menunggu,
              warna: l.menunggu > 0 ? Warna.primary : null,
            ),
            const SizedBox(width: 10),
            _angka('Terbit', l.terbit),
            const SizedBox(width: 10),
            _angka(
              'Sumber gagal',
              l.sumberGagal,
              warna: l.sumberGagal > 0 ? Warna.error : null,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Perlu tindakan', style: t.titleMedium),
        const SizedBox(height: 8),
        if (tindakan.isEmpty)
          Text(
            'Tidak ada yang perlu dikerjakan. Antrean kosong dan semua sumber berhasil diperiksa.',
            style: t.bodyMedium,
          )
        else
          for (final x in tindakan)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(x.teks),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _tab.animateTo(x.tab == 'antrean' ? 1 : 2),
              ),
            ),
        const SizedBox(height: 12),
        Text(
          '${l.jumlahMahasiswa} mahasiswa terdaftar, ${l.jumlahSumber} sumber dipantau.',
          style: t.bodySmall,
        ),
      ],
    );
  }

  bool _hanyaDitandai = false;

  Widget _daftarAntrean(TextTheme t) {
    final semua = _antrean ?? const <AntreanAdmin>[];
    final tampil = _hanyaDitandai
        ? [
            for (final a in semua)
              if (a.alasanDitandai != null) a,
          ]
        : semua;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bantuan('Cara memakai', const [
          'Terbitkan bila data sudah benar. Tolak dengan alasan bila laman tidak dapat dipakai. Untuk memperbaiki data beasiswa yang rinci, buka versi web.',
        ]),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text('Semua (${semua.length})'),
              selected: !_hanyaDitandai,
              onSelected: (_) => setState(() => _hanyaDitandai = false),
            ),
            ChoiceChip(
              label: Text(
                'Ditandai (${semua.where((a) => a.alasanDitandai != null).length})',
              ),
              selected: _hanyaDitandai,
              onSelected: (_) => setState(() => _hanyaDitandai = true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (tampil.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: KosongState(
              ilustrasi: Gulungan(),
              judul: 'Antrean kosong',
              pesan: 'Tidak ada beasiswa yang menunggu validasi.',
            ),
          ),
        for (final a in tampil)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.nama, style: t.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${a.penyelenggara ?? 'Penyelenggara belum terbaca'} | Sumber: ${a.namaSumber ?? '-'}',
                    style: t.bodySmall,
                  ),
                  if (a.alasanDitandai != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      a.alasanDitandai!,
                      style: t.bodySmall?.copyWith(color: Warna.error),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _jalankan(
                            () => _repo.terbitkan(a.id),
                            'Beasiswa diterbitkan.',
                          ),
                          child: const Text('Terbitkan'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _tolak(a),
                          child: const Text('Tolak'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  final _hasilPantau = <String, String>{};
  final _memantau = <String>{};

  Widget _daftarSumber(TextTheme t) {
    final daftar = _sumber ?? const <SumberAdmin>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bantuan('Cara memakai', const [
          'Pantau sekarang membaca laman resmi dan menyimpan beasiswa yang ditemukan ke antrean. Saklar menghentikan atau melanjutkan pemantauan otomatis tanpa menghapus sumber.',
          'Status Gagal berarti pemeriksaan terakhir tidak berhasil. Coba pantau lagi.',
        ]),
        for (final s in daftar)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(s.nama, style: t.titleSmall)),
                      Switch(
                        value: s.aktif,
                        onChanged: (v) => _jalankan(
                          () => _repo.aturAktif(s.id, v),
                          v ? 'Sumber diaktifkan.' : 'Sumber dinonaktifkan.',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    s.status == 'gagal'
                        ? 'Pemeriksaan terakhir gagal'
                        : s.status == 'berhasil'
                        ? 'Pemeriksaan terakhir berhasil'
                        : 'Belum pernah diperiksa',
                    style: t.bodySmall?.copyWith(
                      color: s.status == 'gagal' ? Warna.error : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (s.bisaDipantau) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _memantau.contains(s.id)
                              ? null
                              : () async {
                                  setState(() => _memantau.add(s.id));
                                  try {
                                    final h = await _repo.pantau(s.id);
                                    _hasilPantau[s.id] = h;
                                  } catch (e) {
                                    _hasilPantau[s.id] = pesanGalat(e);
                                  }
                                  _memantau.remove(s.id);
                                  await _muat();
                                },
                          icon: _memantau.contains(s.id)
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: JamPasir(ukuran: 16),
                                )
                              : const Icon(Icons.sync_rounded, size: 18),
                          label: Text(
                            _memantau.contains(s.id)
                                ? 'Memantau'
                                : 'Pantau sekarang',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _hasilPantau[s.id] ?? '',
                            style: t.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
