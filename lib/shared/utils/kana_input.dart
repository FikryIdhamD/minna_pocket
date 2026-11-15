// Konversi ketikan romaji → hiragana untuk kotak jawaban (docs/06_Algoritma.md §3).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
//
// Aturan:
// - Hanya huruf latin kecil a-z, '-' dan "'" yang dikonversi; huruf Jepang dibiarkan.
// - "nn" → ん ("nn"+vokal → ん + な行); "n" di akhir kata / sebelum konsonan (selain y) → ん; "n'" → ん.
// - Konsonan ganda (kk, tt, ss, pp, ...) → っ + konsonan.
// - "-" → ー.
// - Huruf yang belum lengkap (mis. "k") dibiarkan apa adanya sampai lengkap.

const Map<String, String> _table = {
  'kya': 'きゃ', 'kyu': 'きゅ', 'kyo': 'きょ', 'sha': 'しゃ', 'shu': 'しゅ', 'sho': 'しょ', 'she': 'しぇ',
  'sya': 'しゃ', 'syu': 'しゅ', 'syo': 'しょ', 'cha': 'ちゃ', 'chu': 'ちゅ', 'cho': 'ちょ', 'che': 'ちぇ',
  'tya': 'ちゃ', 'tyu': 'ちゅ', 'tyo': 'ちょ', 'nya': 'にゃ', 'nyu': 'にゅ', 'nyo': 'にょ',
  'hya': 'ひゃ', 'hyu': 'ひゅ', 'hyo': 'ひょ', 'mya': 'みゃ', 'myu': 'みゅ', 'myo': 'みょ',
  'rya': 'りゃ', 'ryu': 'りゅ', 'ryo': 'りょ', 'gya': 'ぎゃ', 'gyu': 'ぎゅ', 'gyo': 'ぎょ',
  'ja': 'じゃ', 'ju': 'じゅ', 'jo': 'じょ', 'je': 'じぇ', 'jya': 'じゃ', 'jyu': 'じゅ', 'jyo': 'じょ',
  'zya': 'じゃ', 'zyu': 'じゅ', 'zyo': 'じょ', 'bya': 'びゃ', 'byu': 'びゅ', 'byo': 'びょ',
  'pya': 'ぴゃ', 'pyu': 'ぴゅ', 'pyo': 'ぴょ', 'dya': 'ぢゃ', 'dyu': 'ぢゅ', 'dyo': 'ぢょ',
  'shi': 'し', 'chi': 'ち', 'tsu': 'つ', 'thi': 'てぃ', 'dhi': 'でぃ', 'fa': 'ふぁ', 'fi': 'ふぃ', 'fe': 'ふぇ', 'fo': 'ふぉ',
  'ka': 'か', 'ki': 'き', 'ku': 'く', 'ke': 'け', 'ko': 'こ', 'sa': 'さ', 'si': 'し', 'su': 'す', 'se': 'せ', 'so': 'そ',
  'ta': 'た', 'ti': 'ち', 'tu': 'つ', 'te': 'て', 'to': 'と', 'na': 'な', 'ni': 'に', 'nu': 'ぬ', 'ne': 'ね', 'no': 'の',
  'ha': 'は', 'hi': 'ひ', 'hu': 'ふ', 'fu': 'ふ', 'he': 'へ', 'ho': 'ほ', 'ma': 'ま', 'mi': 'み', 'mu': 'む', 'me': 'め', 'mo': 'も',
  'ya': 'や', 'yu': 'ゆ', 'yo': 'よ', 'ra': 'ら', 'ri': 'り', 'ru': 'る', 're': 'れ', 'ro': 'ろ',
  'la': 'ら', 'li': 'り', 'lu': 'る', 'le': 'れ', 'lo': 'ろ', 'wa': 'わ', 'wo': 'を', 'wi': 'うぃ', 'we': 'うぇ',
  'ga': 'が', 'gi': 'ぎ', 'gu': 'ぐ', 'ge': 'げ', 'go': 'ご', 'za': 'ざ', 'zi': 'じ', 'ji': 'じ', 'zu': 'ず', 'ze': 'ぜ', 'zo': 'ぞ',
  'da': 'だ', 'di': 'ぢ', 'du': 'づ', 'de': 'で', 'do': 'ど', 'ba': 'ば', 'bi': 'び', 'bu': 'ぶ', 'be': 'べ', 'bo': 'ぼ',
  'pa': 'ぱ', 'pi': 'ぴ', 'pu': 'ぷ', 'pe': 'ぺ', 'po': 'ぽ', 'va': 'ゔぁ', 'vi': 'ゔぃ', 'vu': 'ゔ', 've': 'ゔぇ', 'vo': 'ゔぉ',
  'a': 'あ', 'i': 'い', 'u': 'う', 'e': 'え', 'o': 'お',
  'xa': 'ぁ', 'xi': 'ぃ', 'xu': 'ぅ', 'xe': 'ぇ', 'xo': 'ぉ', 'xya': 'ゃ', 'xyu': 'ゅ', 'xyo': 'ょ', 'xtu': 'っ', 'xtsu': 'っ',
};

bool _isConsonant(String c) => 'bcdfghjklmpqrstvwxyz'.contains(c);

/// Mengubah semua bagian romaji di [input] menjadi hiragana.
String romajiToHiragana(String input) {
  final s = input.toLowerCase();
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == '-') {
      out.write('ー');
      i++;
      continue;
    }
    if (!RegExp(r"[a-z']").hasMatch(c)) {
      out.write(input[i]);
      i++;
      continue;
    }
    // ん
    if (c == 'n') {
      final next = i + 1 < s.length ? s[i + 1] : '';
      if (next == 'n') {
        // "nn" + vokal/y → ん lalu "n" kedua memulai suku kata berikutnya (konnichiha → こんにちは)
        final after = i + 2 < s.length ? s[i + 2] : '';
        out.write('ん');
        i += (after.isNotEmpty && 'aiueoy'.contains(after)) ? 1 : 2;
        continue;
      }
      if (next == "'") {
        out.write('ん');
        i += 2;
        continue;
      }
      if (next == '' || (_isConsonant(next) && next != 'y') || !RegExp(r'[a-z]').hasMatch(next)) {
        // "n" di akhir masukan dibiarkan "n" agar pengguna masih bisa mengetik "na", "ni", ...
        if (next == '') {
          out.write('n');
          i++;
          continue;
        }
        out.write('ん');
        i++;
        continue;
      }
    }
    // konsonan ganda → っ
    if (i + 1 < s.length && c == s[i + 1] && _isConsonant(c) && c != 'n') {
      out.write('っ');
      i++;
      continue;
    }
    if (c == 't' && i + 2 < s.length && s.substring(i + 1, i + 3) == 'ch') {
      out.write('っ');
      i++;
      continue;
    }
    var matched = false;
    for (final len in [4, 3, 2, 1]) {
      if (i + len > s.length) continue;
      final k = _table[s.substring(i, i + len)];
      if (k != null) {
        out.write(k);
        i += len;
        matched = true;
        break;
      }
    }
    if (!matched) {
      out.write(input[i]);
      i++;
    }
  }
  return out.toString();
}

/// Versi untuk menyelesaikan masukan (saat "Periksa"): "n" di akhir → ん.
String romajiToHiraganaFinal(String input) {
  final r = romajiToHiragana(input);
  return r.endsWith('n') ? '${r.substring(0, r.length - 1)}ん' : r;
}
