import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route.dart';
import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/progress_selectors.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/manifest.dart';
import '../../../../shared/domain/models/mondaishuu.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/audio_widgets.dart';
import '../../../../shared/widgets/jp_text_view.dart';

class LessonScreen extends ConsumerWidget {
  const LessonScreen({super.key, required this.lesson});
  final int lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final manifestAsync = ref.watch(manifestProvider);
    final done = ref.watch(userDataProvider.select((u) => u.done));
    final lp = ref.watch(lessonProgressProvider(lesson));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: AppIcon(AppIcons.arrowLeft, color: p.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Cari',
            onPressed: () => context.push('/search'),
            icon: AppIcon(AppIcons.search, color: p.ink),
          ),
          const SizedBox(width: Sp.x1),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AsyncView<BookManifest>(
          value: manifestAsync,
          onRetry: () => ref.invalidate(manifestProvider),
          data: (manifest) {
            final meta = manifest.lesson(lesson);
            if (meta == null) return const ErrorView(message: S.loadError);
            final msSet = _mondaishuuForLesson(manifest.mondaishuu, lesson);
            final sectionsDone = lp?.sectionsDone ?? 0;
            final sectionsTotal = lp?.sectionsTotal ?? meta.sections.length;

            return Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: Sp.x8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Sp.x5, vertical: Sp.x2),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '第$lesson課',
                                    style: AppText.brushHero
                                        .copyWith(color: p.primary),
                                  ),
                                  const SizedBox(width: Sp.x4),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          JpTextView(meta.titleJp,
                                              size: JpSize.title),
                                          const SizedBox(height: 2),
                                          Text(meta.titleTr,
                                              style: AppText.bodySm.copyWith(
                                                  color: p.secondary)),
                                        ]),
                                  ),
                                ]),
                            const SizedBox(height: Sp.x4),
                            Row(children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: Radii.fullAll,
                                  child: LinearProgressIndicator(
                                    value: lp?.fraction ?? 0,
                                    minHeight: 6,
                                    color: p.primary,
                                    backgroundColor: p.surfaceAlt,
                                  ),
                                ),
                              ),
                              const SizedBox(width: Sp.x3),
                              Text(
                                '$sectionsDone / $sectionsTotal selesai',
                                style:
                                    AppText.caption.copyWith(color: p.inkMuted),
                              ),
                            ]),
                          ]),
                    ),
                    for (final group in kSectionGroups.entries) ...[
                      if (_sectionsInGroup(meta, group.value).isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              Sp.screen, Sp.x6, Sp.screen, Sp.x2),
                          child: Text(
                            (S.groupNames[group.key] ?? group.key)
                                .toUpperCase(),
                            style: AppText.overline.copyWith(color: p.inkMuted),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: Sp.screen),
                          child: Container(
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: Radii.lgAll,
                              border: Border.all(color: p.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(children: [
                              for (var i = 0;
                                  i <
                                      _sectionsInGroup(meta, group.value)
                                          .length;
                                  i++) ...[
                                if (i > 0)
                                  Divider(
                                      height: 1, thickness: 1, color: p.border),
                                _SectionRow(
                                  lessonMeta: meta,
                                  section:
                                      _sectionsInGroup(meta, group.value)[i],
                                  done: done,
                                ),
                              ],
                            ]),
                          ),
                        ),
                      ],
                    ],
                    if (msSet != null) ...[
                      const SizedBox(height: Sp.x6),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: Sp.screen),
                        child: Material(
                          color: p.surface,
                          borderRadius: Radii.mdAll,
                          child: InkWell(
                            borderRadius: Radii.mdAll,
                            onTap: () => context.push('/ms/${msSet.id}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Sp.x4, vertical: Sp.x3),
                              decoration: BoxDecoration(
                                borderRadius: Radii.mdAll,
                                border: Border.all(color: p.border),
                              ),
                              child: Row(children: [
                                AppIcon(AppIcons.practice, color: p.primary),
                                const SizedBox(width: Sp.x3),
                                Expanded(
                                    child: Text(S.goMondaishuu,
                                        style: AppText.bodyStrong)),
                                AppIcon(AppIcons.chevronRight,
                                    color: p.inkSubtle),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow(
      {required this.lessonMeta, required this.section, required this.done});
  final LessonMeta lessonMeta;
  final SectionMeta section;
  final Set<String> done;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final key = section.key;
    final isMain = section.source == 'main';
    final jpTitle = S.sectionJp[key];
    final isDone = isSectionDone(done, lessonMeta, section);
    final frac = sectionFraction(done, lessonMeta, section);
    final doneCount = section.numbers
        .where((x) => done.contains('${lessonMeta.id}.$key.$x'))
        .length;

    return InkWell(
      onTap: () => context.push(sectionRoute(lessonMeta.lesson, key)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        child: Row(children: [
          Container(
            width: Sizes.tile,
            height: Sizes.tile,
            decoration: BoxDecoration(
              color: isMain ? p.primarySubtle : p.secondarySubtle,
              borderRadius: Radii.mdAll,
            ),
            alignment: Alignment.center,
            child: Text(
              S.sectionTile[key] ?? '?',
              style: AppText.brushTile
                  .copyWith(color: isMain ? p.primaryStrong : p.secondary),
            ),
          ),
          const SizedBox(width: Sp.x3),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(S.sectionNames[key] ?? key, style: AppText.bodyStrong),
                if (jpTitle != null) ...[
                  const SizedBox(width: Sp.x2),
                  Text(jpTitle,
                      style: AppText.jpSm(1).copyWith(color: p.inkMuted)),
                ],
              ]),
              const SizedBox(height: 2),
              _subtitleWidget(context, section),
            ]),
          ),
          if (_audioBadgeText(section) != null) ...[
            const SizedBox(width: Sp.x2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 2),
              decoration: BoxDecoration(
                  color: p.audioSubtle, borderRadius: Radii.fullAll),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AppIcon(AppIcons.headphones, size: 14, color: p.ink),
                const SizedBox(width: Sp.x1),
                Text(_audioBadgeText(section)!,
                    style: AppText.caption.copyWith(color: p.ink)),
              ]),
            ),
          ],
          const SizedBox(width: Sp.x2),
          if (isDone)
            AppIcon(AppIcons.checkCircle, color: p.success)
          else if (section.hasPicker && frac > 0)
            Text('$doneCount/${section.numbers.length}',
                style: AppText.caption.copyWith(color: p.inkMuted))
          else
            AppIcon(AppIcons.chevronRight, color: p.inkSubtle),
        ]),
      ),
    );
  }

  Widget _subtitleWidget(BuildContext context, SectionMeta s) {
    final style = AppText.bodySm.copyWith(color: context.palette.inkMuted);
    switch (s.key) {
      case 'kosakata':
        return Text('${s.count ?? 0} kata · buku terjemahan', style: style);
      case 'bunkei':
        return Text('${s.count ?? 0} pola kalimat', style: style);
      case 'reibun':
        return Text('${s.count ?? 0} contoh kalimat', style: style);
      case 'kaiwa':
        return s.titleJp != null
            ? JpLabel(s.titleJp!, style: style)
            : const SizedBox.shrink();
      case 'renshuu_a':
        return Text('${s.count ?? 0} tabel pola', style: style);
      case 'renshuu_b':
        return Text('${s.count ?? 0} nomor', style: style);
      case 'renshuu_c':
        return Text('${s.count ?? 0} dialog latihan', style: style);
      case 'mondai':
        return Text(
            '${s.count ?? 0} nomor · ${s.audioNumbers.length} soal dengar',
            style: style);
      case 'bunpou':
        return Text('${s.count ?? 0} poin · buku terjemahan', style: style);
      case 'sankou':
        return Text(s.titleTr ?? '', style: style);
      default:
        return const SizedBox.shrink();
    }
  }
}

List<SectionMeta> _sectionsInGroup(LessonMeta meta, List<String> keys) => [
      for (final k in keys)
        if (meta.section(k) != null) meta.section(k)!
    ];

String? _audioBadgeText(SectionMeta s) {
  if (s.key == 'kaiwa' && s.duration != null) {
    return fmtTime(Duration(seconds: s.duration!.round()));
  }
  if (s.key == 'mondai' && s.audioNumbers.isNotEmpty) {
    return '${s.audioNumbers.length}';
  }
  return null;
}

MondaishuuSetMeta? _mondaishuuForLesson(
    List<MondaishuuSetMeta> list, int lesson) {
  for (final m in list) {
    if (m.lessons.contains(lesson)) return m;
  }
  return null;
}
