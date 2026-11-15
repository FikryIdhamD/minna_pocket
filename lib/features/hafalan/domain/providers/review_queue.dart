import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/models.dart';
import '../../../../shared/domain/providers/settings_provider.dart';
import '../../../../shared/utils/srs.dart';
import 'deck_providers.dart';

const _kNewDateKey = 'review.newDate';
const _kNewCountKey = 'review.newCount';

class ReviewQueueItem {
  const ReviewQueueItem({required this.card, required this.isNew});
  final DeckCard card;
  final bool isNew;
}

String _dateStr(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

int readTodayNewCount(SharedPreferences prefs, {DateTime? now}) {
  final todayKey = _dateStr(now ?? DateTime.now());
  if (prefs.getString(_kNewDateKey) != todayKey) return 0;
  return prefs.getInt(_kNewCountKey) ?? 0;
}

Future<void> recordNewCardIntroduced(SharedPreferences prefs,
    {DateTime? now}) async {
  final todayKey = _dateStr(now ?? DateTime.now());
  final prev = prefs.getString(_kNewDateKey) == todayKey
      ? (prefs.getInt(_kNewCountKey) ?? 0)
      : 0;
  await prefs.setString(_kNewDateKey, todayKey);
  await prefs.setInt(_kNewCountKey, prev + 1);
}

List<ReviewQueueItem> buildReviewQueue({
  required Map<String, SrsCard> srs,
  required KanaChart kanaChart,
  required List<KanjiEntry> kanjiEntries,
  required int newCardsPerDay,
  required int introducedToday,
}) {
  final allCards = <DeckCard>[
    ...buildKanaDeck(kanaChart, 'hira'),
    ...buildKanaDeck(kanaChart, 'kata'),
    for (var n = 1; n <= 25; n++) ...buildKanjiDeck(kanjiEntries, n),
  ];
  final byKey = {for (final c in allCards) c.key: c};

  final dueEntries = srs.entries.where((e) => isDue(e.value)).toList()
    ..sort((a, b) {
      final cmp = a.value.due.compareTo(b.value.due);
      return cmp != 0 ? cmp : a.key.compareTo(b.key);
    });

  final queue = <ReviewQueueItem>[
    for (final e in dueEntries)
      if (byKey[e.key] != null)
        ReviewQueueItem(card: byKey[e.key]!, isNew: false),
  ];

  final remainingNew =
      (newCardsPerDay - introducedToday).clamp(0, newCardsPerDay);
  if (remainingNew > 0) {
    var added = 0;
    for (final c in allCards) {
      if (added >= remainingNew) break;
      if (!srs.containsKey(c.key)) {
        queue.add(ReviewQueueItem(card: c, isNew: true));
        added++;
      }
    }
  }

  return queue;
}

final reviewQueueProvider = FutureProvider<List<ReviewQueueItem>>((ref) async {
  final srs = ref.watch(userDataProvider.select((u) => u.srs));
  final newPerDay = ref.watch(settingsProvider.select((s) => s.newCardsPerDay));
  final prefs = ref.watch(sharedPreferencesProvider);
  final chart = await ref.watch(kanaChartProvider.future);
  final kanji = await ref.watch(kanjiIndexProvider.future);

  return buildReviewQueue(
    srs: srs,
    kanaChart: chart,
    kanjiEntries: kanji,
    newCardsPerDay: newPerDay,
    introducedToday: readTodayNewCount(prefs),
  );
});

final reviewQueueCountProvider = Provider<int>(
  (ref) => ref.watch(reviewQueueProvider).valueOrNull?.length ?? 0,
);
