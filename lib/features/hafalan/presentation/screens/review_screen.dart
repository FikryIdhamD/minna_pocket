import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../services/tts_service/domain/providers/tts_service.dart';
import '../../../../shared/domain/providers/settings_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/srs.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../domain/providers/deck_providers.dart';
import '../../domain/providers/review_queue.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<ReviewQueueItem>? _queue;
  int _index = 0;
  bool _flipped = false;
  int _reviewed = 0;

  void _init(List<ReviewQueueItem> source) {
    _queue ??= List<ReviewQueueItem>.from(source);
  }

  Future<void> _grade(ReviewQueueItem item, SrsGrade grade) async {
    if (item.isNew) {
      await recordNewCardIntroduced(ref.read(sharedPreferencesProvider));
    }
    ref.read(userDataProvider.notifier).srsReview(item.card.key, grade);
    if (!mounted) return;
    setState(() {
      if (grade == SrsGrade.lupa) {
        _queue!.add(ReviewQueueItem(card: item.card, isNew: false));
      }
      _reviewed++;
      _index++;
      _flipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final queueAsync = ref.watch(reviewQueueProvider);

    return queueAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text(S.reviewToday)),
        body: const SkeletonList(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text(S.reviewToday)),
        body: ErrorView(
          message: S.loadError,
          onRetry: () => ref.invalidate(reviewQueueProvider),
        ),
      ),
      data: (source) {
        _init(source);
        final queue = _queue!;
        if (queue.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text(S.reviewToday)),
            body: SafeArea(
              top: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(Sp.screen),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppIcon(AppIcons.checkCircle, size: 48, color: p.success),
                      const SizedBox(height: Sp.x3),
                      Text(
                        'Semua kartu sudah diulas hari ini.',
                        textAlign: TextAlign.center,
                        style: AppText.title,
                      ),
                      const SizedBox(height: Sp.x5),
                      FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Kembali'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final done = _index >= queue.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text(S.reviewToday),
            actions: [
              if (!done)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: Sp.screen),
                    child: Text(
                      '${_index + 1} / ${queue.length}',
                      style: AppText.bodySm.copyWith(color: p.inkMuted),
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.all(Sp.screen),
                  child: done ? _doneView(p) : _cardView(queue[_index], p),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _doneView(AppPalette p) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppIcon(AppIcons.checkCircle, size: 48, color: p.success),
        const SizedBox(height: Sp.x3),
        Text(
          'Selesai! $_reviewed kartu diulas.',
          textAlign: TextAlign.center,
          style: AppText.title,
        ),
        const SizedBox(height: Sp.x5),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Kembali'),
        ),
      ],
    );
  }

  Widget _cardView(ReviewQueueItem item, AppPalette p) {
    final card = item.card;
    final isKanji = card.key.startsWith('kanji:');
    final cardHeight = MediaQuery.sizeOf(context).height * 0.48;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Material(
          color: p.surface,
          borderRadius: Radii.lgAll,
          child: InkWell(
            borderRadius: Radii.lgAll,
            onTap: () => setState(() => _flipped = !_flipped),
            child: Container(
              height: cardHeight,
              padding: const EdgeInsets.all(Sp.x5),
              decoration: BoxDecoration(
                borderRadius: Radii.lgAll,
                border: Border.all(color: p.border),
              ),
              child: _flipped ? _back(card, isKanji, p) : _front(card, p),
            ),
          ),
        ),
        const SizedBox(height: Sp.x4),
        if (_flipped)
          Row(
            children: [
              _gradeBtn(
                  S.gradeLupa, p.danger, () => _grade(item, SrsGrade.lupa)),
              const SizedBox(width: Sp.x2),
              _gradeBtn(
                  S.gradeSusah, p.ink, () => _grade(item, SrsGrade.susah)),
              const SizedBox(width: Sp.x2),
              _gradeBtn(S.gradeBisa, p.ink, () => _grade(item, SrsGrade.bisa)),
              const SizedBox(width: Sp.x2),
              _gradeBtn(
                  S.gradeMudah, p.success, () => _grade(item, SrsGrade.mudah)),
            ],
          )
        else
          SizedBox(
            height: 48,
            child: Center(
              child: Text(
                'Ketuk kartu untuk melihat jawaban',
                style: AppText.bodySm.copyWith(color: p.inkMuted),
              ),
            ),
          ),
        const Spacer(),
      ],
    );
  }

  Widget _front(DeckCard card, AppPalette p) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          card.front,
          style: AppText.brushCard.copyWith(color: p.ink),
        ),
      ),
    );
  }

  Widget _back(DeckCard card, bool isKanji, AppPalette p) {
    final ttsText =
        isKanji ? (card.reading?.split('・').first ?? card.front) : card.front;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isKanji) ...[
          Text(card.romaji ?? '', style: AppText.title),
          const SizedBox(height: Sp.x3),
          IconButton.filledTonal(
            tooltip: S.speak,
            style: IconButton.styleFrom(backgroundColor: p.primarySubtle),
            onPressed: () => ref.read(ttsServiceProvider).speak(ttsText),
            icon: AppIcon(AppIcons.speaker, color: p.primary),
          ),
        ] else ...[
          Text(
            card.reading ?? '',
            textAlign: TextAlign.center,
            style: AppText.jpTitle(1).copyWith(color: p.ink),
          ),
          const SizedBox(height: Sp.x1),
          Text(
            card.romaji ?? '',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Sp.x3),
          Text(
            card.meaning ?? '—',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: p.secondary),
          ),
          if (card.lessons.isNotEmpty) ...[
            const SizedBox(height: Sp.x3),
            Text(
              'Muncul di: Bab ${card.lessons.join(', ')}',
              style: AppText.caption.copyWith(color: p.inkMuted),
            ),
          ],
          const SizedBox(height: Sp.x3),
          IconButton.filledTonal(
            tooltip: S.speak,
            style: IconButton.styleFrom(backgroundColor: p.primarySubtle),
            onPressed: () => ref.read(ttsServiceProvider).speak(ttsText),
            icon: AppIcon(AppIcons.speaker, color: p.primary),
          ),
        ],
      ],
    );
  }

  Widget _gradeBtn(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: Sp.x3),
        ),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
