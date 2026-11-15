// Perhitungan progres dari manifest + data pengguna (docs/06_Algoritma.md §4).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/models/models.dart';
import '../../../content_service/domain/providers/content_providers.dart';
import 'user_data_provider.dart';

/// Ref yang harus selesai agar satu bagian dianggap selesai.
/// - Bagian dengan pemilih nomor: satu ref per nomor, mis. "L01.renshuu_b.1" … "L01.renshuu_b.7".
/// - Bagian lain: satu ref, mis. "L01.kaiwa".
List<String> sectionUnitRefs(LessonMeta l, SectionMeta s) => s.hasPicker
    ? [for (final n in s.numbers) '${l.id}.${s.key}.$n']
    : ['${l.id}.${s.key}'];

bool isSectionDone(Set<String> done, LessonMeta l, SectionMeta s) => sectionUnitRefs(l, s).every(done.contains);

/// Pecahan nomor yang selesai di satu bagian (0..1) — untuk teks "3/7 nomor".
double sectionFraction(Set<String> done, LessonMeta l, SectionMeta s) {
  final refs = sectionUnitRefs(l, s);
  return refs.isEmpty ? 0 : refs.where(done.contains).length / refs.length;
}

class LessonProgress {
  const LessonProgress({required this.sectionsDone, required this.sectionsTotal});
  final int sectionsDone;
  final int sectionsTotal;
  double get fraction => sectionsTotal == 0 ? 0 : sectionsDone / sectionsTotal;
  bool get started => sectionsDone > 0;
}

LessonProgress lessonProgressOf(Set<String> done, LessonMeta l) => LessonProgress(
      sectionsDone: l.sections.where((s) => isSectionDone(done, l, s)).length,
      sectionsTotal: l.sections.length,
    );

/// Progres satu bab. Null selama manifest belum dimuat.
final lessonProgressProvider = Provider.family<LessonProgress?, int>((ref, no) {
  final manifest = ref.watch(manifestProvider).valueOrNull;
  final done = ref.watch(userDataProvider.select((u) => u.done));
  final l = manifest?.lesson(no);
  return l == null ? null : lessonProgressOf(done, l);
});

class OverallProgress {
  const OverallProgress({required this.fraction, required this.lessonsStarted, required this.lessonsTotal});
  final double fraction; // rata-rata pecahan semua bab
  final int lessonsStarted;
  final int lessonsTotal;
}

final overallProgressProvider = Provider<OverallProgress?>((ref) {
  final manifest = ref.watch(manifestProvider).valueOrNull;
  if (manifest == null) return null;
  final done = ref.watch(userDataProvider.select((u) => u.done));
  final ps = manifest.lessons.map((l) => lessonProgressOf(done, l)).toList();
  final total = manifest.lessons.length;
  return OverallProgress(
    fraction: total == 0 ? 0 : ps.fold<double>(0, (a, p) => a + p.fraction) / total,
    lessonsStarted: ps.where((p) => p.started).length,
    lessonsTotal: total,
  );
});
