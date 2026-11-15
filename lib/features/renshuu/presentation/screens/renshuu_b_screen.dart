import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route.dart';
import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/domain/models/jp_text.dart';
import '../../../../shared/domain/models/lesson.dart';
import '../../../../shared/domain/models/mondaishuu.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/book_image.dart';
import '../../../../shared/widgets/jp_actions.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/section_scaffold.dart';
import '../../../ai_assist/domain/providers/ai_session.dart';
import '../../../ai_assist/domain/repositories/ai_prompts.dart';
import '../../../bunkei_reibun/presentation/screens/bunkei_screen.dart';

class RenshuuBScreen extends ConsumerWidget {
  const RenshuuBScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final lessonAsync = ref.watch(lessonProvider(lesson));
    final manifest = ref.watch(manifestProvider).valueOrNull;

    return lessonAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(lessonProvider(lesson))),
      ),
      data: (l) {
        final rb = l.sections.renshuuB;
        final item = rb?.items.where((x) => x.no == no).firstOrNull;
        if (rb == null || item == null) {
          return Scaffold(
              appBar: AppBar(), body: const ErrorView(message: S.loadError));
        }

        final figure = rb.figureOf(item);
        final nums = manifest?.lesson(lesson)?.section('renshuu_b')?.numbers ??
            [for (final x in rb.items) x.no];
        final idx = nums.indexOf(no);
        final prevNo = idx > 0 ? nums[idx - 1] : null;
        final nextNo = idx >= 0 && idx + 1 < nums.length ? nums[idx + 1] : null;
        final msSet = _msForLesson(manifest?.mondaishuu ?? const [], lesson);

        final exText = item.examples
            .map((e) =>
                '${e.promptJp?.jp ?? '(gambar)'} → ${e.answerJp.map((a) => a.jp).join(' / ')}')
            .join('\n');
        final ctxText = lessonBookContext(l, exText);

        return SectionScaffold(
          title: '${S.sectionJp['renshuu_b']} ${S.sectionNames['renshuu_b']}',
          subtitle: '${S.lesson} $lesson · ${S.number} $no',
          lesson: lesson,
          doneRef: '${l.id}.renshuu_b.$no',
          trackRoute: '/lesson/$lesson/renshuu_b/$no',
          trackLabel:
              '${S.lesson} $lesson · ${S.sectionNames['renshuu_b']} · ${S.number} $no',
          showModeToggle: true,
          showGrammar: true,
          bottomBar: NumberNavBar(
            prevRoute: prevNo != null
                ? sectionRoute(lesson, 'renshuu_b', no: prevNo)
                : null,
            nextRoute: nextNo != null
                ? sectionRoute(lesson, 'renshuu_b', no: nextNo)
                : null,
            nextLabel: '${S.number} ${nextNo ?? no + 1}',
          ),
          body: (ctx, _) => [
            if (figure != null) ...[
              GestureDetector(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: const EdgeInsets.all(Sp.x3),
                    child: InteractiveViewer(
                        maxScale: 3, child: BookImage(figure.image)),
                  ),
                ),
                child: BookImage(figure.image),
              ),
              const SizedBox(height: Sp.x4),
            ],
            if (item.examples.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(Sp.x4),
                decoration: BoxDecoration(
                    color: p.secondarySubtle, borderRadius: Radii.lgAll),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Sp.x2, vertical: 2),
                          decoration: BoxDecoration(
                              color: p.secondary, borderRadius: Radii.smAll),
                          child: Text(S.example,
                              style:
                                  AppText.caption.copyWith(color: p.onPrimary)),
                        ),
                      ]),
                      const SizedBox(height: Sp.x2),
                      for (var i = 0; i < item.examples.length; i++) ...[
                        if (i > 0) const SizedBox(height: Sp.x3),
                        _exampleBlock(item.examples[i], p),
                      ],
                    ]),
              ),
              const SizedBox(height: Sp.x4),
            ],
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: Radii.lgAll,
                border: Border.all(color: p.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < item.questions.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: p.border),
                  _questionRow(context, item.questions[i], ctxText, p),
                ],
              ]),
            ),
            const SizedBox(height: Sp.x4),
            Text(S.noKeyMondai,
                style: AppText.caption.copyWith(color: p.inkMuted)),
            if (msSet != null) ...[
              const SizedBox(height: Sp.x3),
              OutlinedButton(
                onPressed: () => context.push('/ms/${msSet.id}'),
                child: const Text(S.goMondaishuu),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _exampleBlock(BExample ex, AppPalette p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (ex.promptJp != null)
              Flexible(child: JpTextView(ex.promptJp!))
            else
              Text('(lihat gambar)',
                  style: AppText.bodySm.copyWith(color: p.inkMuted)),
            Text(' →', style: AppText.body.copyWith(color: p.inkMuted)),
          ]),
          for (final ans in ex.answerJp)
            Padding(
              padding: const EdgeInsets.only(left: Sp.x4, top: Sp.x1),
              child: JpTextView(ans),
            ),
        ],
      );

  Widget _questionRow(
      BuildContext context, BQuestion q, String ctxText, AppPalette p) {
    final target = q.promptJp?.jp ?? 'Nomor ${q.no} (lihat gambar)';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => showJpActions(
        context,
        text: q.promptJp ??
            JpText(jp: target, tokens: [JpToken(s: target, ro: '')]),
        refId: q.id,
        kind: 'latihan',
        label:
            '${S.lesson} $lesson · ${S.sectionNames['renshuu_b']} $no.${q.no}',
        ai: AiRequest(
          action: AiAction.exampleAnswer,
          lesson: lesson,
          refId: q.id,
          target: target,
          bookContext: ctxText,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 28,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${q.no})',
                  style: AppText.bodyStrong.copyWith(color: p.inkMuted)),
            ),
          ),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (q.image != null) ...[
                BookImage(q.image!),
                if (q.promptJp != null) const SizedBox(height: Sp.x2),
              ],
              if (q.promptJp != null)
                JpTextView(q.promptJp!)
              else
                Text('(lihat gambar)',
                    style: AppText.bodySm.copyWith(color: p.inkMuted)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Sp.x2, top: 6),
            child: Text('→', style: AppText.body.copyWith(color: p.inkMuted)),
          ),
        ]),
      ),
    );
  }
}

MondaishuuMeta? _msForLesson(List<MondaishuuMeta> list, int lesson) {
  for (final m in list) {
    if (m.lessons.contains(lesson)) return m;
  }
  return null;
}
