import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/content_blocks.dart';
import '../../../hafalan/presentation/widgets/kana_grid.dart';

class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('はじめに'),
          bottom: TabBar(
            labelColor: p.primary,
            unselectedLabelColor: p.inkMuted,
            indicatorColor: p.primary,
            tabs: const [
              Tab(text: 'Huruf'),
              Tab(text: 'Panduan'),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _lettersTab(ref, p),
              _guideTab(ref, p),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lettersTab(WidgetRef ref, AppPalette p) {
    final chartAsync = ref.watch(kanaChartProvider);
    return chartAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorView(
        message: S.loadError,
        onRetry: () => ref.invalidate(kanaChartProvider),
      ),
      data: (chart) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(Sp.screen),
            children: [
              Text('Hiragana', style: AppText.title),
              const SizedBox(height: Sp.x3),
              for (final t in chart.hiragana) ...[
                Text(
                  t.title,
                  style: AppText.bodyStrong.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Sp.x2),
                KanaGrid(table: t),
                const SizedBox(height: Sp.x4),
              ],
              const SizedBox(height: Sp.x2),
              Text('Katakana', style: AppText.title),
              const SizedBox(height: Sp.x3),
              for (final t in chart.katakana) ...[
                Text(
                  t.title,
                  style: AppText.bodyStrong.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Sp.x2),
                KanaGrid(table: t),
                const SizedBox(height: Sp.x4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideTab(WidgetRef ref, AppPalette p) {
    final docAsync = ref.watch(extraDocProvider('intro'));
    return docAsync.when(
      loading: () => const SkeletonList(),
      error: (_, __) => const ErrorView(message: 'Bagian ini belum tersedia.'),
      data: (doc) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(Sp.screen),
            children: [
              for (final sec in doc.sections) ...[
                Text(sec.title, style: AppText.headline),
                const SizedBox(height: Sp.x2),
                ContentBlocksView(blocks: sec.blocks),
                const SizedBox(height: Sp.x4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
