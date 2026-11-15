import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../widgets/kana_grid.dart';

class KanaTableScreen extends ConsumerWidget {
  const KanaTableScreen({super.key, required this.script});

  final String script; // 'hira' | 'kata'

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(kanaChartProvider);
    final title = script == 'kata' ? 'Katakana' : 'Hiragana';
    final p = context.palette;

    return chartAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const SkeletonList(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ErrorView(
          message: S.loadError,
          onRetry: () => ref.invalidate(kanaChartProvider),
        ),
      ),
      data: (chart) {
        final tables = script == 'kata' ? chart.katakana : chart.hiragana;
        return DefaultTabController(
          length: tables.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(title),
              bottom: TabBar(
                isScrollable: tables.length > 3,
                labelColor: p.primary,
                unselectedLabelColor: p.inkMuted,
                indicatorColor: p.primary,
                tabs: [for (final t in tables) Tab(text: t.title)],
              ),
            ),
            body: SafeArea(
              top: false,
              child: TabBarView(
                children: [
                  for (final t in tables)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(Sp.screen),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: Sizes.maxContentWidth),
                          child: KanaGrid(table: t, script: script),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
