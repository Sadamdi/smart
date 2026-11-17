import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/domain/pengguna.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/profil_lanjutan.dart';
import 'profil_controller.dart';

const _jenjang = ['D3', 'D4', 'S1', 'S2', 'S3'];
const _jenisSekolah = ['SMA', 'SMK', 'MA', 'Pesantren', 'Lainnya'];
const _tingkat = ['sekolah', 'kota', 'provinsi', 'nasional', 'internasional'];
const _jenisSertifikat = [
  'keahlian',
  'bahasa',
  'kepanitiaan',
  'pelatihan',
  'kompetensi',
  'lainnya',
];

/// Satu bagian daftar (organisasi, prestasi, sertifikat, pengalaman): judul, kolom isian, dan petunjuk contoh.
class _Bagian {
  const _Bagian(this.kunci, this.judul, this.kolom, this.petunjuk);

  final String kunci;
  final String judul;
  final List<_Kolom> kolom;
  final String petunjuk;
}

class _Kolom {
  const _Kolom(this.kunci, this.label, {this.pilihan, this.angka = false});

  final String kunci;
  final String label;
  final List<String>? pilihan;
  final bool angka;
}

const _bagian = [
  _Bagian('organisasi', 'Organisasi', [
    _Kolom('nama', 'Nama organisasi'),
    _Kolom('jabatan', 'Jabatan'),
    _Kolom('tahun', 'Tahun', angka: true),
  ], 'Contoh: HMJ Teknik Informatika, Ketua, 2025'),
  _Bagian('prestasi', 'Prestasi', [
    _Kolom('nama', 'Nama prestasi'),
    _Kolom('tingkat', 'Tingkat', pilihan: _tingkat),
    _Kolom('tahun', 'Tahun', angka: true),
  ], 'Contoh: Juara 2 OSN, nasional, 2022'),
  _Bagian('sertifikat', 'Sertifikat', [
    _Kolom('nama', 'Nama sertifikat'),
    _Kolom('jenis', 'Jenis', pilihan: _jenisSertifikat),
    _Kolom('penerbit', 'Penerbit'),
    _Kolom('tahun', 'Tahun', angka: true),
  ], 'Keahlian, bahasa, kepanitiaan, pelatihan, atau kompetensi'),
  _Bagian('pengalaman', 'Pengalaman kerja, magang, atau relawan', [
    _Kolom('nama', 'Tempat atau kegiatan'),
    _Kolom('peran', 'Peran'),
    _Kolom('tahun', 'Tahun', angka: true),
  ], 'Contoh: Magang Telkom, Data analyst, 2025'),
];

/// Profil lanjutan: bagian berkartu dengan daftar butir (tambah lewat lembar isian, ubah, hapus) dan tombol simpan
/// yang menempel di bawah serta menghormati area aman (tidak tertutup tombol navigasi Android).
class ProfilLanjutanPage extends StatefulWidget {
  const ProfilLanjutanPage({super.key});

  @override
  State<ProfilLanjutanPage> createState() => _ProfilLanjutanPageState();
}

class _ProfilLanjutanPageState extends State<ProfilLanjutanPage> {
  final _ctrl = Get.find<ProfilController>();
  final _c = <String, TextEditingController>{};
  final _daftar = <String, List<Map<String, dynamic>>>{};
  final _keahlian = <String>[];
  String? _jenisSekolahPilih;
  final Set<String> _jenjangPilih = {};
  bool get _kirim => _ctrl.mengirim.value;
  bool _terisi = false;

  TextEditingController _ctl(String k) =>
      _c.putIfAbsent(k, TextEditingController.new);

  void _isi(Pengguna p) {
    final l = p.profilLanjutan;
    for (final k in [
      'provinsi_asal',
      'kota_asal',
      'sekolah_asal',
      'jurusan_sekolah',
      'fakultas',
    ]) {
      _ctl(k).text = '${l[k] ?? ''}';
    }
    _ctl('tahun_lulus').text = '${l['tahun_lulus'] ?? ''}';
    for (final b in _bagian) {
      _daftar[b.kunci] = [
        for (final x in (l[b.kunci] as List? ?? []))
          if (x is Map) Map<String, dynamic>.from(x),
      ];
    }
    _keahlian
      ..clear()
      ..addAll((l['keahlian'] as List? ?? []).map((e) => '$e'));
    final ts = l['target_studi'] as Map? ?? {};
    _ctl('negara').text = (ts['negara'] as List? ?? []).join(', ');
    _ctl('bidang').text = (ts['bidang'] as List? ?? []).join(', ');
    _jenjangPilih
      ..clear()
      ..addAll((ts['jenjang'] as List? ?? []).map((e) => '$e'));
    _jenisSekolahPilih = l['jenis_sekolah'] as String?;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _teks(String k) {
    final t = _ctl(k).text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _simpan() async {
    final peta = <String, dynamic>{
      'provinsi_asal': _teks('provinsi_asal'),
      'kota_asal': _teks('kota_asal'),
      'sekolah_asal': _teks('sekolah_asal'),
      'jenis_sekolah': _jenisSekolahPilih,
      'jurusan_sekolah': _teks('jurusan_sekolah'),
      'tahun_lulus': int.tryParse(_ctl('tahun_lulus').text.trim()),
      'fakultas': _teks('fakultas'),
      for (final b in _bagian)
        b.kunci: _daftar[b.kunci] ?? <Map<String, dynamic>>[],
      'keahlian': _keahlian,
      'target_studi': {
        'jenjang': _jenjangPilih.toList(),
        'negara': uraiDaftarKoma(_ctl('negara').text),
        'bidang': uraiDaftarKoma(_ctl('bidang').text),
      },
    };
    final ok = await _ctrl.simpan(ProfilMasukan(profilLanjutan: peta));
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profil lanjutan disimpan. Rekomendasi sedang diperbarui.',
          ),
        ),
      );
      context.pop();
    }
  }

  /// Lembar isian satu butir; mengembalikan butir baru atau null bila dibatalkan.
  Future<Map<String, dynamic>?> _lembar(_Bagian b, Map<String, dynamic>? awal) {
    final ctl = {
      for (final k in b.kolom)
        k.kunci: TextEditingController(text: '${awal?[k.kunci] ?? ''}'),
    };
    final pilih = <String, String?>{
      for (final k in b.kolom.where((k) => k.pilihan != null))
        k.kunci: awal?[k.kunci] as String?,
    };
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          // Papan ketik dan area aman mendorong isi naik, jadi tombol tidak tertutup.
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).viewPadding.bottom +
                16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  awal == null
                      ? 'Tambah ${b.judul.toLowerCase()}'
                      : 'Ubah ${b.judul.toLowerCase()}',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(b.petunjuk, style: Theme.of(ctx).textTheme.bodySmall),
                const SizedBox(height: 16),
                for (final k in b.kolom) ...[
                  if (k.pilihan != null)
                    DropdownButtonFormField<String>(
                      initialValue: pilih[k.kunci],
                      decoration: InputDecoration(labelText: k.label),
                      items: [
                        for (final o in k.pilihan!)
                          DropdownMenuItem(value: o, child: Text(o)),
                      ],
                      onChanged: (v) => setS(() => pilih[k.kunci] = v),
                    )
                  else
                    TextField(
                      controller: ctl[k.kunci],
                      keyboardType: k.angka
                          ? TextInputType.number
                          : TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(labelText: k.label),
                    ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final butir = <String, dynamic>{};
                      for (final k in b.kolom) {
                        final v = k.pilihan != null
                            ? pilih[k.kunci]
                            : ctl[k.kunci]!.text.trim();
                        if (v == null || v.isEmpty) continue;
                        butir[k.kunci] = k.angka ? int.tryParse(v) : v;
                      }
                      butir.removeWhere((_, v) => v == null);
                      if ((butir['nama'] as String?)?.isEmpty ?? true) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Nama wajib diisi.')),
                        );
                        return;
                      }
                      Navigator.pop(ctx, butir);
                    },
                    child: const Text('Simpan butir'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      for (final c in ctl.values) {
        c.dispose();
      }
    });
  }

  Future<void> _tambahUbah(_Bagian b, {int? indeks}) async {
    final daftar = _daftar.putIfAbsent(b.kunci, () => []);
    final hasil = await _lembar(b, indeks == null ? null : daftar[indeks]);
    if (hasil == null || !mounted) return;
    setState(() => indeks == null ? daftar.add(hasil) : daftar[indeks] = hasil);
  }

  Future<void> _tambahKeahlian() async {
    final ctl = TextEditingController();
    final nilai = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah keahlian'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Contoh: Python, analisis data',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    ctl.dispose();
    if (nilai == null || !mounted) return;
    final baru = uraiDaftarKoma(nilai)
        .where((x) => !_keahlian.contains(x))
        .toList();
    if (baru.isNotEmpty) setState(() => _keahlian.addAll(baru));
  }

  Widget _kolom(String k, String label, {bool angka = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _ctl(k),
      keyboardType: angka ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    ),
  );

  Widget _kartu({
    required String judul,
    String? keterangan,
    required List<Widget> anak,
    Widget? aksi,
  }) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu + 4),
        border: Border.all(color: Warna.container4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(judul, style: t.titleMedium)),
              ?aksi,
            ],
          ),
          if (keterangan != null) ...[
            const SizedBox(height: 2),
            Text(keterangan, style: t.bodySmall),
          ],
          const SizedBox(height: 12),
          ...anak,
        ],
      ),
    );
  }

  Widget _bagianDaftar(_Bagian b) {
    final t = Theme.of(context).textTheme;
    final isi = _daftar[b.kunci] ?? [];
    return _kartu(
      judul: b.judul,
      keterangan: isi.isEmpty
          ? 'Belum ada. ${b.petunjuk}'
          : '${isi.length} butir',
      aksi: TextButton.icon(
        onPressed: () => _tambahUbah(b),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Tambah'),
      ),
      anak: [
        for (final (i, x) in isi.indexed)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Warna.container1,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              dense: true,
              onTap: () => _tambahUbah(b, indeks: i),
              title: Text(
                '${x['nama'] ?? ''}',
                style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  for (final k in b.kolom.skip(1))
                    if ('${x[k.kunci] ?? ''}'.isNotEmpty) '${x[k.kunci]}',
                ].join(' | '),
                style: t.bodySmall,
              ),
              trailing: IconButton(
                tooltip: 'Hapus',
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                onPressed: () => setState(() => isi.removeAt(i)),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _ctrl.bersihkanGalat();
  }

  @override
  Widget build(BuildContext context) => Obx(() => _bangun(context));

  Widget _bangun(BuildContext context) {
    final p = Get.find<AuthController>().pengguna;
    if (p != null && !_terisi) {
      _isi(p);
      _terisi = true;
    }
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Lanjutan')),
      // Tombol simpan menempel di bawah dan memakai area aman: tidak tertimpa tombol navigasi Android.
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Warna.surface,
            border: Border(top: BorderSide(color: Warna.container4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_ctrl.galat.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _ctrl.galat.value!,
                    style: TextStyle(color: Warna.error),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _kirim ? null : _simpan,
                  child: _kirim
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan profil lanjutan'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Opsional. Makin lengkap, estimasi peluang makin tepat. Anda juga dapat mengunggah CV di menu Dokumen agar AI mengisinya.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 16),
          _kartu(
            judul: 'Asal daerah dan sekolah',
            anak: [
              _kolom('provinsi_asal', 'Provinsi asal'),
              _kolom('kota_asal', 'Kota atau kabupaten asal'),
              _kolom('sekolah_asal', 'Sekolah asal'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _jenisSekolahPilih,
                  decoration: const InputDecoration(labelText: 'Jenis sekolah'),
                  items: [
                    for (final j in _jenisSekolah)
                      DropdownMenuItem(value: j, child: Text(j)),
                  ],
                  onChanged: (v) => setState(() => _jenisSekolahPilih = v),
                ),
              ),
              _kolom('jurusan_sekolah', 'Jurusan di sekolah'),
              _kolom('tahun_lulus', 'Tahun lulus', angka: true),
              _kolom('fakultas', 'Fakultas'),
            ],
          ),
          for (final b in _bagian) _bagianDaftar(b),
          _kartu(
            judul: 'Keahlian',
            keterangan: _keahlian.isEmpty
                ? 'Belum ada. Tambahkan keahlian yang kamu kuasai.'
                : null,
            aksi: TextButton.icon(
              onPressed: _tambahKeahlian,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah'),
            ),
            anak: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final k in _keahlian)
                    InputChip(
                      label: Text(k),
                      onDeleted: () => setState(() => _keahlian.remove(k)),
                    ),
                ],
              ),
            ],
          ),
          _kartu(
            judul: 'Target studi dan beasiswa',
            keterangan: 'Jenjang tujuan dipakai saat menilai beasiswa jenjang berikutnya (mis. S1 menuju S2).',
            anak: [
              Wrap(
                spacing: 8,
                children: [
                  for (final j in _jenjang)
                    FilterChip(
                      label: Text(j),
                      selected: _jenjangPilih.contains(j),
                      onSelected: (v) => setState(
                        () =>
                            v ? _jenjangPilih.add(j) : _jenjangPilih.remove(j),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _kolom(
                'negara',
                'Negara tujuan (pisahkan dengan koma; kosong bila dalam negeri)',
              ),
              _kolom('bidang', 'Bidang yang diminati (pisahkan dengan koma)'),
            ],
          ),
        ],
      ),
    );
  }
}
