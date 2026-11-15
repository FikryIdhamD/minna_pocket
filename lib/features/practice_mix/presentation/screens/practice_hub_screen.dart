import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/manifest.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_text_view.dart';

class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final manifestAsync = ref.watch(manifestProvider);
    final msScores = ref.watch(userDataProvider.select((u) => u.msScores));

    return Scaffold(
      body: SafeArea(
        child: AsyncView<BookManifest>(
          value: manifestAsync,
          onRetry: () => ref.invalidate(manifestProvider),
          data: (manifest) {
            return Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(Sp.screen),
                  children: [
                    Text('Latihan', style: AppText.title),
                    const SizedBox(height: Sp.x4),
                    Container(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: Radii.lgAll,
                        border: Border.all(color: p.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push('/mix'),
                        child: Padding(
                          padding: const EdgeInsets.all(Sp.x4),
                          child: Row(children: [
                            Container(
                              width: Sizes.tile,
                              height: Sizes.tile,
                              decoration: BoxDecoration(
                                color: p.primarySubtle,
                                borderRadius: Radii.mdAll,
                              ),
                              child: Center(
                                  child: AppIcon(AppIcons.shuffle,
                                      color: p.primaryStrong)),
                            ),
                            const SizedBox(width: Sp.x3),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Latihan Campuran',
                                        style: AppText.bodyStrong),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Soal acak lintas bab dari Mondaishuu & Kosa Kata',
                                      style: AppText.bodySm
                                          .copyWith(color: p.inkMuted),
                                    ),
                                  ]),
                            ),
                            const SizedBox(width: Sp.x2),
                            AppIcon(AppIcons.chevronRight, color: p.inkSubtle),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: Sp.x6),
                    Text('MONDAISHUU',
                        style: AppText.overline.copyWith(color: p.inkMuted)),
                    const SizedBox(height: Sp.x2),
                    Container(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: Radii.lgAll,
                        border: Border.all(color: p.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        for (var i = 0;
                            i < manifest.mondaishuu.length;
                            i++) ...[
                          if (i > 0)
                            Divider(height: 1, thickness: 1, color: p.border),
                          _msRow(context, manifest.mondaishuu[i], msScores, p),
                        ],
                      ]),
                    ),
                    const SizedBox(height: Sp.x8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _msRow(BuildContext context, dynamic m, Map<String, dynamic> msScores,
      AppPalette p) {
    final lessons = m.lessons as List<int>;
    final lessonLabel = lessons.length > 1
        ? 'Bab ${lessons.first}–${lessons.last}'
        : 'Bab ${lessons.first}';
    var best = 0;
    for (final entry in msScores.entries) {
      if (entry.key.startsWith('${m.id}.')) {
        best += (entry.value.best as int);
      }
    }
    return InkWell(
      onTap: () => context.push('/ms/${m.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              JpLabel(m.titleJp,
                  style: AppText.jpSm(1).copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('$lessonLabel · ${m.itemCount} soal',
                  style: AppText.bodySm.copyWith(color: p.inkMuted)),
            ]),
          ),
          const SizedBox(width: Sp.x2),
          Text('benar terbaik: $best/${m.itemCount}',
              style: AppText.caption.copyWith(color: p.inkMuted)),
        ]),
      ),
    );
  }
}
