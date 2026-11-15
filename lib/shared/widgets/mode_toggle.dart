// Tombol geser あ | Ro (global). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/text_theme.dart';

class ModeToggle extends ConsumerWidget {
  const ModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mode = ref.watch(settingsProvider.select((s) => s.displayMode));
    Widget seg(String label, bool on, TextStyle st) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? p.surface : Colors.transparent,
            borderRadius: Radii.fullAll,
            boxShadow: on ? [BoxShadow(color: p.ink.withAlpha(31), blurRadius: 2, offset: const Offset(0, 1))] : null,
          ),
          child: Text(label, style: st.copyWith(color: on ? p.ink : p.inkMuted)),
        );
    return Semantics(
      button: true,
      label: mode == DisplayMode.kana ? 'Mode kana. Ketuk untuk romaji' : 'Mode romaji. Ketuk untuk kana',
      child: GestureDetector(
        onTap: () => ref.read(settingsProvider.notifier).toggleDisplayMode(),
        child: Container(
          height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: Radii.fullAll, border: Border.all(color: p.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            seg('あ', mode == DisplayMode.kana, AppText.jpSm(1).copyWith(height: 1)),
            seg('Ro', mode == DisplayMode.romaji, AppText.caption.copyWith(height: 1)),
          ]),
        ),
      ),
    );
  }
}
