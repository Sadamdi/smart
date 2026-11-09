import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_app_bar.dart';
import '../../auth/domain/pengguna.dart';
import '../../auth/presentation/auth_controller.dart';

const _labelKondisi = {
  'disabilitas': 'Penyandang disabilitas',
  'ekonomi_kurang_mampu': 'Ekonomi kurang mampu',
  'yatim_piatu': 'Yatim, piatu, atau yatim piatu',
  'daerah_3t': 'Daerah 3T',
  'penghafal_quran': 'Penghafal Al-Quran',
  'anak_tenaga_kesehatan': 'Anak tenaga kesehatan',
};

class ProfilPage extends ConsumerStatefulWidget {
  const ProfilPage({super.key});

  @override
  ConsumerState<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends ConsumerState<ProfilPage> {
  bool _ubah = false;
  bool _kirim = false;
  String? _galat;
  final _kunci = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _kampus = TextEditingController();
  final _prodi = TextEditingController();
  final _semester = TextEditingController();
  final _ipk = TextEditingController();
  final _kota = TextEditingController();
  final _minat = TextEditingController();
  final _catatan = TextEditingController();
  final _lahir = TextEditingController();
  final _ips = TextEditingController();
  final _penghasilan = TextEditingController();
  final _warga = TextEditingController();
  final _toefl = TextEditingController();
  final _ielts = TextEditingController();
  Set<String> _kondisi = {};
  String? _jenisKampus;
  String? _jenjang;

  @override
  void dispose() {
    for (final c in [
      _nama,
      _kampus,
      _prodi,
      _semester,
      _ipk,
      _kota,
      _minat,
      _catatan,
      _lahir,
      _ips,
      _penghasilan,
      _warga,
      _toefl,
      _ielts,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _isi(Pengguna p) {
    _nama.text = p.nama;
    _kampus.text = p.kampus ?? '';
    _prodi.text = p.programStudi ?? '';
    _semester.text = p.semester?.toString() ?? '';
    _ipk.text = p.ipk ?? '';
    _kota.text = p.kotaDomisili ?? '';
    _minat.text = p.minat.join(', ');
    _catatan.text = p.catatanTambahan ?? '';
    _lahir.text = p.tanggalLahir ?? '';
    _ips.text = p.ipsTerakhir ?? '';
    _penghasilan.text = p.penghasilanOrangTua?.toString() ?? '';
    _warga.text = p.kewarganegaraan ?? '';
    _toefl.text = p.skorBahasa['toefl']?.toString() ?? '';
    _ielts.text = p.skorBahasa['ielts']?.toString() ?? '';
    _kondisi = p.kondisiKhusus.toSet();
    _jenisKampus = p.jenisKampus;
    _jenjang = p.jenjang;
    _galat = null;
  }

  String? _wajibAngka(String? v, num min, num max, String nama) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final n = num.tryParse(s.replaceAll(',', '.'));
    if (n == null || n < min || n > max) {
      return '$nama harus berupa angka $min sampai $max.';
    }
    return null;
  }

  Future<void> _simpan() async {
    if (!_kunci.currentState!.validate()) return;
    setState(() {
      _kirim = true;
      _galat = null;
    });
    String? teks(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final minat = _minat.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    try {
      await ref
          .read(authControllerProvider.notifier)
          .ubahProfil(
            ProfilMasukan(
              nama: teks(_nama),
              kampus: teks(_kampus),
              jenisKampus: _jenisKampus,
              programStudi: teks(_prodi),
              jenjang: _jenjang,
              semester: int.tryParse(_semester.text.trim()),
              ipk: double.tryParse(_ipk.text.trim().replaceAll(',', '.')),
              kotaDomisili: teks(_kota),
              minat: minat.isEmpty ? null : minat,
              kondisiKhusus: _kondisi.toList(),
              catatanTambahan: _catatan.text.trim(),
              tanggalLahir: teks(_lahir),
              ipsTerakhir: double.tryParse(_ips.text.trim().replaceAll(',', '.')),
              penghasilanOrangTua: int.tryParse(
                _penghasilan.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
              ),
              kewarganegaraan: teks(_warga),
              skorBahasa: {
                if (_toefl.text.trim().isNotEmpty)
                  'toefl': num.tryParse(_toefl.text.trim()) ?? _toefl.text.trim(),
                if (_ielts.text.trim().isNotEmpty)
                  'ielts': num.tryParse(_ielts.text.trim().replaceAll(',', '.')) ??
                      _ielts.text.trim(),
              },
            ),
          );
      if (mounted) {
        setState(() => _ubah = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profil disimpan.')));
      }
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = ref.watch(authControllerProvider).pengguna;
    if (p == null) return const Scaffold(body: SizedBox.shrink());
    final kel = p.kelengkapan;

    return Scaffold(
      appBar: const SmartAppBar(),
      body: ListView(
        // Semua kolom form tetap terpasang agar validasi mencakup kolom yang di luar layar.
        // ignore: deprecated_member_use
        cacheExtent: 6000,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Profil Saya', style: t.headlineMedium),
          const SizedBox(height: 12),
          _HeaderProfil(
            nama: p.nama,
            email: p.email,
            terisi: kel.terisi,
            total: kel.total,
          ),
          const SizedBox(height: 16),
          if (!_ubah) ...[
            _KartuData(
              judul: 'Data akademik',
              baris: [
                ('Kampus', p.kampus),
                ('Jenis kampus', p.jenisKampus),
                ('Program studi', p.programStudi),
                ('Jenjang', p.jenjang),
                ('Semester', p.semester?.toString()),
                ('IPK', p.ipk),
                ('IPS terakhir', p.ipsTerakhir),
                ('TOEFL', p.skorBahasa['toefl']?.toString()),
                ('IELTS', p.skorBahasa['ielts']?.toString()),
              ],
            ),
            const SizedBox(height: 12),
            _KartuData(
              judul: 'Lainnya',
              baris: [
                ('Tanggal lahir', p.tanggalLahir),
                ('Kewarganegaraan', p.kewarganegaraan),
                (
                  'Penghasilan orang tua',
                  p.penghasilanOrangTua == null
                      ? null
                      : 'Rp${p.penghasilanOrangTua}',
                ),
                ('Kota domisili', p.kotaDomisili),
                ('Minat', p.minat.isEmpty ? null : p.minat.join(', ')),
                (
                  'Kondisi khusus',
                  p.kondisiKhusus.isEmpty
                      ? null
                      : p.kondisiKhusus
                            .map((k) => _labelKondisi[k] ?? k)
                            .join(', '),
                ),
                ('Catatan khusus', p.catatanTambahan),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => setState(() {
                _isi(p);
                _ubah = true;
              }),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Ubah profil'),
            ),
          ] else
            Form(
              key: _kunci,
              child: Column(
                children: [
                  _Kolom(
                    _nama,
                    'Nama lengkap',
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Nama tidak boleh kosong.'
                        : null,
                  ),
                  _Kolom(_kampus, 'Kampus'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _jenisKampus,
                      decoration: const InputDecoration(
                        labelText: 'Jenis kampus',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'negeri',
                          child: Text('Negeri'),
                        ),
                        DropdownMenuItem(
                          value: 'swasta',
                          child: Text('Swasta'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _jenisKampus = v),
                    ),
                  ),
                  _Kolom(_prodi, 'Program studi'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _jenjang,
                      decoration: const InputDecoration(labelText: 'Jenjang'),
                      items: [
                        for (final j in ['D3', 'D4', 'S1', 'S2', 'S3'])
                          DropdownMenuItem(value: j, child: Text(j)),
                      ],
                      onChanged: (v) => setState(() => _jenjang = v),
                    ),
                  ),
                  _Kolom(
                    _semester,
                    'Semester',
                    angka: true,
                    validator: (v) => _wajibAngka(v, 1, 14, 'Semester'),
                  ),
                  _Kolom(
                    _ipk,
                    'IPK',
                    angka: true,
                    validator: (v) => _wajibAngka(v, 0, 4, 'IPK'),
                  ),
                  _Kolom(
                    _ips,
                    'IPS terakhir',
                    angka: true,
                    validator: (v) => _wajibAngka(v, 0, 4, 'IPS'),
                  ),
                  _Kolom(
                    _toefl,
                    'Skor TOEFL (opsional)',
                    angka: true,
                    validator: (v) => _wajibAngka(v, 0, 677, 'TOEFL'),
                  ),
                  _Kolom(
                    _ielts,
                    'Skor IELTS (opsional)',
                    angka: true,
                    validator: (v) => _wajibAngka(v, 0, 9, 'IELTS'),
                  ),
                  _Kolom(
                    _lahir,
                    'Tanggal lahir (TTTT-BB-HH)',
                    hint: '2004-08-17',
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      return DateTime.tryParse(s) == null
                          ? 'Tulis tanggal seperti 2004-08-17.'
                          : null;
                    },
                  ),
                  _Kolom(_warga, 'Kewarganegaraan', hint: 'Indonesia'),
                  _Kolom(
                    _penghasilan,
                    'Penghasilan orang tua per bulan (Rp)',
                    angka: true,
                  ),
                  _Kolom(_kota, 'Kota domisili'),
                  _Kolom(
                    _minat,
                    'Minat (pisahkan dengan koma)',
                    hint: 'teknologi, riset, kepemimpinan',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profil tambahan (opsional, tidak dikirim ke layanan AI)',
                      style: t.titleSmall,
                    ),
                  ),
                  for (final e in _labelKondisi.entries)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.value),
                      value: _kondisi.contains(e.key),
                      onChanged: (v) => setState(
                        () => v == true
                            ? _kondisi.add(e.key)
                            : _kondisi.remove(e.key),
                      ),
                    ),
                  _Kolom(
                    _catatan,
                    'Catatan khusus',
                    hint: 'Contoh: penerima KIP',
                  ),
                  if (_galat != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _galat!,
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
                        : const Text('Simpan perubahan'),
                  ),
                  TextButton(
                    onPressed: _kirim
                        ? null
                        : () => setState(() => _ubah = false),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Material(
            color: Warna.kartu,
            borderRadius: BorderRadius.circular(Jari.kartu),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final (i, m) in [
                  (Icons.badge_outlined, 'Profil Lanjutan', '/profil-lanjutan'),
                  (Icons.description_outlined, 'Dokumen Saya', '/dokumen'),
                  (Icons.chat_bubble_outline, 'Chatbot AI', '/chat'),
                  (Icons.settings_outlined, 'Pengaturan', '/pengaturan'),
                ].indexed) ...[
                  if (i > 0) const Divider(indent: 64),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Warna.container3,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.$1, size: 20, color: Warna.primary),
                    ),
                    title: Text(m.$2),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(m.$3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Warna.error,
              side: BorderSide(color: Warna.error.withValues(alpha: 0.5)),
            ),
            onPressed: () => ref.read(authControllerProvider.notifier).keluar(),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _Kolom extends StatelessWidget {
  const _Kolom(
    this.c,
    this.label, {
    this.validator,
    this.angka = false,
    this.hint,
  });

  final TextEditingController c;
  final String label;
  final String? Function(String?)? validator;
  final bool angka;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: validator,
        keyboardType: angka
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

class _HeaderProfil extends StatelessWidget {
  const _HeaderProfil({
    required this.nama,
    required this.email,
    required this.terisi,
    required this.total,
  });

  final String nama;
  final String email;
  final int terisi;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final huruf = nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F6FC0), Color(0xFF143F7C)],
        ),
        borderRadius: BorderRadius.circular(Jari.kartu),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  huruf,
                  style: t.titleLarge?.copyWith(color: Warna.putih),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: t.titleLarge?.copyWith(color: Warna.putih),
                    ),
                    Text(
                      email,
                      style: t.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Kelengkapan profil: $terisi dari $total',
            style: t.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(Jari.bulat),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : terisi / total,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFF5B73B)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu kartu berisi beberapa pasang label dan nilai, dipisah garis tipis.
class _KartuData extends StatelessWidget {
  const _KartuData({required this.judul, required this.baris});

  final String judul;
  final List<(String, String?)> baris;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: Warna.kartu,
        borderRadius: BorderRadius.circular(Jari.kartu),
        boxShadow: bayanganKartu,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: t.labelSmall),
          const SizedBox(height: 4),
          for (final (i, b) in baris.indexed) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 4, child: Text(b.$1, style: t.bodySmall)),
                  Expanded(
                    flex: 6,
                    child: Text(
                      (b.$2 == null || b.$2!.isEmpty) ? 'Belum diisi' : b.$2!,
                      textAlign: TextAlign.end,
                      style: (b.$2 == null || b.$2!.isEmpty)
                          ? t.bodySmall
                          : t.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
