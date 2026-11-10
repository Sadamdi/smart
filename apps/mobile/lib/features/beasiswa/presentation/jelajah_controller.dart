import 'package:get/get.dart';

import '../../../core/dependensi.dart';
import '../data/beasiswa_repository.dart';
import '../domain/beasiswa.dart';

class JelajahState {
  const JelajahState({
    this.items = const [],
    this.kursor,
    this.memuat = true,
    this.memuatLagi = false,
    this.galat,
    this.galatLagi,
    this.q = '',
    this.jenjang,
  });

  final List<BeasiswaRingkas> items;
  final String? kursor;
  final bool memuat;
  final bool memuatLagi;
  final String? galat;
  final String? galatLagi;
  final String q;
  final String? jenjang;

  bool get adaLagi => kursor != null;

  JelajahState salin({
    List<BeasiswaRingkas>? items,
    Object? kursor = _tak,
    bool? memuat,
    bool? memuatLagi,
    Object? galat = _tak,
    Object? galatLagi = _tak,
    String? q,
    Object? jenjang = _tak,
  }) => JelajahState(
    items: items ?? this.items,
    kursor: identical(kursor, _tak) ? this.kursor : kursor as String?,
    memuat: memuat ?? this.memuat,
    memuatLagi: memuatLagi ?? this.memuatLagi,
    galat: identical(galat, _tak) ? this.galat : galat as String?,
    galatLagi: identical(galatLagi, _tak)
        ? this.galatLagi
        : galatLagi as String?,
    q: q ?? this.q,
    jenjang: identical(jenjang, _tak) ? this.jenjang : jenjang as String?,
  );
}

const _tak = Object();

/// Daftar Jelajah dengan pencarian, filter jenjang, dan paginasi kursor.
class JelajahController extends GetxController {
  final state = const JelajahState().obs;

  BeasiswaRepository get _repo => Get.find<BeasiswaRepository>();

  bool _diminta = false;

  Future<void> pastikan() => _diminta ? Future.value() : muat();

  void bersihkan() {
    _diminta = false;
    state.value = const JelajahState();
  }

  Future<void> muat() async {
    _diminta = true;
    state.value = state.value.salin(memuat: true, galat: null, galatLagi: null);
    final q = state.value.q;
    final jenjang = state.value.jenjang;
    try {
      final h = await _repo.daftar(q: q, jenjang: jenjang);
      if (q != state.value.q || jenjang != state.value.jenjang) {
        return; // sudah kedaluwarsa
      }
      state.value = state.value.salin(
        items: h.items,
        kursor: h.kursorBerikut,
        memuat: false,
      );
    } catch (e) {
      state.value = state.value.salin(memuat: false, galat: pesanGalat(e));
    }
  }

  Future<void> lagi() async {
    final s = state.value;
    if (s.memuat || s.memuatLagi || !s.adaLagi) return;
    state.value = s.salin(memuatLagi: true, galatLagi: null);
    try {
      final h = await _repo.daftar(
        q: s.q,
        jenjang: s.jenjang,
        kursor: s.kursor,
      );
      state.value = state.value.salin(
        items: [...state.value.items, ...h.items],
        kursor: h.kursorBerikut,
        memuatLagi: false,
      );
    } catch (e) {
      state.value = state.value.salin(
        memuatLagi: false,
        galatLagi: pesanGalat(e),
      );
    }
  }

  Future<void> cari(String q) {
    state.value = state.value.salin(q: q.trim());
    return muat();
  }

  Future<void> pilihJenjang(String? jenjang) {
    state.value = state.value.salin(jenjang: jenjang);
    return muat();
  }
}
