import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
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
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Warna.primary,
                        borderRadius: BorderRadius.circular(Jari.kartu),
                      ),
                      child: const Icon(
                        Icons.school,
                        size: 38,
                        color: Warna.putih,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('SMART', style: t.headlineMedium),
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
              Text(judul, style: t.titleLarge?.copyWith(fontSize: 22)),
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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _kunci = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _lihat = false;
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_kunci.currentState!.validate()) return;
    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .masuk(_email.text.trim(), _sandi.text);
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
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
            if (_galat != null) ...[
              const SizedBox(height: 12),
              Text(
                _galat!,
                key: const Key('galat-form'),
                style: const TextStyle(color: Warna.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _kirim ? null : _masuk,
              child: _kirim
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}

class DaftarPage extends ConsumerStatefulWidget {
  const DaftarPage({super.key});

  @override
  ConsumerState<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends ConsumerState<DaftarPage> {
  final _kunci = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _kirim = false;
  String? _galat;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (!_kunci.currentState!.validate()) return;
    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .daftar(_nama.text.trim(), _email.text.trim(), _sandi.text);
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
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
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata sandi',
                hintText: 'Minimal 8 karakter',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) => (v ?? '').length < 8
                  ? 'Kata sandi minimal 8 karakter.'
                  : null,
            ),
            if (_galat != null) ...[
              const SizedBox(height: 12),
              Text(
                _galat!,
                key: const Key('galat-form'),
                style: const TextStyle(color: Warna.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _kirim ? null : _daftar,
              child: _kirim
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Daftar'),
            ),
          ],
        ),
      ),
    );
  }
}
