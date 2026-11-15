import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/user_data.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_text_view.dart';

class MondaishuuResultScreen extends ConsumerWidget {
  const MondaishuuResultScreen({super.key, required this.setId});
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
        var totalLast = 0;
        var totalBest = 0;
        var totalGraded = 0;
        int? firstWrongExNo;

        for (final ex in set.exercises) {
          final t = ex.items.where((it) => it.autoGraded).length;
          final s = msScores[ex.id];
          totalGraded += t;
          if (s != null) {
            totalLast += s.last;
            totalBest += s.best;
            if (firstWrongExNo == null &&
                s.items.values.any((st) =>
                    st == ItemStatus.wrong || st == ItemStatus.assisted)) {
              firstWrongExNo = ex.no;
            }
          }
        }

        return PopScope(
          canPop: context.canPop(),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.go('/ms/$setId');
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Kembali',
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/ms/$setId'),
                icon: AppIcon(AppIcons.arrowLeft, color: p.ink),
              ),
              titleSpacing: 0,
              title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    JpLabel(set.titleJp, style: AppText.headline),
                    Text('Ringkasan',
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
                      Center(
                        child: Column(children: [
                          Text('$totalLast / $totalGraded',
                              style:
                                  AppText.brushHero.copyWith(color: p.primary)),
                          const SizedBox(height: Sp.x1),
                          Text('Skor terbaik: $totalBest / $totalGraded',
                              style:
                                  AppText.bodySm.copyWith(color: p.inkMuted)),
                        ]),
                      ),
                      const SizedBox(height: Sp.x6),
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
                            Builder(builder: (_) {
                              final ex = set.exercises[i];
                              final t =
                                  ex.items.where((it) => it.autoGraded).length;
                              final s = msScores[ex.id];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Sp.x4, vertical: Sp.x3),
                                child: Row(children: [
                                  Expanded(
                                      child: Text('Latihan ${ex.no}',
                                          style: AppText.bodyStrong)),
                                  Text(
                                    'terakhir ${s?.last ?? 0}/$t · terbaik ${s?.best ?? 0}/$t',
                                    style: AppText.bodySm
                                        .copyWith(color: p.inkMuted),
                                  ),
                                ]),
                              );
                            }),
                          ],
                        ]),
                      ),
                      const SizedBox(height: Sp.x6),
                      FilledButton(
                        onPressed: () {
                          final ud = ref.read(userDataProvider.notifier);
                          for (final ex in set.exercises) {
                            ud.clearAnswers('${ex.id}.');
                          }
                          context.pushReplacement('/ms/$setId/ex/1');
                        },
                        child: const Text(S.repeatAll),
                      ),
                      if (firstWrongExNo != null) ...[
                        const SizedBox(height: Sp.x3),
                        OutlinedButton(
                          onPressed: () => context.pushReplacement(
                              '/ms/$setId/ex/$firstWrongExNo?only=wrong'),
                          child: const Text(S.repeatWrong),
                        ),
                      ],
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
}
