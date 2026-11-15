// Jarak, radius, ukuran (docs/04_Design_System.md §4). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/widgets.dart';

abstract final class Sp {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;

  /// Margin kiri-kanan layar.
  static const double screen = 16;
}

abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double full = 999;
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));
}

abstract final class Sizes {
  static const double touch = 48; // target sentuh minimum
  static const double icon = 24;
  static const double iconSm = 18;
  static const double tile = 40; // tile huruf di daftar subtitle
  static const double button = 48;
  static const double rowMin = 60; // tinggi minimum baris daftar
  static const double appBar = 64;
  static const double maxContentWidth = 640; // tablet: konten di tengah
}
