import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/content_blocks.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/section_scaffold.dart';

class SankouScreen extends ConsumerWidget {
  const SankouScreen({super.key, required this.lesson});
  final int lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final lessonAsync = ref.watch(lessonProvider(lesson));

    return lessonAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(lessonProvider(lesson))),
      ),
      data: (l) {
        final sankou = l.sections.sankou;
        if (sankou == null)
          return Scaffold(
              appBar: AppBar(), body: const ErrorView(message: S.loadError));

        return SectionScaffold(
          title: S.sectionNames['sankou']!,
          lesson: lesson,
          doneRef: '${l.id}.sankou',
          trackRoute: '/lesson/$lesson/sankou',
          trackLabel: '${S.lesson} $lesson · ${S.sectionNames['sankou']}',
          body: (ctx, _) => [
            JpTextView(sankou.titleJp, size: JpSize.title),
            const SizedBox(height: 2),
            Text(sankou.titleTr,
                style: AppText.bodySm.copyWith(color: p.secondary)),
            const SizedBox(height: Sp.x4),
            ContentBlocksView(blocks: sankou.blocks),
          ],
        );
      },
    );
  }
}
