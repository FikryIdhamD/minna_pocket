import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_route.dart';
import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/book_image.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/section_scaffold.dart';

class RenshuuCScreen extends ConsumerStatefulWidget {
  const RenshuuCScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;

  @override
  ConsumerState<RenshuuCScreen> createState() => _RenshuuCScreenState();
}

class _RenshuuCScreenState extends ConsumerState<RenshuuCScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lessonAsync = ref.watch(lessonProvider(widget.lesson));
    final manifest = ref.watch(manifestProvider).valueOrNull;

    return lessonAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(lessonProvider(widget.lesson))),
      ),
      data: (l) {
        final item =
            l.sections.renshuuC.where((x) => x.no == widget.no).firstOrNull;
        if (item == null) {
          return Scaffold(
              appBar: AppBar(), body: const ErrorView(message: S.loadError));
        }

        final nums =
            manifest?.lesson(widget.lesson)?.section('renshuu_c')?.numbers ??
                [for (final x in l.sections.renshuuC) x.no];
        final idx = nums.indexOf(widget.no);
        final prevNo = idx > 0 ? nums[idx - 1] : null;
        final nextNo = idx >= 0 && idx + 1 < nums.length ? nums[idx + 1] : null;

        final sub = _selected > 0 && _selected <= item.substitutions.length
            ? item.substitutions[_selected - 1]
            : null;
        final imagePath = _selected == 0 ? item.image : sub?.image;

        return SectionScaffold(
          title: '${S.sectionJp['renshuu_c']} ${S.sectionNames['renshuu_c']}',
          subtitle: '${S.lesson} ${widget.lesson} · ${S.number} ${widget.no}',
          lesson: widget.lesson,
          doneRef: '${l.id}.renshuu_c.${widget.no}',
          trackRoute: '/lesson/${widget.lesson}/renshuu_c/${widget.no}',
          trackLabel:
              '${S.lesson} ${widget.lesson} · ${S.sectionNames['renshuu_c']} · ${S.number} ${widget.no}',
          showModeToggle: true,
          bottomBar: NumberNavBar(
            prevRoute: prevNo != null
                ? sectionRoute(widget.lesson, 'renshuu_c', no: prevNo)
                : null,
            nextRoute: nextNo != null
                ? sectionRoute(widget.lesson, 'renshuu_c', no: nextNo)
                : null,
            nextLabel: '${S.number} ${nextNo ?? widget.no + 1}',
          ),
          body: (ctx, _) => [
            if (item.substitutions.isNotEmpty) ...[
              SegmentedButton<int>(
                segments: [
                  const ButtonSegment<int>(value: 0, label: Text('Contoh')),
                  for (var k = 1; k <= item.substitutions.length; k++)
                    ButtonSegment<int>(value: k, label: Text('$k')),
                ],
                selected: {_selected},
                onSelectionChanged: (s) => setState(() => _selected = s.first),
              ),
              const SizedBox(height: Sp.x4),
            ],
            if (imagePath != null) ...[
              BookImage(imagePath),
              const SizedBox(height: Sp.x4),
            ],
            if (sub != null && sub.optsJp.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(Sp.x3),
                decoration: BoxDecoration(
                    color: p.highlightBg, borderRadius: Radii.mdAll),
                child: Wrap(
                  spacing: Sp.x3,
                  runSpacing: Sp.x2,
                  children: [for (final opt in sub.optsJp) JpTextView(opt)],
                ),
              ),
              const SizedBox(height: Sp.x4),
            ],
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
                    for (var i = 0; i < item.dialog.length; i++) ...[
                      if (i > 0) const SizedBox(height: Sp.x2),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              child: item.dialog[i].turnStart &&
                                      item.dialog[i].speakerJp != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        item.dialog[i].speakerJp!.jp,
                                        style: AppText.bodyStrong
                                            .copyWith(color: p.primaryStrong),
                                      ),
                                    )
                                  : null,
                            ),
                            Expanded(child: JpTextView(item.dialog[i].jp)),
                          ]),
                    ],
                  ]),
            ),
            const SizedBox(height: Sp.x3),
            Text(
              'Ganti bagian bergaris bawah sesuai gambar 1 / 2, lalu ucapkan dialognya.',
              style: AppText.caption.copyWith(color: p.inkMuted),
            ),
          ],
        );
      },
    );
  }
}
