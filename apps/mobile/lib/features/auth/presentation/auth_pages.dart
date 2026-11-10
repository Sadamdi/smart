import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/logo_smart.dart';
import 'auth_controller.dart';

final _pola = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _Kerangka extends StatelessWidget {
  const _Kerangka({
    required this.judul,
    required this.subjudul,
    required this.anak,
    required this.kaki,
  });

  final String judul;
  final String subjudul;
  final Widget anak;
  final Widget kaki;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const LogoSmart(ukuran: 84),
                    const SizedBox(height: 14),
                    Text(
                      'SMART',
                      style: t.headlineMedium?.copyWith(letterSpacing: 3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scholarship Monitoring & Recommendation Tool',
                      textAlign: TextAlign.center,
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(judul, style: t.headlineMedium?.copyWith(fontSize: 24)),
              const SizedBox(height: 6),
              Text(subjudul, style: t.bodyMedium),
              const SizedBox(height: 20),
              anak,
              const SizedBox(height: 20),
              Center(child: kaki),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _kunci = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _c = Get.find<AuthController>();
  bool _lihat = false;

  @override
  void initState() {
    super.initState();
    _c.bersihkanForm();
  }

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_kunci.currentState!.validate()) return;
    await _c.masuk(_email.text.trim(), _sandi.text);
  }

  @override
  Widget build(BuildContext context) {
    return _Kerangka(
      judul: 'Masuk ke Akun SMART',
      subjudul: 'Akses rekomendasi beasiswa berdasarkan profilmu, pantau tenggat, dan siapkan berkas.',
      kaki: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Belum punya akun?'),
          TextButton(
            onPressed: () => context.go('/daftar'),
            child: const Text('Daftar Akun Baru'),
          ),
        ],
      ),
      anak: Form(
        key: _kunci,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'nama@kampus.ac.id',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) => _pola.hasMatch((v ?? '').trim())
                  ? null
                  : 'Masukkan alamat email yang valid.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sandi,
              obscureText: !_lihat,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                hintText: 'Minimal 8 karakter',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _lihat ? 'Sembunyikan' : 'Tampilkan',
                  icon: Icon(
                    _lihat ? Icons.visibility_off : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _lihat = !_lihat),
                ),
              ),
              validator: (v) =>
                  (v ?? '').isEmpty ? 'Kata sandi wajib diisi.' : null,
              onFieldSubmitted: (_) => _masuk(),
            ),
            Obx(
              () => _c.galatForm.value == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _KotakGalat(_c.galatForm.value!),
                    ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => FilledButton(
                onPressed: _c.mengirim.value ? null : _masuk,
                child: _c.mengirim.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Masuk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  final _kunci = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _c = Get.find<AuthController>();
  bool _lihat = false;

  @override
  void initState() {
    super.initState();
    _c.bersihkanForm();
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (!_kunci.currentState!.validate()) return;
    await _c.daftar(_nama.text.trim(), _email.text.trim(), _sandi.text);
  }

  @override
  Widget build(BuildContext context) {
    return _Kerangka(
      judul: 'Buat Akun SMART',
      subjudul: 'Daftar dulu, lalu lengkapi profil akademikmu agar rekomendasi sesuai.',
      kaki: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Sudah punya akun?'),
          TextButton(
            onPressed: () => context.go('/masuk'),
            child: const Text('Masuk'),
          ),
        ],
      ),
      anak: Form(
        key: _kunci,
        child: Column(
          children: [
            TextFormField(
              controller: _nama,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama lengkap',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Nama wajib diisi.'
                  : (v!.trim().length > 200 ? 'Nama terlalu panjang.' : null),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) => _pola.hasMatch((v ?? '').trim())
                  ? null
                  : 'Masukkan alamat email yang valid.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sandi,
              obscureText: !_lihat,
              decoration: InputDecoration(
                labelText: 'Kata sandi',
                hintText: 'Minimal 8 karakter',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _lihat ? 'Sembunyikan' : 'Tampilkan',
                  icon: Icon(
                    _lihat ? Icons.visibility_off : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _lihat = !_lihat),
                ),
              ),
              validator: (v) => (v ?? '').length < 8
                  ? 'Kata sandi minimal 8 karakter.'
                  : null,
            ),
            Obx(
              () => _c.galatForm.value == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _KotakGalat(_c.galatForm.value!),
                    ),
            ),
            const SizedBox(height: 20),
            Obx(
              () => FilledButton(
                onPressed: _c.mengirim.value ? null : _daftar,
                child: _c.mengirim.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Daftar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KotakGalat extends StatelessWidget {
  const _KotakGalat(this.pesan);

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.errorSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: Warna.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pesan,
              key: const Key('galat-form'),
              style: TextStyle(color: Warna.error),
            ),
          ),
        ],
      ),
    );
  }
}
