import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route.dart';
import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/lesson.dart';
import '../../../../shared/domain/models/manifest.dart';
import '../../../../shared/domain/providers/settings_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_text_view.dart';

class NumberPickerScreen extends ConsumerWidget {
  const NumberPickerScreen(
      {super.key, required this.lesson, required this.section});
  final int lesson;
  final String section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final manifestAsync = ref.watch(manifestProvider);
    final done = ref.watch(userDataProvider.select((u) => u.done));
    final jp = S.sectionJp[section];
    final name = S.sectionNames[section] ?? section;
    final title =
        section == 'bunpou' ? name : (jp != null ? '$jp $name' : name);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/lesson/$lesson'),
          icon: AppIcon(AppIcons.arrowLeft, color: p.ink),
        ),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppText.headline
                  .copyWith(fontFamilyFallback: const [AppFonts.jp])),
          Text('${S.lesson} $lesson · pilih nomor',
              style: AppText.caption.copyWith(color: p.inkMuted)),
        ]),
      ),
      body: SafeArea(
        top: false,
        child: AsyncView<BookManifest>(
          value: manifestAsync,
          onRetry: () => ref.invalidate(manifestProvider),
          data: (manifest) {
            final meta = manifest.lesson(lesson);
            final secMeta = meta?.section(section);
            if (meta == null || secMeta == null) {
              return const ErrorView(message: S.loadError);
            }

            if (section == 'bunpou') {
              return AsyncView<Lesson>(
                value: ref.watch(lessonProvider(lesson)),
                onRetry: () => ref.invalidate(lessonProvider(lesson)),
                data: (lessonData) {
                  final list = lessonData.sections.bunpou;
                  return Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                      child: ListView(
                        padding: const EdgeInsets.all(Sp.screen),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: Radii.lgAll,
                              border: Border.all(color: p.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(children: [
                              for (var i = 0; i < list.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                      height: 1, thickness: 1, color: p.border),
                                _BunpouRow(
                                  point: list[i],
                                  isDone: done.contains(
                                      '${meta.id}.bunpou.${list[i].no}'),
                                  onTap: () => context.push(sectionRoute(
                                      lesson, section,
                                      no: list[i].no)),
                                ),
                              ],
                            ]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            final numbers = secMeta.numbers;
            return Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: GridView.builder(
                  padding: const EdgeInsets.all(Sp.screen),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: Sp.x3,
                    crossAxisSpacing: Sp.x3,
                  ),
                  itemCount: numbers.length,
                  itemBuilder: (context, i) {
                    final x = numbers[i];
                    final hasAudio = secMeta.audioNumbers.contains(x);
                    final isDone = done.contains('${meta.id}.$section.$x');
                    return Material(
                      color: p.surface,
                      borderRadius: Radii.lgAll,
                      child: InkWell(
                        borderRadius: Radii.lgAll,
                        onTap: () =>
                            context.push(sectionRoute(lesson, section, no: x)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: Radii.lgAll,
                            border: Border.all(color: p.border),
                          ),
                          child: Stack(children: [
                            Center(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$x',
                                        style: AppText.brushNo
                                            .copyWith(color: p.primary)),
                                    const SizedBox(height: Sp.x1),
                                    Text('${S.number} $x',
                                        style: AppText.caption
                                            .copyWith(color: p.inkMuted)),
                                  ]),
                            ),
                            if (hasAudio || isDone)
                              Positioned(
                                top: Sp.x2,
                                right: Sp.x2,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasAudio)
                                        AppIcon(AppIcons.headphones,
                                            size: 16, color: p.inkMuted),
                                      if (hasAudio && isDone)
                                        const SizedBox(width: Sp.x1),
                                      if (isDone)
                                        AppIcon(AppIcons.checkCircle,
                                            size: 16, color: p.success),
                                    ]),
                              ),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BunpouRow extends StatelessWidget {
  const _BunpouRow(
      {required this.point, required this.isDone, required this.onTap});
  final Bunpou point;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 28,
            child: Text('${point.no}.',
                style: AppText.bodyStrong.copyWith(color: p.secondary)),
          ),
          Expanded(
            child: JpTextView(point.titleRich,
                size: JpSize.small, mode: DisplayMode.kana, interactive: false),
          ),
          const SizedBox(width: Sp.x2),
          if (isDone)
            AppIcon(AppIcons.checkCircle, color: p.success)
          else
            AppIcon(AppIcons.chevronRight, color: p.inkSubtle),
        ]),
      ),
    );
  }
}
