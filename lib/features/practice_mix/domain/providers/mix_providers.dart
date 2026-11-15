import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/models.dart';

class MixConfig {
  const MixConfig({
    required this.from,
    required this.to,
    required this.useMs,
    required this.useVocab,
    this.count,
    this.focusWeak = false,
  });

  final int from;
  final int to;
  final bool useMs;
  final bool useVocab;
  final int? count; // null = semua
  final bool focusWeak;
}

sealed class MixQuestion {
  const MixQuestion();
  int get lesson;
}

class MixMsQuestion extends MixQuestion {
  const MixMsQuestion({
    required this.set,
    required this.exercise,
    required this.item,
    required this.lesson,
  });

  final MondaishuuSet set;
  final MsExercise exercise;
  final MsItem item;
  @override
  final int lesson;
}

class MixVocabQuestion extends MixQuestion {
  const MixVocabQuestion({
    required this.item,
    required this.options,
    required this.lesson,
  });

  final KosakataItem item;
  final List<String> options;
  @override
  final int lesson;
}

class MixConfigNotifier extends Notifier<MixConfig?> {
  @override
  MixConfig? build() => null;

  void setConfig(MixConfig cfg) => state = cfg;
}

final mixConfigProvider =
    NotifierProvider<MixConfigNotifier, MixConfig?>(MixConfigNotifier.new);

List<MixQuestion> _weightedPick(
  List<(MixQuestion q, int weight)> pool,
  int? count,
  Random rng,
) {
  final remaining = List<(MixQuestion q, int weight)>.from(pool);
  final target =
      count == null ? remaining.length : min(count, remaining.length);
  final picked = <MixQuestion>[];

  for (var i = 0; i < target; i++) {
    final totalW = remaining.fold<int>(0, (s, e) => s + e.$2);
    if (totalW <= 0) break;
    var r = rng.nextInt(totalW);
    var idx = 0;
    for (; idx < remaining.length - 1; idx++) {
      r -= remaining[idx].$2;
      if (r < 0) break;
    }
    picked.add(remaining.removeAt(idx).$1);
  }
  picked.shuffle(rng);
  return picked;
}

final mixQuestionsProvider = FutureProvider<List<MixQuestion>>((ref) async {
  final cfg = ref.watch(mixConfigProvider);
  if (cfg == null) return const [];

  final manifest = await ref.watch(manifestProvider.future);
  final ud = ref.read(userDataProvider);
  final rng = Random();
  final pool = <(MixQuestion, int)>[];

  if (cfg.useMs) {
    final matchingSets = manifest.mondaishuu.where(
      (m) => m.lessons.any((l) => l >= cfg.from && l <= cfg.to),
    );
    for (final meta in matchingSets) {
      final set = await ref.watch(mondaishuuProvider(meta.id).future);
      final baseLesson = set.lessons.isNotEmpty ? set.lessons.first : cfg.from;
      for (final ex in set.exercises) {
        final score = ud.msScores[ex.id];
        for (final it in ex.items) {
          if (!it.autoGraded) continue;
          var w = 1;
          if (cfg.focusWeak) {
            final st = score?.items[it.id];
            if (st == ItemStatus.wrong || st == ItemStatus.assisted) {
              w = 3;
            }
          }
          pool.add((
            MixMsQuestion(
              set: set,
              exercise: ex,
              item: it,
              lesson: baseLesson,
            ),
            w,
          ));
        }
      }
    }
  }

  if (cfg.useVocab) {
    final vocabEntries = <(int lesson, KosakataItem item)>[];
    for (var l = cfg.from; l <= cfg.to; l++) {
      if (manifest.lesson(l) == null) continue;
      final lesson = await ref.watch(lessonProvider(l).future);
      final k = lesson.sections.kosakata;
      if (k == null) continue;
      for (final it in k.allItems) {
        if (it.tr.toLowerCase().contains('fiksi')) continue;
        vocabEntries.add((l, it));
      }
    }

    final allTr = vocabEntries.map((e) => e.$2.tr).toSet().toList();
    for (final (l, it) in vocabEntries) {
      final distractors = <String>[];
      final seen = <String>{it.tr};
      final shuffledTr = List<String>.from(allTr)..shuffle(rng);
      for (final tr in shuffledTr) {
        if (distractors.length >= 3) break;
        if (seen.add(tr)) distractors.add(tr);
      }
      final options = [it.tr, ...distractors]..shuffle(rng);
      if (options.length < 2) continue;

      var w = 1;
      if (cfg.focusWeak && it.kanjiJp != null) {
        final card = ud.srs['kanji:${it.kanjiJp!.jp}'];
        if (card != null && card.lapses >= 1) {
          w = 3;
        }
      }
      pool.add((
        MixVocabQuestion(item: it, options: options, lesson: l),
        w,
      ));
    }
  }

  return _weightedPick(pool, cfg.count, rng);
});
