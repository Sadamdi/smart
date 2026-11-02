import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/notifikasi.dart';

final notifikasiProvider = FutureProvider.autoDispose<List<Notifikasi>>(
  (ref) => ref.watch(notifikasiRepositoryProvider).daftar(),
);
