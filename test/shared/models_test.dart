// Tes parsing data asli (assets/book1). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minna_pocket/shared/domain/models/models.dart';

dynamic readAsset(String p) => jsonDecode(File('assets/book1/$p').readAsStringSync());

void main() {
  test('manifest dapat dibaca', () {
    final m = BookManifest.fromJson(readAsset('manifest.json') as JsonMap);
    expect(m.book, 1);
    expect(m.lessons, isNotEmpty);
    expect(m.lesson(1)!.section('kaiwa'), isNotNull);
  });

  test('semua bab di manifest dapat dibaca', () {
    final m = BookManifest.fromJson(readAsset('manifest.json') as JsonMap);
    for (final lm in m.lessons) {
      final l = Lesson.fromJson(readAsset(lm.file) as JsonMap);
      expect(l.lesson, lm.lesson);
      expect(l.sections.kaiwa!.lines.every((x) => x.t != null), isTrue);
      for (final md in l.sections.mondai) {
        if (md.kind.isListening) {
          expect(md.segments.length, md.examples.length + md.questions.length, reason: md.id);
        }
      }
    }
  });

  test('Bab 1: isi kunci', () {
    final l = Lesson.fromJson(readAsset('lessons/L01.json') as JsonMap);
    expect(l.titleJp.jp, '初めまして');
    expect(l.sections.bunkei.first.jp.romaji, 'Watashi wa maiku miraa desu.');
    final kanji = l.sections.kaiwa!.lines[5].jp.tokens.firstWhere((t) => t.k);
    expect(kanji.s, '来');
    expect(kanji.r, 'き');
    expect(l.sections.renshuuB!.figureOf(l.sections.renshuuB!.items.first), isNotNull);
    expect(l.sections.mondai[3].questions.first.blankCount, 1);
  });

  test('semua Mondaishuu dapat dibaca & blank konsisten', () {
    final m = BookManifest.fromJson(readAsset('manifest.json') as JsonMap);
    for (final mm in [...m.mondaishuu, ...m.fukushuu]) {
      final s = MondaishuuSet.fromJson(readAsset(mm.file) as JsonMap);
      for (final ex in s.exercises) {
        for (final it in ex.items) {
          final blanks = it.linesJp.fold<int>(0, (n, l) => n + l.tokens.where((t) => t.blank).length);
          expect(blanks, it.blanks.length, reason: it.id);
        }
      }
    }
  });

  test('urutan buku: setiap 復習/まとめ punya set, setiap bab ada', () {
    final m = BookManifest.fromJson(readAsset('manifest.json') as JsonMap);
    expect(m.fukushuu, isNotEmpty);
    for (final it in m.sequence) {
      if (it.type == 'lesson') {
        expect(m.lesson(it.lesson!), isNotNull, reason: 'bab ${it.lesson}');
      } else {
        expect(m.setMeta(it.id!), isNotNull, reason: it.id);
        expect(it.titleJp, isNotNull, reason: it.id);
      }
    }
  });

  test('indeks & kana dapat dibaca', () {
    expect(parseList(readAsset('kanji_index.json'), KanjiEntry.fromJson), isNotEmpty);
    expect(parseList(readAsset('search_index.json'), SearchEntry.fromJson), isNotEmpty);
    final k = KanaChart.fromJson(readAsset('extras/kana.json') as JsonMap);
    expect(k.hiragana.first.cells.first.kana, 'あ');
    expect(ExtraDoc.fromJson(readAsset('extras/howto.json') as JsonMap).sections, isNotEmpty);
    expect(ExtraDoc.fromJson(readAsset('extras/intro.json') as JsonMap).sections, isNotEmpty);
  });

  test('UserData bolak-balik JSON', () {
    final u = const UserData().copyWith(done: {'L01.kaiwa'}, answers: {'x#0': 'あ'});
    final back = UserData.fromJson(jsonDecode(jsonEncode(u.toJson())) as JsonMap);
    expect(back.done, contains('L01.kaiwa'));
    expect(back.answers['x#0'], 'あ');
  });
}
