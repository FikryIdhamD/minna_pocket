import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import 'deck_providers.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.card,
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });

  final DeckCard card;
  final String prompt;
  final String correctAnswer;
  final List<String> options;
}

String _answerForCard(DeckCard card, bool isKanji) {
  if (!isKanji) return card.romaji ?? '';
  final r = card.reading ?? '';
  if (r.isEmpty) return '';
  return r.split('・').first;
}

List<QuizQuestion> buildQuiz(
  List<DeckCard> deck, {
  required bool isKanji,
  List<DeckCard> fallbackCards = const [],
  Random? random,
}) {
  if (deck.isEmpty) return const [];
  final rng = random ?? Random();
  final count = min(10, deck.length);
  final picked = List<DeckCard>.from(deck)..shuffle(rng);
  final selected = picked.take(count);

  final questions = <QuizQuestion>[];
  for (final card in selected) {
    final correct = _answerForCard(card, isKanji);
    if (correct.isEmpty) continue;

    final distractors = <String>[];
    final seen = <String>{correct};

    final sameDeckPool = List<DeckCard>.from(deck)..shuffle(rng);
    for (final other in sameDeckPool) {
      if (distractors.length >= 3) break;
      if (other.key == card.key) continue;
      final cand = _answerForCard(other, isKanji);
      if (cand.isNotEmpty && seen.add(cand)) {
        distractors.add(cand);
      }
    }

    if (isKanji && distractors.length < 3 && fallbackCards.isNotEmpty) {
      final fbPool = List<DeckCard>.from(fallbackCards)..shuffle(rng);
      for (final other in fbPool) {
        if (distractors.length >= 3) break;
        if (other.key == card.key) continue;
        final cand = _answerForCard(other, true);
        if (cand.isNotEmpty && seen.add(cand)) {
          distractors.add(cand);
        }
      }
    }

    final options = [correct, ...distractors]..shuffle(rng);
    if (options.length < 2) continue;

    questions.add(QuizQuestion(
      card: card,
      prompt: card.front,
      correctAnswer: correct,
      options: options,
    ));
  }
  return questions;
}

final quizProvider = FutureProvider.autoDispose
    .family<List<QuizQuestion>, String>((ref, deckId) async {
  final deck = await ref.watch(deckProvider(deckId).future);
  final isKanji = deckId.startsWith('kanji-');
  var fallback = const <DeckCard>[];
  if (isKanji && deck.length < 4) {
    final lessonNo = int.tryParse(deckId.substring(6)) ?? 1;
    final entries = await ref.watch(kanjiIndexProvider.future);
    fallback = [
      for (var prev = lessonNo - 1; prev >= 1; prev--)
        ...buildKanjiDeck(entries, prev),
    ];
  }
  return buildQuiz(deck, isKanji: isKanji, fallbackCards: fallback);
});
