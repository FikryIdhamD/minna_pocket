// ThemeData terang & gelap (docs/04_Design_System.md). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'text_theme.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppPalette.light);
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness b, AppPalette p) {
    final scheme = ColorScheme(
      brightness: b,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.secondary,
      onSecondary: p.surface,
      error: p.danger,
      onError: p.onPrimary,
      surface: p.bg,
      onSurface: p.ink,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: p.surfaceAlt,
      surfaceContainerHighest: p.surfaceAlt,
      outline: p.border,
      outlineVariant: p.border,
    );
    final textTheme = TextTheme(
      displaySmall: AppText.display,
      headlineSmall: AppText.title,
      titleLarge: AppText.title,
      titleMedium: AppText.headline,
      titleSmall: AppText.bodyStrong,
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      bodySmall: AppText.bodySm,
      labelLarge: AppText.button,
      labelMedium: AppText.caption,
      labelSmall: AppText.caption,
    ).apply(bodyColor: p.ink, displayColor: p.ink);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      fontFamily: AppFonts.ui,
      textTheme: textTheme,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: Sizes.appBar,
        centerTitle: false,
        titleTextStyle: AppText.headline.copyWith(color: p.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: p.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primarySubtle,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppText.caption.copyWith(color: s.contains(WidgetState.selected) ? p.ink : p.inkMuted),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          minimumSize: const Size(64, Sizes.button),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: AppText.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size(Sizes.touch, Sizes.touch - 4),
          side: BorderSide(color: p.border),
          backgroundColor: p.surface,
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
          textStyle: AppText.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primaryStrong,
          minimumSize: const Size(Sizes.touch, Sizes.touch),
          textStyle: AppText.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x3),
        hintStyle: AppText.body.copyWith(color: p.inkSubtle),
        border: OutlineInputBorder(borderRadius: Radii.smAll, borderSide: BorderSide(color: p.border)),
        enabledBorder: OutlineInputBorder(borderRadius: Radii.smAll, borderSide: BorderSide(color: p.border)),
        focusedBorder: OutlineInputBorder(borderRadius: Radii.smAll, borderSide: BorderSide(color: p.primary, width: 1.5)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg))),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.primarySubtle,
        side: BorderSide(color: p.border),
        labelStyle: AppText.bodyStrong.copyWith(color: p.ink),
        shape: const RoundedRectangleBorder(borderRadius: Radii.fullAll),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.player,
        contentTextStyle: AppText.body.copyWith(color: p.onPlayer),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
