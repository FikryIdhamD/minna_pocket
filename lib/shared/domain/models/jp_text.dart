// JpText: teks Jepang terkompilasi (lihat docs/03_Spesifikasi_Data.md §2).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

class JpToken {
  const JpToken({
    required this.s,
    required this.ro,
    this.r,
    this.k = false,
    this.u = false,
    this.blank = false,
  });

  /// Teks tampil.
  final String s;

  /// Bacaan (furigana). Hanya ada jika [k] true.
  final String? r;

  /// Romaji token ini, sudah termasuk spasi/tanda hubung di depan bila perlu.
  final String ro;

  /// Token kanji: bisa ditekan untuk memunculkan furigana.
  final bool k;

  /// Bergaris bawah (bagian yang diganti di Renshuu C).
  final bool u;

  /// Tempat kosong (isian). Ditampilkan sebagai kotak/garis kosong.
  final bool blank;

  factory JpToken.fromJson(Map<String, dynamic> j) => JpToken(
        s: j['s'] as String,
        r: j['r'] as String?,
        ro: j['ro'] as String,
        k: (j['k'] as bool?) ?? false,
        u: (j['u'] as bool?) ?? false,
        blank: (j['blank'] as bool?) ?? false,
      );
}

class JpText {
  const JpText({required this.jp, required this.tokens});

  /// Teks polos tanpa markup (untuk TTS, pencarian, salin).
  final String jp;
  final List<JpToken> tokens;

  factory JpText.fromJson(Map<String, dynamic> j) => JpText(
        jp: j['jp'] as String,
        tokens: (j['tokens'] as List)
            .map((e) => JpToken.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  static JpText? maybe(dynamic v) =>
      v == null ? null : JpText.fromJson(v as Map<String, dynamic>);

  static List<JpText> list(dynamic v) => v == null
      ? const []
      : (v as List)
          .map((e) => JpText.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);

  /// Baris romaji lengkap (spasi dirapikan).
  String get romaji => tokens
      .map((t) => t.ro)
      .join()
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Bacaan kana lengkap (kanji diganti bacaannya). Dipakai untuk TTS.
  String get reading => tokens.map((t) => t.r ?? t.s).join();

  bool get hasKanji => tokens.any((t) => t.k);
}
