import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/content_blocks.dart';

class IntroScreen extends ConsumerWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(extraDocProvider('intro'));

    return Scaffold(
      appBar: AppBar(title: const Text('はじめに · Panduan')),
      body: SafeArea(
        top: false,
        child: docAsync.when(
          loading: () => const SkeletonList(),
          error: (_, __) =>
              const ErrorView(message: 'Bagian ini belum tersedia.'),
          data: (doc) => Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: Sizes.maxContentWidth),
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
        ),
      ),
    );
  }
}
