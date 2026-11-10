import 'package:get/get.dart';

/// Tiga keadaan data jaringan: memuat, galat, dan data.
enum StatusMuat { memuat, galat, data }

/// Keadaan satu sumber data. Berisi data terakhir bila ada, dan galat mentah bila gagal.
class AsyncState<T> {
  const AsyncState._(this.status, this.data, this.galat);

  const AsyncState.memuat([T? data]) : this._(StatusMuat.memuat, data, null);
  const AsyncState.sukses(T data) : this._(StatusMuat.data, data, null);
  const AsyncState.gagal(Object galat) : this._(StatusMuat.galat, null, galat);

  final StatusMuat status;
  final T? data;
  final Object? galat;

  T? get value => data;
  bool get hasValue => status == StatusMuat.data;
  bool get memuat => status == StatusMuat.memuat;
  bool get adaGalat => status == StatusMuat.galat;

  R when<R>({
    required R Function() loading,
    required R Function(Object e, StackTrace s) error,
    required R Function(T data) data,
  }) {
    switch (status) {
      case StatusMuat.memuat:
        return loading();
      case StatusMuat.galat:
        return error(galat!, StackTrace.empty);
      case StatusMuat.data:
        return data(this.data as T);
    }
  }
}

/// Pemegang satu sumber data async untuk dipakai di GetxController: [state] reaktif (Rx), [muat] mengambil ulang.
/// Data lama tetap terlihat selama pemuatan ulang; galat menggantikan data.
class Muatan<T> {
  Muatan(this._ambil);

  final Future<T> Function() _ambil;
  final state = Rx<AsyncState<T>>(const AsyncState.memuat());
  int _generasi = 0;
  bool _diminta = false;

  T? get value => state.value.data;

  /// Memuat hanya bila belum pernah diminta. Aman dipanggil dari initState layar.
  Future<void> pastikan() => _diminta ? Future.value() : muat();

  /// Mengosongkan data (mis. saat keluar) agar akun berikutnya tidak melihat data lama.
  void reset() {
    _generasi++;
    _diminta = false;
    state.value = const AsyncState.memuat();
  }

  Future<void> muat() async {
    _diminta = true;
    final g = ++_generasi;
    final lama = state.value.data;
    if (lama == null) state.value = const AsyncState.memuat();
    try {
      final hasil = await _ambil();
      if (g == _generasi) state.value = AsyncState.sukses(hasil);
    } catch (e) {
      if (g == _generasi) state.value = AsyncState.gagal(e);
    }
  }

  /// Ubah data lokal tanpa ke jaringan (mis. pembaruan optimistis).
  void atur(T nilai) => state.value = AsyncState.sukses(nilai);
}
