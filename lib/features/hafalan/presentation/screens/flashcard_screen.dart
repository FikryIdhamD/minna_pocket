import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../services/tts_service/domain/providers/tts_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/srs.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../domain/providers/deck_providers.dart';

String deckTitle(String deck) {
  if (deck == 'hira') return 'Hiragana';
  if (deck == 'kata') return 'Katakana';
  if (deck.startsWith('kanji-')) return 'Kanji Bab ${deck.substring(6)}';
  return 'Kartu';
}

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key, required this.deck});

  final String deck;

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen> {
  List<DeckCard>? _cards;
  int _index = 0;
  bool _flipped = false;
  int _reviewed = 0;

  void _init(List<DeckCard> source) {
    _cards ??= List<DeckCard>.from(source);
  }

  void _shuffle() {
    if (_cards == null) return;
    setState(() {
      _cards = List<DeckCard>.from(_cards!)..shuffle(Random());
      _index = 0;
      _flipped = false;
      _reviewed = 0;
    });
  }

  void _grade(DeckCard card, SrsGrade grade) {
    ref.read(userDataProvider.notifier).srsReview(card.key, grade);
    setState(() {
      _reviewed++;
      _index++;
      _flipped = false;
    });
  }

  void _restart(List<DeckCard> source) {
    setState(() {
      _cards = List<DeckCard>.from(source);
      _index = 0;
      _flipped = false;
      _reviewed = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final deckAsync = ref.watch(deckProvider(widget.deck));
    final title = deckTitle(widget.deck);

    return deckAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const SkeletonList(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ErrorView(
          message: S.loadError,
          onRetry: () => ref.invalidate(deckProvider(widget.deck)),
        ),
      ),
      data: (source) {
        if (source.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(
              child: Text('Tidak ada kartu.', style: AppText.body),
            ),
          );
        }
        _init(source);
        final cards = _cards!;
        final done = _index >= cards.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              if (!done)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: Sp.x2),
                    child: Text(
                      '${_index + 1} / ${cards.length}',
                      style: AppText.bodySm.copyWith(color: p.inkMuted),
                    ),
                  ),
                ),
              IconButton(
                tooltip: S.shuffle,
                onPressed: _shuffle,
                icon: AppIcon(AppIcons.shuffle, color: p.ink),
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
                  child:
                      done ? _doneView(source, p) : _cardView(cards[_index], p),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _doneView(List<DeckCard> source, AppPalette p) {
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
          onPressed: () => _restart(source),
          child: const Text('Ulangi'),
        ),
        const SizedBox(height: Sp.x2),
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Kembali'),
        ),
      ],
    );
  }

  Widget _cardView(DeckCard card, AppPalette p) {
    final isKanji = widget.deck.startsWith('kanji-');
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
                  S.gradeLupa, p.danger, () => _grade(card, SrsGrade.lupa)),
              const SizedBox(width: Sp.x2),
              _gradeBtn(
                  S.gradeSusah, p.ink, () => _grade(card, SrsGrade.susah)),
              const SizedBox(width: Sp.x2),
              _gradeBtn(S.gradeBisa, p.ink, () => _grade(card, SrsGrade.bisa)),
              const SizedBox(width: Sp.x2),
              _gradeBtn(
                  S.gradeMudah, p.success, () => _grade(card, SrsGrade.mudah)),
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
