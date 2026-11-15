import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/progress_selectors.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/extra_doc.dart';
import '../../../../shared/domain/models/manifest.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/content_blocks.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;
  int _doneLesson = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _skip() {
    ref.read(userDataProvider.notifier).setOnboardingDone();
    context.go('/');
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final howtoAsync = ref.watch(extraDocProvider('howto'));
    final manifest = ref.watch(manifestProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
            child: Column(children: [
              SizedBox(
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Sp.screen),
                  child:
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (_page < 2)
                      TextButton(onPressed: _skip, child: const Text('Lewati')),
                  ]),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _page1(howtoAsync, p),
                    _page2(p),
                    _page3(manifest, p),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Sp.x4),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: i == _page ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: i == _page ? p.primary : p.border,
                        borderRadius: Radii.fullAll,
                      ),
                    ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _page1(AsyncValue<ExtraDoc> howtoAsync, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.screen),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Cara belajar dari buku', style: AppText.display),
        const SizedBox(height: Sp.x4),
        Expanded(
          child: AsyncView<ExtraDoc>(
            value: howtoAsync,
            onRetry: () => ref.invalidate(extraDocProvider('howto')),
            data: (doc) => ListView(
              children: [
                if (doc.sections.isNotEmpty)
                  ContentBlocksView(blocks: doc.sections.first.blocks),
              ],
            ),
          ),
        ),
        const SizedBox(height: Sp.x3),
        FilledButton(onPressed: _nextPage, child: const Text('Lanjut')),
      ]),
    );
  }

  Widget _page2(AppPalette p) {
    const items = [
      (AppIcons.book, 'Ketuk kanji', 'Furigana muncul saat kanji diketuk.'),
      (AppIcons.translate, 'あ | Ro', 'Ganti tampilan ke romaji kapan saja.'),
      (
        AppIcons.speaker,
        '🔊 Ucapkan',
        'Tekan lama teks untuk mendengar pengucapan (suara sintetis).'
      ),
      (
        AppIcons.sparkles,
        '✨ AI (opsional)',
        'Isi API key di Pengaturan untuk penjelasan AI.'
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.screen),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Fitur Minna Pocket', style: AppText.display),
        const SizedBox(height: Sp.x6),
        Expanded(
          child: ListView(children: [
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: Radii.lgAll,
                border: Border.all(color: p.border),
              ),
              child: Column(children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: p.border),
                  Padding(
                    padding: const EdgeInsets.all(Sp.x4),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppIcon(items[i].$1, color: p.primary),
                          const SizedBox(width: Sp.x3),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(items[i].$2, style: AppText.bodyStrong),
                                  const SizedBox(height: 2),
                                  Text(items[i].$3,
                                      style: AppText.bodySm
                                          .copyWith(color: p.inkMuted)),
                                ]),
                          ),
                        ]),
                  ),
                ],
              ]),
            ),
          ]),
        ),
        const SizedBox(height: Sp.x3),
        FilledButton(onPressed: _nextPage, child: const Text('Lanjut')),
      ]),
    );
  }

  Widget _page3(BookManifest? manifest, AppPalette p) {
    final maxLesson = manifest?.lessons.length ?? 25;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Sp.screen),
      child: ListView(children: [
        Text('Sudah pernah belajar?', style: AppText.display),
        const SizedBox(height: Sp.x6),
        Material(
          color: p.surface,
          borderRadius: Radii.lgAll,
          child: InkWell(
            borderRadius: Radii.lgAll,
            onTap: () {
              ref.read(userDataProvider.notifier).setOnboardingDone();
              context.go('/');
            },
            child: Container(
              padding: const EdgeInsets.all(Sp.x4),
              decoration: BoxDecoration(
                borderRadius: Radii.lgAll,
                border: Border.all(color: p.border),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Belum, mulai dari nol', style: AppText.headline),
                        const SizedBox(height: 2),
                        Text('Mulai dari tabel Hiragana.',
                            style: AppText.bodySm.copyWith(color: p.inkMuted)),
                      ]),
                ),
                AppIcon(AppIcons.chevronRight, color: p.inkSubtle),
              ]),
            ),
          ),
        ),
        const SizedBox(height: Sp.x4),
        Container(
          padding: const EdgeInsets.all(Sp.x4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: Radii.lgAll,
            border: Border.all(color: p.border),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Sudah, sampai bab …', style: AppText.headline),
            const SizedBox(height: Sp.x4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: _doneLesson > 1
                    ? () => setState(() => _doneLesson--)
                    : null,
                icon: AppIcon(AppIcons.chevronLeft,
                    color: _doneLesson > 1 ? p.ink : p.inkSubtle),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  '$_doneLesson',
                  textAlign: TextAlign.center,
                  style: AppText.brushHero.copyWith(color: p.primary),
                ),
              ),
              IconButton(
                onPressed: _doneLesson < maxLesson
                    ? () => setState(() => _doneLesson++)
                    : null,
                icon: AppIcon(AppIcons.chevronRight,
                    color: _doneLesson < maxLesson ? p.ink : p.inkSubtle),
              ),
            ]),
            const SizedBox(height: Sp.x4),
            FilledButton(
              onPressed: () {
                final ud = ref.read(userDataProvider.notifier);
                if (manifest != null) {
                  final refs = <String>[
                    for (final l in manifest.lessons)
                      if (l.lesson < _doneLesson + 1)
                        for (final s in l.sections) ...sectionUnitRefs(l, s),
                  ];
                  ud.setManyDone(refs, true);
                }
                ud.setOnboardingDone();
                context.go('/');
              },
              child: Text('Mulai dari Bab ${_doneLesson + 1}'),
            ),
          ]),
        ),
      ]),
    );
  }
}
