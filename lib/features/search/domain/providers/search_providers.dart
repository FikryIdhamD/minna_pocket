import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/domain/models/models.dart';
import '../../../../shared/utils/answer_checker.dart';
import '../../../../shared/utils/kana_input.dart';

final _punct = RegExp(r'[\s。、，,．.・！？!?…「」『』（）()［］\[\]〜～~／/:：]');

const _typeOrder = {
  'kosakata': 0,
  'kalimat': 1,
  'tata_bahasa': 2,
  'referensi': 3,
};

int? _scoreEntry(
  SearchEntry e, {
  required bool isLatin,
  required String qRo,
  required String qKana,
  required String qTr,
  required String qJp,
}) {
  final ro2 = e.ro.replaceAll(RegExp(r'\s+'), '');
  final kana2 = e.kana.replaceAll(_punct, '');
  final jp2 = toHiragana(e.jp).replaceAll(RegExp(r'\s+'), '');

  if (isLatin) {
    if ((qRo.isNotEmpty && ro2 == qRo) ||
        (qKana.isNotEmpty && kana2 == qKana)) {
      return 0;
    }
    if ((qRo.isNotEmpty && ro2.startsWith(qRo)) ||
        (qKana.isNotEmpty && kana2.startsWith(qKana))) {
      return 1;
    }
    if ((qRo.isNotEmpty && ro2.contains(qRo)) ||
        (qKana.isNotEmpty && kana2.contains(qKana))) {
      return 2;
    }
    final trLow = e.tr.toLowerCase();
    if (qTr.isNotEmpty && RegExp(r'\b' + RegExp.escape(qTr)).hasMatch(trLow)) {
      return 3;
    }
    if (qTr.isNotEmpty && trLow.contains(qTr)) {
      return 4;
    }
    return null;
  }

  if (qJp.isNotEmpty && (jp2 == qJp || kana2 == qJp)) return 0;
  if (qJp.isNotEmpty && (jp2.startsWith(qJp) || kana2.startsWith(qJp))) {
    return 1;
  }
  if (qJp.isNotEmpty && (jp2.contains(qJp) || kana2.contains(qJp))) return 2;
  return null;
}

List<SearchEntry> filterSearchEntries(List<SearchEntry> entries, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final isLatin = RegExp(r'[a-z]').hasMatch(q);
  final qRo = isLatin ? q.replaceAll(RegExp(r'\s+'), '') : '';
  final qKana = isLatin
      ? toHiragana(romajiToHiraganaFinal(q)).replaceAll(RegExp(r'\s+'), '')
      : '';
  final qTr = isLatin ? q : '';
  final qJp = isLatin ? '' : toHiragana(q).replaceAll(RegExp(r'\s+'), '');

  final scored = <(int score, SearchEntry entry)>[];
  for (final e in entries) {
    final sc = _scoreEntry(
      e,
      isLatin: isLatin,
      qRo: qRo,
      qKana: qKana,
      qTr: qTr,
      qJp: qJp,
    );
    if (sc != null) scored.add((sc, e));
  }

  scored.sort((a, b) {
    final cScore = a.$1.compareTo(b.$1);
    if (cScore != 0) return cScore;
    final ta = _typeOrder[a.$2.type] ?? 9;
    final tb = _typeOrder[b.$2.type] ?? 9;
    final cType = ta.compareTo(tb);
    if (cType != 0) return cType;
    return a.$2.lesson.compareTo(b.$2.lesson);
  });

  return scored.take(60).map((e) => e.$2).toList(growable: false);
}

final searchResultsProvider =
    FutureProvider.family<List<SearchEntry>, String>((ref, query) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final entries = await ref.watch(searchIndexProvider.future);
  return filterSearchEntries(entries, q);
});
