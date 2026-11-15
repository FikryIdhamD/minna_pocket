import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/models.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/srs.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../domain/providers/deck_providers.dart';
import '../../domain/providers/review_queue.dart';

class HafalanHubScreen extends ConsumerWidget {
  const HafalanHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final dueCount = ref.watch(reviewQueueCountProvider);
    final hiraDeck = ref.watch(deckProvider('hira')).valueOrNull ?? const [];
    final kataDeck = ref.watch(deckProvider('kata')).valueOrNull ?? const [];
    final kanjiAsync = ref.watch(kanjiIndexProvider);
    final srs = ref.watch(userDataProvider.select((u) => u.srs));

    int masteredCount(Iterable<String> keys) =>
        keys.where((k) => srs[k] != null && isMastered(srs[k]!)).length;

    final hiraMastered = masteredCount(hiraDeck.map((c) => c.key));
    final kataMastered = masteredCount(kataDeck.map((c) => c.key));

    return Scaffold(
      appBar: AppBar(title: const Text('Hafalan')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(Sp.screen),
              children: [
                _reviewCard(context, dueCount, p),
                const SizedBox(height: Sp.x4),
                _kanaCard(
                  context,
                  title: 'Hiragana',
                  script: 'hira',
                  mastered: hiraMastered,
                  total: hiraDeck.length,
                  p: p,
                ),
                const SizedBox(height: Sp.x3),
                _kanaCard(
                  context,
                  title: 'Katakana',
                  script: 'kata',
                  mastered: kataMastered,
                  total: kataDeck.length,
                  p: p,
                ),
                const SizedBox(height: Sp.x5),
                Text(
                  'KANJI PER BAB',
                  style: AppText.overline.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Sp.x2),
                kanjiAsync.when(
                  loading: () => const SizedBox(
                    height: 240,
                    child: SkeletonList(),
                  ),
                  error: (e, _) => ErrorView(
                    message: S.loadError,
                    onRetry: () => ref.invalidate(kanjiIndexProvider),
                  ),
                  data: (entries) {
                    final byLesson = <int, List<KanjiEntry>>{};
                    for (final e in entries) {
                      byLesson.putIfAbsent(e.firstLesson, () => []).add(e);
                    }
                    final lessons = byLesson.keys.toList()..sort();
                    return Container(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: Radii.lgAll,
                        border: Border.all(color: p.border),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < lessons.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, thickness: 1, color: p.border),
                            _kanjiRow(
                              context,
                              lessons[i],
                              byLesson[lessons[i]]!,
                              srs,
                              p,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: Sp.x6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewCard(BuildContext context, int dueCount, AppPalette p) {
    return Container(
      padding: const EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '$dueCount',
                style: AppText.brushNo.copyWith(
                  color: dueCount > 0 ? p.primary : p.inkMuted,
                ),
              ),
              const SizedBox(width: Sp.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(S.reviewToday, style: AppText.headline),
                    if (dueCount == 0)
                      Text(
                        'Tidak ada kartu jatuh tempo.',
                        style: AppText.bodySm.copyWith(color: p.inkMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (dueCount > 0) ...[
            const SizedBox(height: Sp.x3),
            FilledButton(
              onPressed: () => context.push('/review'),
              child: const Text('Mulai ulasan'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kanaCard(
    BuildContext context, {
    required String title,
    required String script,
    required int mastered,
    required int total,
    required AppPalette p,
  }) {
    return Container(
      padding: const EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AppText.headline)),
              Text(
                '$mastered / $total hafal',
                style: AppText.bodySm.copyWith(color: p.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: Sp.x3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/kana/$script'),
                  child: const Text('Tabel'),
                ),
              ),
              const SizedBox(width: Sp.x2),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/cards/$script'),
                  child: const Text('Kartu'),
                ),
              ),
              const SizedBox(width: Sp.x2),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/quiz/$script'),
                  child: const Text('Kuis'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kanjiRow(
    BuildContext context,
    int lesson,
    List<KanjiEntry> list,
    Map<String, SrsCard> srs,
    AppPalette p,
  ) {
    final mastered = list.where((e) {
      final c = srs['kanji:${e.word}'];
      return c != null && isMastered(c);
    }).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bab $lesson', style: AppText.bodyStrong),
                Text(
                  '${list.length} kata · $mastered hafal',
                  style: AppText.bodySm.copyWith(color: p.inkMuted),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/cards/kanji-$lesson'),
            child: const Text('Kartu'),
          ),
          TextButton(
            onPressed: () => context.push('/quiz/kanji-$lesson'),
            child: const Text('Kuis'),
          ),
        ],
      ),
    );
  }
}
