import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/metrik_dan_progres.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Profil Saya', style: t.headlineMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Warna.putih,
              borderRadius: BorderRadius.circular(Jari.kartu),
              boxShadow: bayanganKartu,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nama, style: t.titleLarge),
                Text(p.email, style: t.bodyMedium),
                const SizedBox(height: 12),
                Text(
                  'Kelengkapan profil: ${kel.terisi} dari ${kel.total}',
                  style: t.bodySmall,
                ),
                const SizedBox(height: 6),
                BarProgres(nilai: kel.terisi / kel.total),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_ubah) ...[
            _Baris('Kampus', p.kampus),
            _Baris('Jenis kampus', p.jenisKampus),
            _Baris('Program studi', p.programStudi),
            _Baris('Jenjang', p.jenjang),
            _Baris('Semester', p.semester?.toString()),
            _Baris('IPK', p.ipk),
            _Baris('Kota domisili', p.kotaDomisili),
            _Baris('Minat', p.minat.isEmpty ? null : p.minat.join(', ')),
            _Baris(
              'Kondisi khusus',
              p.kondisiKhusus.isEmpty
                  ? null
                  : p.kondisiKhusus
                        .map((k) => _labelKondisi[k] ?? k)
                        .join(', '),
            ),
            _Baris('Catatan khusus', p.catatanTambahan),
            const SizedBox(height: 16),
            FilledButton.icon(
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
                        style: const TextStyle(color: Warna.error),
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
          for (final m in [
            (Icons.description_outlined, 'Dokumen Saya', '/dokumen'),
            (Icons.chat_bubble_outline, 'Chatbot AI', '/chat'),
            (Icons.settings_outlined, 'Pengaturan', '/pengaturan'),
          ])
            ListTile(
              leading: Icon(m.$1),
              title: Text(m.$2),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(m.$3),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
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

class _Baris extends StatelessWidget {
  const _Baris(this.label, this.nilai);

  final String label;
  final String? nilai;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final kosong = nilai == null || nilai!.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Warna.putih,
        borderRadius: BorderRadius.circular(Jari.kartuDalam),
        boxShadow: bayanganKartu,
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(label, style: t.bodySmall)),
          Expanded(
            flex: 6,
            child: Text(
              kosong ? 'Belum diisi' : nilai!,
              textAlign: TextAlign.end,
              style: kosong ? t.bodySmall : t.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
