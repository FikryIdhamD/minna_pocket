// Tipografi (docs/04_Design_System.md §3). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
// Font variabel: ketebalan diatur lewat fontWeight + fontVariations (wght).

import 'dart:ui' show FontVariation;
import 'package:flutter/material.dart';

abstract final class AppFonts {
  static const jp = 'NotoSansJP';
  static const brush = 'KleeOne';
  static const ui = 'PlusJakartaSans';
}

TextStyle _s(String family, double size, double height, int weight, {double? letterSpacing}) => TextStyle(
      fontFamily: family,
      fontFamilyFallback: const [AppFonts.jp],
      fontSize: size,
      height: height / size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation('wght', weight.toDouble())],
      letterSpacing: letterSpacing,
    );

/// Gaya teks. Warna TIDAK ditentukan di sini (diwarisi dari tema / diberi saat dipakai).
abstract final class AppText {
  // ---- UI (Plus Jakarta Sans)
  static final display = _s(AppFonts.ui, 28, 34, 700, letterSpacing: -0.4);
  static final title = _s(AppFonts.ui, 20, 28, 700, letterSpacing: -0.2);
  static final headline = _s(AppFonts.ui, 17, 24, 700);
  static final bodyStrong = _s(AppFonts.ui, 15, 20, 600);
  static final body = _s(AppFonts.ui, 15, 22, 500);
  static final bodySm = _s(AppFonts.ui, 13, 18, 500);
  static final caption = _s(AppFonts.ui, 12, 16, 600, letterSpacing: 0.2);
  static final overline = _s(AppFonts.ui, 12, 16, 600, letterSpacing: 0.7); // tulis UPPERCASE
  static final button = _s(AppFonts.ui, 15, 20, 600);

  // ---- Jepang (Noto Sans JP)
  /// Teks Jepang utama. Ukuran dikali skala huruf dari Settings.
  static TextStyle jp(double scale) => _s(AppFonts.jp, 18 * scale, 36 * scale, 400);
  static TextStyle jpTitle(double scale) => _s(AppFonts.jp, 22 * scale, 36 * scale, 700);
  static TextStyle jpSm(double scale) => _s(AppFonts.jp, 14 * scale, 22 * scale, 500);
  static TextStyle furigana(double scale) => _s(AppFonts.jp, 10 * scale, 12 * scale, 500);
  static TextStyle romaji(double scale) => _s(AppFonts.ui, 17 * scale, 26 * scale, 500);
  static TextStyle jpUnderRomaji(double scale) => _s(AppFonts.jp, 13 * scale, 20 * scale, 400);

  // ---- Kuas (Klee One) — angka bab, kanji besar, tile
  static final brushHero = _s(AppFonts.brush, 44, 48, 600);
  static final brushCard = _s(AppFonts.brush, 72, 80, 600);
  static final brushNo = _s(AppFonts.brush, 26, 28, 600);
  static final brushTile = _s(AppFonts.brush, 20, 22, 600);
}
