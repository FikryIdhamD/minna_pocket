import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_route.dart';
import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/domain/models/lesson.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/section_scaffold.dart';

class RenshuuAScreen extends ConsumerWidget {
  const RenshuuAScreen({super.key, required this.lesson, required this.no});
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
        final item = l.sections.renshuuA.where((x) => x.no == no).firstOrNull;
        if (item == null) {
          return Scaffold(
              appBar: AppBar(), body: const ErrorView(message: S.loadError));
        }

        final nums = manifest?.lesson(lesson)?.section('renshuu_a')?.numbers ??
            [for (final x in l.sections.renshuuA) x.no];
        final idx = nums.indexOf(no);
        final prevNo = idx > 0 ? nums[idx - 1] : null;
        final nextNo = idx >= 0 && idx + 1 < nums.length ? nums[idx + 1] : null;

        return SectionScaffold(
          title: '${S.sectionJp['renshuu_a']} ${S.sectionNames['renshuu_a']}',
          subtitle: '${S.lesson} $lesson · ${S.number} $no',
          lesson: lesson,
          doneRef: '${l.id}.renshuu_a.$no',
          trackRoute: '/lesson/$lesson/renshuu_a/$no',
          trackLabel:
              '${S.lesson} $lesson · ${S.sectionNames['renshuu_a']} · ${S.number} $no',
          showModeToggle: true,
          bottomBar: NumberNavBar(
            prevRoute: prevNo != null
                ? sectionRoute(lesson, 'renshuu_a', no: prevNo)
                : null,
            nextRoute: nextNo != null
                ? sectionRoute(lesson, 'renshuu_a', no: nextNo)
                : null,
            nextLabel: '${S.number} ${nextNo ?? no + 1}',
          ),
          body: (ctx, _) => [
            Container(
              padding: const EdgeInsets.all(Sp.x4),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: Radii.lgAll,
                border: Border.all(color: p.border),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < item.lines.length; i++) ...[
                      if (i > 0) const SizedBox(height: Sp.x4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final seg in item.lines[i]) _segment(seg, p),
                            ]),
                      ),
                    ],
                  ]),
            ),
            const SizedBox(height: Sp.x3),
            Text('Baca keras-keras setiap baris kombinasi.',
                style: AppText.caption.copyWith(color: p.inkMuted)),
          ],
        );
      },
    );
  }

  Widget _segment(ASegment seg, AppPalette p) {
    if (!seg.isSlot) {
      return Padding(
        padding: const EdgeInsets.only(top: Sp.x2, left: Sp.x1, right: Sp.x1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (seg.textJp != null) JpTextView(seg.textJp!),
          for (final v in seg.variantsJp)
            JpTextView(v,
                size: JpSize.small, color: p.inkMuted, interactive: false),
        ]),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.x1),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var b = 0; b < seg.slot!.length; b++) ...[
          if (b > 0) const SizedBox(height: Sp.x1),
          _slotBox(seg.slot![b], p),
        ],
      ]),
    );
  }

  Widget _slotBox(ABox box, AppPalette p) {
    final bg = switch (box.hl) {
      BoxHighlight.strong => p.highlight,
      BoxHighlight.normal => p.highlightBg,
      BoxHighlight.none => Colors.transparent,
    };
    return Container(
      padding: const EdgeInsets.all(Sp.x2),
      decoration: BoxDecoration(color: bg, borderRadius: Radii.smAll),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var o = 0; o < box.opts.length; o++) ...[
          if (o > 0) const SizedBox(height: 2),
          JpTextView(box.opts[o]),
        ],
      ]),
    );
  }
}
