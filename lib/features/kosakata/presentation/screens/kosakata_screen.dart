import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/tts_service/domain/providers/tts_service.dart';
import '../../../../shared/domain/models/lesson.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_actions.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/section_scaffold.dart';

class KosakataScreen extends ConsumerWidget {
  const KosakataScreen({super.key, required this.lesson});
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
        final groups = l.sections.kosakata?.groups ?? const <KosakataGroup>[];
        return SectionScaffold(
          title: S.sectionNames['kosakata']!,
          lesson: lesson,
          doneRef: '${l.id}.kosakata',
          trackRoute: '/lesson/$lesson/kosakata',
          trackLabel: '${S.lesson} $lesson · ${S.sectionNames['kosakata']}',
          showModeToggle: true,
          body: (ctx, _) => [
            for (final g in groups) ...[
              if (g.labelJp != null)
                Padding(
                  padding: const EdgeInsets.only(top: Sp.x4, bottom: Sp.x2),
                  child: JpTextView(g.labelJp!, size: JpSize.small),
                ),
              if (g.separator)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sp.x4),
                  child: Divider(height: 1, thickness: 1, color: p.border),
                ),
              Container(
                margin: const EdgeInsets.only(bottom: Sp.x3),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: Radii.lgAll,
                  border: Border.all(color: p.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (var i = 0; i < g.items.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, thickness: 1, color: p.border),
                    _KosakataRow(item: g.items[i]),
                  ],
                ]),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _KosakataRow extends ConsumerWidget {
  const _KosakataRow({required this.item});
  final KosakataItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final mainJp = item.kanjiJp ?? item.kanaJp;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => showJpActions(
        context,
        text: mainJp,
        refId: item.id,
        kind: 'kosakata',
        label: '${mainJp.jp} — ${item.tr}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (item.kanjiJp != null) ...[
                JpTextView(item.kanjiJp!),
                JpTextView(item.kanaJp,
                    size: JpSize.small, color: p.inkMuted, interactive: false),
              ] else
                JpTextView(item.kanaJp),
              const SizedBox(height: 2),
              Text(item.tr, style: AppText.body),
            ]),
          ),
          IconButton(
            tooltip: S.speak,
            onPressed: () =>
                ref.read(ttsServiceProvider).speak(item.kanaJp.reading),
            icon: AppIcon(AppIcons.speaker, color: p.ink),
          ),
        ]),
      ),
    );
  }
}
