import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../domain/providers/mix_providers.dart';

class MixSetupScreen extends ConsumerStatefulWidget {
  const MixSetupScreen({super.key});

  @override
  ConsumerState<MixSetupScreen> createState() => _MixSetupScreenState();
}

class _MixSetupScreenState extends ConsumerState<MixSetupScreen> {
  int? _from;
  int? _to;
  bool _useMs = true;
  bool _useVocab = true;
  int? _count = 10;
  bool _focusWeak = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final manifestAsync = ref.watch(manifestProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Latihan Campuran')),
      body: SafeArea(
        top: false,
        child: manifestAsync.when(
          loading: () => const SkeletonList(),
          error: (e, _) => ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(manifestProvider),
          ),
          data: (manifest) {
            final maxLesson = manifest.lessons.isEmpty
                ? 1
                : manifest.lessons.map((l) => l.lesson).reduce(max);
            final from = (_from ?? 1).clamp(1, maxLesson);
            final to = (_to ?? maxLesson).clamp(from, maxLesson);
            final canStart = _useMs || _useVocab;

            return Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(Sp.screen),
                  children: [
                    Text('Rentang bab', style: AppText.bodyStrong),
                    const SizedBox(height: Sp.x1),
                    Text(
                      'Bab $from – $to',
                      style: AppText.headline.copyWith(color: p.primary),
                    ),
                    if (maxLesson > 1)
                      RangeSlider(
                        min: 1,
                        max: maxLesson.toDouble(),
                        divisions: maxLesson - 1,
                        values: RangeValues(from.toDouble(), to.toDouble()),
                        labels: RangeLabels('Bab $from', 'Bab $to'),
                        onChanged: (v) => setState(() {
                          _from = v.start.round();
                          _to = v.end.round();
                        }),
                      ),
                    const SizedBox(height: Sp.x4),
                    Text('Jenis soal', style: AppText.bodyStrong),
                    const SizedBox(height: Sp.x1),
                    Container(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: Radii.lgAll,
                        border: Border.all(color: p.border),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: const Text('Mondaishuu'),
                            value: _useMs,
                            onChanged: (v) =>
                                setState(() => _useMs = v ?? false),
                          ),
                          Divider(height: 1, thickness: 1, color: p.border),
                          CheckboxListTile(
                            title: const Text('Kuis kosakata'),
                            value: _useVocab,
                            onChanged: (v) =>
                                setState(() => _useVocab = v ?? false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Sp.x4),
                    Text('Jumlah soal', style: AppText.bodyStrong),
                    const SizedBox(height: Sp.x2),
                    SegmentedButton<int?>(
                      segments: const [
                        ButtonSegment(value: 10, label: Text('10')),
                        ButtonSegment(value: 20, label: Text('20')),
                        ButtonSegment(value: 30, label: Text('30')),
                        ButtonSegment(value: null, label: Text('Semua')),
                      ],
                      selected: {_count},
                      onSelectionChanged: (v) =>
                          setState(() => _count = v.first),
                    ),
                    const SizedBox(height: Sp.x4),
                    Container(
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: Radii.lgAll,
                        border: Border.all(color: p.border),
                      ),
                      child: SwitchListTile(
                        title: const Text('Fokus kelemahan'),
                        subtitle: const Text(
                            'Soal yang pernah salah lebih sering muncul'),
                        value: _focusWeak,
                        onChanged: (v) => setState(() => _focusWeak = v),
                      ),
                    ),
                    const SizedBox(height: Sp.x6),
                    FilledButton(
                      onPressed: canStart
                          ? () {
                              ref.read(mixConfigProvider.notifier).setConfig(
                                    MixConfig(
                                      from: from,
                                      to: to,
                                      useMs: _useMs,
                                      useVocab: _useVocab,
                                      count: _count,
                                      focusWeak: _focusWeak,
                                    ),
                                  );
                              ref.invalidate(mixQuestionsProvider);
                              context.push('/mix/session');
                            }
                          : null,
                      child: const Text('Mulai'),
                    ),
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
