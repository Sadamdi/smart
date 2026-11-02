import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/kalender.dart';

/// Acara dari awal bulan ini sampai 120 hari ke depan.
final kalenderProvider = FutureProvider.autoDispose<List<Acara>>((ref) {
  final n = DateTime.now();
  return ref
      .watch(kalenderRepositoryProvider)
      .acara(
        dari: DateTime(n.year, n.month, 1),
        sampai: DateTime(n.year, n.month, n.day).add(const Duration(days: 120)),
      );
});

final checklistProvider = FutureProvider.autoDispose<List<ChecklistBeasiswa>>(
  (ref) => ref.watch(kalenderRepositoryProvider).checklist(),
);
