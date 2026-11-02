import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/rekomendasi.dart';

final rekomendasiProvider = FutureProvider.autoDispose
    .family<List<Rekomendasi>, Kategori?>(
      (ref, k) => ref.watch(rekomendasiRepositoryProvider).daftar(kategori: k),
    );

final ringkasanRekomendasiProvider =
    FutureProvider.autoDispose<RingkasanRekomendasi>(
      (ref) => ref.watch(rekomendasiRepositoryProvider).ringkasan(),
    );
