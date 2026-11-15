import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/domain/models/models.dart';

class DeckCard {
  const DeckCard({
    required this.key,
    required this.front,
    this.reading,
    this.romaji,
    this.meaning,
    this.lessons = const [],
  });

  final String key;
  final String front;
  final String? reading;
  final String? romaji;
  final String? meaning;
  final List<int> lessons;
}

List<DeckCard> buildKanaDeck(KanaChart chart, String deckId) {
  final tables = deckId == 'hira' ? chart.hiragana : chart.katakana;
  return [
    for (final t in tables)
      for (final c in t.cells)
        DeckCard(
          key: '$deckId:${c.kana}',
          front: c.kana,
          romaji: c.romaji,
        ),
  ];
}

List<DeckCard> buildKanjiDeck(List<KanjiEntry> entries, int lessonNo) {
  return [
    for (final e in entries)
      if (e.firstLesson == lessonNo) kanjiEntryToDeckCard(e),
  ];
}

DeckCard kanjiEntryToDeckCard(KanjiEntry e) {
  final lessons = e.occurrences.map((o) => o.lesson).toSet().toList()..sort();
  return DeckCard(
    key: 'kanji:${e.word}',
    front: e.word,
    reading: e.readings.join('・'),
    romaji: e.readingsRo.join(' / '),
    meaning: e.meaning,
    lessons: lessons,
  );
}

final deckProvider =
    FutureProvider.family<List<DeckCard>, String>((ref, id) async {
  if (id == 'hira' || id == 'kata') {
    final chart = await ref.watch(kanaChartProvider.future);
    return buildKanaDeck(chart, id);
  }
  if (id.startsWith('kanji-')) {
    final lessonNo = int.tryParse(id.substring(6));
    if (lessonNo == null) return const [];
    final entries = await ref.watch(kanjiIndexProvider.future);
    return buildKanjiDeck(entries, lessonNo);
  }
  return const [];
});
