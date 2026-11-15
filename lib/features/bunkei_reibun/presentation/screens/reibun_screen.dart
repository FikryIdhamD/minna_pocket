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
import 'bunkei_screen.dart';

class ReibunScreen extends ConsumerStatefulWidget {
  const ReibunScreen({super.key, required this.lesson});
  final int lesson;

  @override
  ConsumerState<ReibunScreen> createState() => _ReibunScreenState();
}

class _ReibunScreenState extends ConsumerState<ReibunScreen> {
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
          title: '${S.sectionJp['reibun']} ${S.sectionNames['reibun']}',
          lesson: widget.lesson,
          doneRef: '${l.id}.reibun',
          trackRoute: '/lesson/${widget.lesson}/reibun',
          trackLabel:
              '${S.lesson} ${widget.lesson} · ${S.sectionNames['reibun']}',
          showModeToggle: true,
          showTranslationToggle: true,
          body: (ctx, showTr) => [
            for (var i = 0; i < l.sections.reibun.length; i++) ...[
              if (i > 0) const SizedBox(height: Sp.x5),
              _ReibunCard(
                item: l.sections.reibun[i],
                showTrAll: showTr,
                openTr: _openTr,
                onToggleLine: (key) => setState(() {
                  if (!_openTr.add(key)) _openTr.remove(key);
                }),
                onLongPressLine: (key, line) => showJpActions(
                  context,
                  text: line.jp,
                  refId: key,
                  kind: 'kalimat',
                  label: line.jp.jp,
                  ai: AiRequest(
                    action: AiAction.explainSentence,
                    lesson: widget.lesson,
                    refId: key,
                    target: line.jp.jp,
                    bookContext: ctxText,
                  ),
                ),
                p: p,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ReibunCard extends StatelessWidget {
  const _ReibunCard({
    required this.item,
    required this.showTrAll,
    required this.openTr,
    required this.onToggleLine,
    required this.onLongPressLine,
    required this.p,
  });
  final Reibun item;
  final bool showTrAll;
  final Set<String> openTr;
  final ValueChanged<String> onToggleLine;
  final void Function(String key, TrLine line) onLongPressLine;
  final AppPalette p;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border),
      ),
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
            for (var j = 0; j < item.lines.length; j++) ...[
              if (j > 0) const SizedBox(height: Sp.x2),
              _buildLine(item.lines[j], item.lines[j].id ?? '${item.id}#$j'),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildLine(TrLine line, String key) {
    final isReply = line.jp.jp.startsWith('……');
    final trVisible = (showTrAll || openTr.contains(key)) && line.tr != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onToggleLine(key),
      onLongPress: () => onLongPressLine(key, line),
      child: Padding(
        padding: EdgeInsets.only(left: isReply ? Sp.x4 : 0),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          JpTextView(line.jp),
          for (final v in line.variantsJp)
            Align(
              alignment: Alignment.centerRight,
              child: JpTextView(v,
                  size: JpSize.small, color: p.inkMuted, interactive: false),
            ),
          if (trVisible) ...[
            const SizedBox(height: Sp.x1),
            Text(line.tr!, style: AppText.bodySm.copyWith(color: p.secondary)),
          ],
        ]),
      ),
    );
  }
}
