// Tes utilitas. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:minna_pocket/shared/domain/models/models.dart';
import 'package:minna_pocket/shared/utils/answer_checker.dart';
import 'package:minna_pocket/shared/utils/kana_input.dart';
import 'package:minna_pocket/shared/utils/srs.dart';

void main() {
  group('romajiToHiragana', () {
    test('dasar', () {
      expect(romajiToHiragana('watashi'), 'わたし');
      expect(romajiToHiragana('gakusei desu'), 'がくせい です');
      expect(romajiToHiragana('kitte'), 'きって');
      expect(romajiToHiragana('konnichiha'), 'こんにちは');
      expect(romajiToHiragana('shinbun'), 'しんぶn');
      expect(romajiToHiraganaFinal('shinbun'), 'しんぶん');
      expect(romajiToHiragana("kon'ya"), 'こんや');
      expect(romajiToHiragana('konpyu-ta-'), 'こんぴゅーたー');
    });
  });

  group('normalizeAnswer', () {
    test('kana/katakana/ー/tanda baca', () {
      expect(normalizeAnswer('コンピューター'), normalizeAnswer('konpyuutaa'));
      expect(normalizeAnswer('学生です。'), '学生です');
      expect(normalizeAnswer('例：マイク・ミラーです。'), 'まいくみらあです');
      expect(normalizeAnswer(' も '), 'も');
    });
  });

  test('checkBlank memakai data MS01', () {
    final s = MondaishuuSet.fromJson(jsonDecode(File('assets/book1/mondaishuu/MS01.json').readAsStringSync()) as JsonMap);
    final ex1 = s.exercises.first;
    expect(checkBlank(ex1.items[0].blanks[0], '時計'), BlankResult.correct);
    expect(checkBlank(ex1.items[0].blanks[0], 'とけい'), BlankResult.correct);
    expect(checkBlank(ex1.items[0].blanks[0], 'tokei'), BlankResult.correct);
    expect(checkBlank(ex1.items[0].blanks[0], 'かさ'), BlankResult.wrong);
    final ex4 = s.exercises[3];
    expect(checkBlank(ex4.items[2].blanks[0], 'だれですか'), BlankResult.correct);
    final ex5 = s.exercises[4];
    expect(checkBlank(ex5.items[0].blanks[0], 'f'), BlankResult.correct);
    final ex8 = s.exercises[7];
    expect(checkBlank(ex8.items[1].blanks[0], 'apa saja'), BlankResult.ungraded);
  });

  test('SRS', () {
    var c = newCard();
    c = review(c, SrsGrade.bisa);
    expect(c.interval, 1);
    c = review(c, SrsGrade.bisa);
    expect(c.interval, 3);
    c = review(c, SrsGrade.lupa);
    expect(c.reps, 0);
    expect(isDue(c), isTrue);
  });
}
