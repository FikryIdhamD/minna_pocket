import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/domain/models/lesson.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_actions.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/section_scaffold.dart';
import '../../../ai_assist/domain/providers/ai_session.dart';
import '../../../ai_assist/domain/repositories/ai_prompts.dart';

class BunkeiScreen extends ConsumerStatefulWidget {
  const BunkeiScreen({super.key, required this.lesson});
  final int lesson;

  @override
  ConsumerState<BunkeiScreen> createState() => _BunkeiScreenState();
}

class _BunkeiScreenState extends ConsumerState<BunkeiScreen> {
  final Set<String> _openTr = {};

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lessonAsync = ref.watch(lessonProvider(widget.lesson));

    return lessonAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(lessonProvider(widget.lesson))),
      ),
      data: (l) {
        final ctxText = lessonBookContext(l);
        return SectionScaffold(
          title: '${S.sectionJp['bunkei']} ${S.sectionNames['bunkei']}',
          lesson: widget.lesson,
          doneRef: '${l.id}.bunkei',
          trackRoute: '/lesson/${widget.lesson}/bunkei',
          trackLabel:
              '${S.lesson} ${widget.lesson} · ${S.sectionNames['bunkei']}',
          showModeToggle: true,
          showTranslationToggle: true,
          body: (ctx, showTr) => [
            for (var i = 0; i < l.sections.bunkei.length; i++) ...[
              if (i > 0) const SizedBox(height: Sp.x5),
              _BunkeiItemRow(
                item: l.sections.bunkei[i],
                showTr: showTr || _openTr.contains(l.sections.bunkei[i].id),
                onToggleTr: () => setState(() {
                  final id = l.sections.bunkei[i].id;
                  if (!_openTr.add(id)) _openTr.remove(id);
                }),
                onLongPress: () {
                  final b = l.sections.bunkei[i];
                  showJpActions(
                    context,
                    text: b.jp,
                    refId: b.id,
                    kind: 'kalimat',
                    label: b.jp.jp,
                    ai: AiRequest(
                      action: AiAction.explainSentence,
                      lesson: widget.lesson,
                      refId: b.id,
                      target: b.jp.jp,
                      bookContext: ctxText,
                    ),
                  );
                },
                p: p,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BunkeiItemRow extends StatelessWidget {
  const _BunkeiItemRow({
    required this.item,
    required this.showTr,
    required this.onToggleTr,
    required this.onLongPress,
    required this.p,
  });
  final Bunkei item;
  final bool showTr;
  final VoidCallback onToggleTr;
  final VoidCallback onLongPress;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onToggleTr,
      onLongPress: onLongPress,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 4),
          decoration:
              BoxDecoration(color: p.surfaceAlt, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('${item.no}',
              style: AppText.caption.copyWith(color: p.inkMuted)),
        ),
        const SizedBox(width: Sp.x3),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            JpTextView(item.jp),
            for (final v in item.variantsJp)
              Align(
                alignment: Alignment.centerRight,
                child: JpTextView(v,
                    size: JpSize.small, color: p.inkMuted, interactive: false),
              ),
            if (showTr) ...[
              const SizedBox(height: Sp.x1),
              Text(item.tr, style: AppText.bodySm.copyWith(color: p.secondary)),
            ],
          ]),
        ),
      ]),
    );
  }
}

String lessonBookContext(Lesson l, [String? extra]) {
  final buf = StringBuffer();
  for (final g in l.sections.bunpou) {
    buf.writeln('${g.no}. ${g.titleRich.jp}');
  }
  for (final b in l.sections.bunkei) {
    buf.writeln('${b.jp.jp} — ${b.tr}');
  }
  if (extra != null && extra.isNotEmpty) buf.writeln(extra);
  final s = buf.toString();
  return s.length <= 1500 ? s : s.substring(0, 1500);
}
