import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/mondaishuu.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_text_view.dart';

class MondaishuuSetScreen extends ConsumerWidget {
  const MondaishuuSetScreen({super.key, required this.setId});
  final String setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final setAsync = ref.watch(mondaishuuProvider(setId));
    final msScores = ref.watch(userDataProvider.select((u) => u.msScores));

    return setAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(mondaishuuProvider(setId))),
      ),
      data: (set) {
        return PopScope(
          canPop: context.canPop(),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.go('/practice');
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Kembali',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/practice'),
                icon: AppIcon(AppIcons.arrowLeft, color: p.ink),
              ),
              titleSpacing: 0,
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JpLabel(set.titleJp, style: AppText.headline),
                    Text('Mondaishuu',
                        style: AppText.caption.copyWith(color: p.inkMuted)),
                  ]),
            ),
            body: SafeArea(
              top: false,
              child: Center(
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
                          for (var i = 0; i < set.exercises.length; i++) ...[
                            if (i > 0)
                              Divider(height: 1, thickness: 1, color: p.border),
                            _exRow(context, set.exercises[i],
                                msScores[set.exercises[i].id], p),
                          ],
                        ]),
                      ),
                      const SizedBox(height: Sp.x5),
                      OutlinedButton(
                        onPressed: () => context.push('/ms/$setId/result'),
                        child: const Text('Lihat ringkasan'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _exRow(
      BuildContext context, MsExercise ex, dynamic score, AppPalette p) {
    final perfect =
        score != null && score.best == score.total && score.total > 0;
    return InkWell(
      onTap: () => context.push('/ms/$setId/ex/${ex.no}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Latihan ${ex.no}', style: AppText.bodyStrong),
              const SizedBox(height: 2),
              Text('${ex.items.length} soal',
                  style: AppText.bodySm.copyWith(color: p.inkMuted)),
            ]),
          ),
          if (score != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 2),
              decoration: BoxDecoration(
                color: perfect ? p.successSubtle : p.surfaceAlt,
                borderRadius: Radii.fullAll,
              ),
              child: Text(
                '${score.best}/${score.total}',
                style: AppText.caption
                    .copyWith(color: perfect ? p.success : p.inkMuted),
              ),
            )
          else
            AppIcon(AppIcons.chevronRight, color: p.inkSubtle),
        ]),
      ),
    );
  }
}
