import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
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
class JelajahController extends Notifier<JelajahState> {
  @override
  JelajahState build() {
    Future.microtask(muat);
    return const JelajahState();
  }

  Future<void> muat() async {
    state = state.salin(memuat: true, galat: null, galatLagi: null);
    final q = state.q;
    final jenjang = state.jenjang;
    try {
      final h = await ref
          .read(beasiswaRepositoryProvider)
          .daftar(q: q, jenjang: jenjang);
      if (q != state.q || jenjang != state.jenjang) return; // sudah kedaluwarsa
      state = state.salin(
        items: h.items,
        kursor: h.kursorBerikut,
        memuat: false,
      );
    } catch (e) {
      state = state.salin(memuat: false, galat: pesanGalat(e));
    }
  }

  Future<void> lagi() async {
    if (state.memuat || state.memuatLagi || !state.adaLagi) return;
    state = state.salin(memuatLagi: true, galatLagi: null);
    try {
      final h = await ref
          .read(beasiswaRepositoryProvider)
          .daftar(q: state.q, jenjang: state.jenjang, kursor: state.kursor);
      state = state.salin(
        items: [...state.items, ...h.items],
        kursor: h.kursorBerikut,
        memuatLagi: false,
      );
    } catch (e) {
      state = state.salin(memuatLagi: false, galatLagi: pesanGalat(e));
    }
  }

  Future<void> cari(String q) {
    state = state.salin(q: q.trim());
    return muat();
  }

  Future<void> pilihJenjang(String? jenjang) {
    state = state.salin(jenjang: jenjang);
    return muat();
  }
}

final jelajahProvider = NotifierProvider<JelajahController, JelajahState>(
  JelajahController.new,
);

final detailBeasiswaProvider = FutureProvider.autoDispose
    .family<BeasiswaDetail, String>(
      (ref, id) => ref.watch(beasiswaRepositoryProvider).detail(id),
    );

final tersimpanProvider = FutureProvider.autoDispose<Set<String>>(
  (ref) => ref.watch(beasiswaRepositoryProvider).idTersimpan(),
);
