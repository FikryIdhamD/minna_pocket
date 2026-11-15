// Kerangka 4 tab bawah. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget icon(String name, bool on) =>
        AppIcon(name, color: on ? p.primaryStrong : p.inkMuted);
    return PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && shell.currentIndex != 0) shell.goBranch(0);
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            NavigationDestination(
                icon: icon(AppIcons.book, false),
                selectedIcon: icon(AppIcons.book, true),
                label: S.tabLearn),
            NavigationDestination(
                icon: icon(AppIcons.practice, false),
                selectedIcon: icon(AppIcons.practice, true),
                label: S.tabPractice),
            NavigationDestination(
                icon: icon(AppIcons.cards, false),
                selectedIcon: icon(AppIcons.cards, true),
                label: S.tabHafalan),
            NavigationDestination(
                icon: icon(AppIcons.more, false),
                selectedIcon: icon(AppIcons.more, true),
                label: S.tabMore),
          ],
        ),
      ),
    );
  }
}
