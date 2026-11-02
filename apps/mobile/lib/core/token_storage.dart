import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Pasangan token yang disimpan di perangkat.
class PasanganToken {
  const PasanganToken({required this.akses, required this.penyegar});

  final String akses;
  final String penyegar;
}

abstract class TokenStorage {
  Future<PasanganToken?> baca();
  Future<void> simpan(PasanganToken token);
  Future<void> hapus();
}

/// Penyimpanan aman (Keystore Android). Token tidak pernah ditulis ke repo atau log.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? s])
    : _s = s ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;
  static const _kAkses = 'token_akses';
  static const _kPenyegar = 'token_penyegar';

  @override
  Future<PasanganToken?> baca() async {
    final a = await _s.read(key: _kAkses);
    final p = await _s.read(key: _kPenyegar);
    if (a == null || p == null) return null;
    return PasanganToken(akses: a, penyegar: p);
  }

  @override
  Future<void> simpan(PasanganToken token) async {
    await _s.write(key: _kAkses, value: token.akses);
    await _s.write(key: _kPenyegar, value: token.penyegar);
  }

  @override
  Future<void> hapus() async {
    await _s.delete(key: _kAkses);
    await _s.delete(key: _kPenyegar);
  }
}

/// Untuk uji.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this._t]);

  PasanganToken? _t;

  @override
  Future<PasanganToken?> baca() async => _t;

  @override
  Future<void> simpan(PasanganToken token) async => _t = token;

  @override
  Future<void> hapus() async => _t = null;
}
