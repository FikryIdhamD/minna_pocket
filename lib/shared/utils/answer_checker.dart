// Koreksi jawaban Mondaishuu (docs/06_Algoritma.md §2). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import '../domain/models/jp_text.dart';
import '../domain/models/mondaishuu.dart';
import 'kana_input.dart';

/// Katakana → hiragana.
String toHiragana(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x30A1 && r <= 0x30F6) {
      b.writeCharCode(r - 0x60);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

const _vowelOf = {
  'あ': 'あ', 'か': 'あ', 'さ': 'あ', 'た': 'あ', 'な': 'あ', 'は': 'あ', 'ま': 'あ', 'や': 'あ', 'ら': 'あ', 'わ': 'あ',
  'が': 'あ', 'ざ': 'あ', 'だ': 'あ', 'ば': 'あ', 'ぱ': 'あ', 'ゃ': 'あ', 'ぁ': 'あ',
  'い': 'い', 'き': 'い', 'し': 'い', 'ち': 'い', 'に': 'い', 'ひ': 'い', 'み': 'い', 'り': 'い',
  'ぎ': 'い', 'じ': 'い', 'ぢ': 'い', 'び': 'い', 'ぴ': 'い', 'ぃ': 'い',
  'う': 'う', 'く': 'う', 'す': 'う', 'つ': 'う', 'ぬ': 'う', 'ふ': 'う', 'む': 'う', 'ゆ': 'う', 'る': 'う',
  'ぐ': 'う', 'ず': 'う', 'づ': 'う', 'ぶ': 'う', 'ぷ': 'う', 'ゅ': 'う', 'ぅ': 'う', 'ゔ': 'う',
  'え': 'え', 'け': 'え', 'せ': 'え', 'て': 'え', 'ね': 'え', 'へ': 'え', 'め': 'え', 'れ': 'え',
  'げ': 'え', 'ぜ': 'え', 'で': 'え', 'べ': 'え', 'ぺ': 'え', 'ぇ': 'え',
  'お': 'お', 'こ': 'お', 'そ': 'お', 'と': 'お', 'の': 'お', 'ほ': 'お', 'も': 'お', 'よ': 'お', 'ろ': 'お', 'を': 'お',
  'ご': 'お', 'ぞ': 'お', 'ど': 'お', 'ぼ': 'お', 'ぽ': 'お', 'ょ': 'お', 'ぉ': 'お',
};

/// Normalisasi untuk perbandingan:
/// 1. romaji → hiragana (huruf latin kecil saja; huruf besar seperti "IMC", "CD" dibiarkan)
/// 2. lebar penuh → lebar biasa untuk huruf/angka latin; huruf latin dikecilkan
/// 3. katakana → hiragana; "ー" → vokal huruf sebelumnya
/// 4. hapus spasi dan tanda baca: 。、，．・！？!?…「」『』（）()［］[] 〜～ serta "例:" / "例："
String normalizeAnswer(String raw) {
  var s = raw.trim();
  s = s.replaceAll(RegExp(r'^例\s*[:：]\s*'), '');
  if (RegExp(r'[a-z]').hasMatch(s)) s = romajiToHiraganaFinal(s);
  final b = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0xFF01 && r <= 0xFF5E) {
      b.writeCharCode(r - 0xFEE0);
    } else if (r == 0x3000) {
      b.write(' ');
    } else {
      b.writeCharCode(r);
    }
  }
  s = toHiragana(b.toString()).toLowerCase();
  final out = StringBuffer();
  String? prev;
  for (final ch in s.split('')) {
    if (ch == 'ー') {
      final v = prev == null ? null : _vowelOf[prev];
      if (v != null) {
        out.write(v);
        prev = v;
      }
      continue;
    }
    if (RegExp(r'[\s。、，,．.・！？!?…「」『』（）()［］\[\]〜～~／/:：]').hasMatch(ch)) continue;
    out.write(ch);
    prev = ch;
  }
  return out.toString();
}

/// Semua bentuk jawaban yang diterima: teks asli (kanji) dan bacaannya (kana).
Set<String> acceptedForms(List<JpText> answers) => {
      for (final a in answers) ...[normalizeAnswer(a.jp), normalizeAnswer(a.reading)],
    }..removeWhere((e) => e.isEmpty);

/// Hasil koreksi satu tempat kosong.
enum BlankResult { correct, wrong, ungraded }

BlankResult checkBlank(MsBlank blank, String userAnswer) {
  switch (blank.type) {
    case BlankType.free:
      return BlankResult.ungraded;
    case BlankType.option:
      return userAnswer.trim().toLowerCase() == (blank.answer ?? '').toLowerCase()
          ? BlankResult.correct
          : BlankResult.wrong;
    case BlankType.choice:
    case BlankType.text:
    case BlankType.sentence:
      final u = normalizeAnswer(userAnswer);
      if (u.isEmpty) return BlankResult.wrong;
      return acceptedForms(blank.answersJp).contains(u) ? BlankResult.correct : BlankResult.wrong;
  }
}
