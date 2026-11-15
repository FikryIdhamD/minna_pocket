import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_route.dart';
import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/domain/models/lesson.dart';
import '../../../../shared/domain/providers/settings_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/content_blocks.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/section_scaffold.dart';
import '../../../ai_assist/data/datasource/ai_key_store.dart';
import '../../../ai_assist/domain/providers/ai_session.dart';
import '../../../ai_assist/domain/repositories/ai_prompts.dart';
import '../../../ai_assist/presentation/widgets/ai_panel.dart';

class BunpouScreen extends ConsumerWidget {
  const BunpouScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final lessonAsync = ref.watch(lessonProvider(lesson));
    final manifest = ref.watch(manifestProvider).valueOrNull;
    final aiOn = ref.watch(aiEnabledProvider).valueOrNull ?? false;

    return lessonAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(lessonProvider(lesson))),
      ),
      data: (l) {
        final b = l.sections.bunpou.where((x) => x.no == no).firstOrNull;
        if (b == null)
          return Scaffold(
              appBar: AppBar(), body: const ErrorView(message: S.loadError));

        final nums = manifest?.lesson(lesson)?.section('bunpou')?.numbers ??
            [for (final x in l.sections.bunpou) x.no];
        final idx = nums.indexOf(no);
        final prevNo = idx > 0 ? nums[idx - 1] : null;
        final nextNo = idx >= 0 && idx + 1 < nums.length ? nums[idx + 1] : null;
        final ctxText = _bunpouContext(b);

        return SectionScaffold(
          title: S.sectionNames['bunpou']!,
          subtitle: '${S.lesson} $lesson · Poin $no',
          lesson: lesson,
          doneRef: '${l.id}.bunpou.$no',
          trackRoute: '/lesson/$lesson/bunpou/$no',
          trackLabel:
              '${S.lesson} $lesson · ${S.sectionNames['bunpou']} · Poin $no',
          showModeToggle: true,
          bottomBar: NumberNavBar(
            prevRoute: prevNo != null
                ? sectionRoute(lesson, 'bunpou', no: prevNo)
                : null,
            nextRoute: nextNo != null
                ? sectionRoute(lesson, 'bunpou', no: nextNo)
                : null,
            nextLabel: 'Poin ${nextNo ?? no + 1}',
          ),
          body: (ctx, _) => [
            Container(
              padding: const EdgeInsets.all(Sp.x4),
              decoration: BoxDecoration(
                  color: p.secondarySubtle, borderRadius: Radii.lgAll),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$no.',
                    style: AppText.brushNo.copyWith(color: p.secondary)),
                const SizedBox(width: Sp.x3),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        JpTextView(b.titleRich,
                            size: JpSize.small, mode: DisplayMode.kana),
                        if (b.titleNote != null) ...[
                          const SizedBox(height: Sp.x1),
                          Text(b.titleNote!,
                              style:
                                  AppText.caption.copyWith(color: p.inkMuted)),
                        ],
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: Sp.x4),
            ContentBlocksView(blocks: b.blocks, showTr: true),
            if (aiOn) ...[
              const SizedBox(height: Sp.x4),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.secondary,
                      side: BorderSide(color: p.secondary),
                    ),
                    onPressed: () => showAiPanel(
                      context,
                      AiRequest(
                        action: AiAction.simplerGrammar,
                        lesson: lesson,
                        refId: b.id,
                        target: b.titleRich.jp,
                        bookContext: ctxText,
                      ),
                    ),
                    child: const Text('✨ Jelaskan lebih sederhana',
                        textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: Sp.x3),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.secondary,
                      side: BorderSide(color: p.secondary),
                    ),
                    onPressed: () => showAiPanel(
                      context,
                      AiRequest(
                        action: AiAction.moreExamples,
                        lesson: lesson,
                        refId: b.id,
                        target: b.titleRich.jp,
                        bookContext: ctxText,
                      ),
                    ),
                    child: const Text('✨ Contoh lain',
                        textAlign: TextAlign.center),
                  ),
                ),
              ]),
            ],
          ],
        );
      },
    );
  }
}

String _bunpouContext(Bunpou b) {
  final buf = StringBuffer();
  for (final blk in b.blocks) {
    if (blk.textRich != null) buf.writeln(blk.textRich!.jp);
    for (final line in blk.lines) {
      buf.writeln('${line.jp.jp}${line.tr != null ? ' — ${line.tr}' : ''}');
    }
  }
  final s = buf.toString();
  return s.length <= 1500 ? s : s.substring(0, 1500);
}
