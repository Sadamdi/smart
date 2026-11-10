import '../../../core/api_client.dart';
import '../../../core/token_storage.dart';
import '../domain/pengguna.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  Future<bool> adaToken() async => (await _storage.baca()) != null;

  Future<Pengguna> masuk(String email, String kataSandi) async {
    final r = await _api.post(
      '/auth/login',
      body: {'email': email, 'kata_sandi': kataSandi},
    );
    return _simpanSesi(r.data as Map<String, dynamic>);
  }

  Future<Pengguna> daftar(String nama, String email, String kataSandi) async {
    final r = await _api.post(
      '/auth/register',
      body: {'nama': nama, 'email': email, 'kata_sandi': kataSandi},
    );
    return _simpanSesi(r.data as Map<String, dynamic>);
  }

  Future<Pengguna> _simpanSesi(Map<String, dynamic> d) async {
    await _storage.simpan(
      PasanganToken(
        akses: d['token_akses'] as String,
        penyegar: d['token_penyegar'] as String,
      ),
    );
    // Login hanya mengembalikan token; pendaftaran mengembalikan token beserta pengguna.
    final p = d['pengguna'];
    if (p is Map<String, dynamic>) return Pengguna.fromJson(p);
    return saya();
  }

  Future<Pengguna> saya() async {
    final r = await _api.get('/me');
    return Pengguna.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Pengguna> ubahProfil(ProfilMasukan m) async {
    final r = await _api.put('/me/profil', body: m.toJson());
    return Pengguna.fromJson(r.data as Map<String, dynamic>);
  }

  /// Daftar negara dan provinsi untuk pilihan domisili (tanpa autentikasi, data tetap).
  Future<ReferensiWilayah> wilayah() async {
    final r = await _api.get('/referensi/wilayah');
    return ReferensiWilayah.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Pengguna> ubahPreferensi({
    required bool email,
    required bool push,
  }) async {
    final r = await _api.put(
      '/me/preferensi-notifikasi',
      body: {'email': email, 'push': push},
    );
    return Pengguna.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> keluar() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Token dihapus di perangkat walau server tidak terjangkau.
    }
    await _storage.hapus();
  }
}
