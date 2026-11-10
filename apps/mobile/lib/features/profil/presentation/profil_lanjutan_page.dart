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

class ProfilLanjutanPage extends StatefulWidget {
  const ProfilLanjutanPage({super.key});

  @override
  State<ProfilLanjutanPage> createState() => _ProfilLanjutanPageState();
}

class _ProfilLanjutanPageState extends State<ProfilLanjutanPage> {
  final _ctrl = Get.find<ProfilController>();
  final _c = <String, TextEditingController>{};
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
    _ctl('organisasi').text = formatBaris(l['organisasi'] as List? ?? [], [
      'nama',
      'jabatan',
      'tahun',
    ]);
    _ctl('prestasi').text = formatBaris(l['prestasi'] as List? ?? [], [
      'nama',
      'tingkat',
      'tahun',
    ]);
    _ctl('sertifikat').text = formatBaris(l['sertifikat'] as List? ?? [], [
      'nama',
      'penerbit',
      'tahun',
    ]);
    _ctl('pengalaman').text = formatBaris(l['pengalaman'] as List? ?? [], [
      'nama',
      'peran',
      'tahun',
    ]);
    _ctl('keahlian').text = (l['keahlian'] as List? ?? []).join(', ');
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
      'organisasi': uraiBaris(_ctl('organisasi').text, [
        'nama',
        'jabatan',
        'tahun',
      ]),
      'prestasi': uraiBaris(_ctl('prestasi').text, [
        'nama',
        'tingkat',
        'tahun',
      ]),
      'sertifikat': uraiBaris(_ctl('sertifikat').text, [
        'nama',
        'penerbit',
        'tahun',
      ]),
      'pengalaman': uraiBaris(_ctl('pengalaman').text, [
        'nama',
        'peran',
        'tahun',
      ]),
      'keahlian': uraiDaftarKoma(_ctl('keahlian').text),
      'target_studi': {
        'jenjang': _jenjangPilih.toList(),
        'negara': uraiDaftarKoma(_ctl('negara').text),
        'bidang': uraiDaftarKoma(_ctl('bidang').text),
      },
    };
    final ok = await _ctrl.simpan(ProfilMasukan(profilLanjutan: peta));
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil lanjutan disimpan.')),
      );
      context.pop();
    }
  }

  Widget _kolom(
    String k,
    String label, {
    String? hint,
    int baris = 1,
    bool angka = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _ctl(k),
      minLines: baris,
      maxLines: baris == 1 ? 1 : baris + 2,
      keyboardType: angka ? TextInputType.number : TextInputType.multiline,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Opsional. Makin lengkap, rekomendasi makin terarah. Anda juga dapat mengunggah CV di menu Dokumen agar AI mengisinya.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('Asal daerah dan sekolah', style: t.titleSmall),
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          Text(
            'Satu butir per baris, pisahkan kolom dengan tanda |',
            style: t.bodySmall,
          ),
          const SizedBox(height: 8),
          _kolom(
            'organisasi',
            'Organisasi (nama | jabatan | tahun)',
            hint: 'HMJ Teknik Informatika | Ketua | 2025',
            baris: 3,
          ),
          _kolom(
            'prestasi',
            'Prestasi (nama | tingkat | tahun)',
            hint: 'Juara 2 OSN | nasional | 2022',
            baris: 3,
          ),
          _kolom(
            'sertifikat',
            'Sertifikat (nama | penerbit | tahun)',
            hint: 'TOEFL ITP | ETS | 2026',
            baris: 3,
          ),
          _kolom(
            'pengalaman',
            'Pengalaman (tempat | peran | tahun)',
            hint: 'Magang Telkom | Data analyst | 2025',
            baris: 3,
          ),
          _kolom(
            'keahlian',
            'Keahlian (pisahkan dengan koma)',
            hint: 'Python, analisis data',
          ),
          const SizedBox(height: 8),
          Text('Target studi dan beasiswa', style: t.titleSmall),
          Wrap(
            spacing: 8,
            children: [
              for (final j in _jenjang)
                FilterChip(
                  label: Text(j),
                  selected: _jenjangPilih.contains(j),
                  onSelected: (v) => setState(
                    () => v ? _jenjangPilih.add(j) : _jenjangPilih.remove(j),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _kolom('negara', 'Negara tujuan (koma; kosong bila dalam negeri)'),
          _kolom('bidang', 'Bidang yang diminati (pisahkan dengan koma)'),
          if (_ctrl.galat.value != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _ctrl.galat.value!,
                style: TextStyle(color: Warna.error),
              ),
            ),
          FilledButton(
            onPressed: _kirim ? null : _simpan,
            child: _kirim
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan profil lanjutan'),
          ),
        ],
      ),
    );
  }
}
