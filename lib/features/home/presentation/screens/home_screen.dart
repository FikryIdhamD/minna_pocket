import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/progress_selectors.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/manifest.dart';
import '../../../../shared/domain/models/user_data.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/srs.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/progress_ring.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final manifestAsync = ref.watch(manifestProvider);
    final ud = ref.watch(userDataProvider);
    final overall = ref.watch(overallProgressProvider);
    final dueCount = ud.srs.values.where(isDue).length;
    final showBackup = ud.done.isNotEmpty &&
        (ud.lastBackupAt == null ||
            DateTime.now().difference(ud.lastBackupAt!).inDays > 30);

    return Scaffold(
      body: SafeArea(
        child: AsyncView<BookManifest>(
          value: manifestAsync,
          onRetry: () => ref.invalidate(manifestProvider),
          data: (manifest) {
            final pct = ((overall?.fraction ?? 0) * 100).round();
            final started = overall?.lessonsStarted ?? 0;
            final total = overall?.lessonsTotal ?? manifest.lessons.length;

            return Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(Sp.screen),
                  children: [
                    SizedBox(
                      height: 56,
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset('assets/logo/logo_256.png',
                              width: 36, height: 36),
                        ),
                        const SizedBox(width: Sp.x3),
                        Text(S.appName, style: AppText.title),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Cari',
                          onPressed: () => context.push('/search'),
                          icon: AppIcon(AppIcons.search, color: p.ink),
                        ),
                      ]),
                    ),
                    const SizedBox(height: Sp.x3),
                    _ContinueCard(
                        lastOpened: ud.lastOpened, lesson1: manifest.lesson(1)),
                    if (dueCount > 0) ...[
                      const SizedBox(height: Sp.x3),
                      Material(
                        color: p.secondarySubtle,
                        borderRadius: Radii.mdAll,
                        child: InkWell(
                          borderRadius: Radii.mdAll,
                          onTap: () => context.push('/review'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Sp.x4, vertical: Sp.x3),
                            child: Row(children: [
                              AppIcon(AppIcons.cards, color: p.secondary),
                              const SizedBox(width: Sp.x3),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(S.reviewToday,
                                          style: AppText.bodyStrong
                                              .copyWith(color: p.ink)),
                                      Text('$dueCount kartu jatuh tempo',
                                          style: AppText.caption
                                              .copyWith(color: p.secondary)),
                                    ]),
                              ),
                              AppIcon(AppIcons.chevronRight,
                                  color: p.inkSubtle),
                            ]),
                          ),
                        ),
                      ),
                    ],
                    if (showBackup) ...[
                      const SizedBox(height: Sp.x3),
                      Container(
                        padding: const EdgeInsets.fromLTRB(
                            Sp.x4, Sp.x3, Sp.x2, Sp.x3),
                        decoration: BoxDecoration(
                            color: p.surfaceAlt, borderRadius: Radii.mdAll),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                              'Simpan cadangan progres agar tidak hilang saat ganti HP.',
                              style: AppText.bodySm.copyWith(color: p.ink),
                            ),
                          ),
                          TextButton(
                              onPressed: () => context.push('/settings'),
                              child: const Text('Backup')),
                        ]),
                      ),
                    ],
                    const SizedBox(height: Sp.x3),
                    _CardBox(
                      child: InkWell(
                        borderRadius: Radii.lgAll,
                        onTap: () => context.push('/intro'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Sp.x4, vertical: Sp.x3),
                          child: Row(children: [
                            _BookTile(text: '本', primary: false),
                            const SizedBox(width: Sp.x3),
                            Expanded(
                              child: Text('はじめに · Panduan',
                                  style: AppText.bodyStrong),
                            ),
                            AppIcon(AppIcons.chevronRight, color: p.inkSubtle),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: Sp.x2),
                    const _KanaExpandableCard(),
                    const SizedBox(height: Sp.x6),
                    Row(children: [
                      Text('Bab', style: AppText.headline),
                      const Spacer(),
                      Text(
                        'Progres $pct% · $started dari $total dimulai',
                        style: AppText.bodySm.copyWith(color: p.inkMuted),
                      ),
                    ]),
                    const SizedBox(height: Sp.x3),
                    _CardBox(
                      child: Column(children: [
                        for (var i = 0; i < manifest.sequence.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, thickness: 1, color: p.border),
                          _SequenceRow(
                              item: manifest.sequence[i], manifest: manifest),
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
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.lastOpened, required this.lesson1});
  final LastOpened? lastOpened;
  final LessonMeta? lesson1;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = lastOpened;
    if (last == null) {
      return _CardBox(
        child: Padding(
          padding: const EdgeInsets.all(Sp.x4),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('MULAI BELAJAR',
                style: AppText.overline.copyWith(color: p.inkMuted)),
            const SizedBox(height: Sp.x1),
            if (lesson1 != null)
              Row(children: [
                Text('Bab 1 · ', style: AppText.headline),
                Expanded(
                    child: JpLabel(lesson1!.titleJp, style: AppText.headline)),
              ])
            else
              Text('Bab 1', style: AppText.headline),
            const SizedBox(height: Sp.x4),
            FilledButton(
              onPressed: () => context.push('/lesson/1'),
              child: const Text('Mulai Bab 1'),
            ),
          ]),
        ),
      );
    }

    return _CardBox(
      child: Padding(
        padding: const EdgeInsets.all(Sp.x4),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: p.primarySubtle, borderRadius: Radii.mdAll),
              alignment: Alignment.center,
              child: Text(
                _tileForRoute(last.route),
                style: AppText.brushHero
                    .copyWith(fontSize: 28, color: p.primaryStrong),
              ),
            ),
            const SizedBox(width: Sp.x4),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LANJUTKAN',
                        style: AppText.overline.copyWith(color: p.inkMuted)),
                    const SizedBox(height: Sp.x1),
                    Text(last.label,
                        style: AppText.headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(_relativeTime(last.at),
                        style: AppText.caption.copyWith(color: p.inkMuted)),
                  ]),
            ),
          ]),
          const SizedBox(height: Sp.x4),
          FilledButton(
            onPressed: () => context.push(last.route),
            child: const Text(S.continueLabel),
          ),
        ]),
      ),
    );
  }
}

class _SequenceRow extends ConsumerWidget {
  const _SequenceRow({required this.item, required this.manifest});
  final SequenceItem item;
  final BookManifest manifest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    if (item.type == 'lesson') {
      final n = item.lesson!;
      final meta = manifest.lesson(n);
      final lp = ref.watch(lessonProgressProvider(n));
      final sub = lp != null && lp.started
          ? '${lp.sectionsDone} dari ${lp.sectionsTotal} bagian'
          : '${meta?.sections.length ?? 0} bagian';
      return InkWell(
        onTap: () => context.push('/lesson/$n'),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
          child: Row(children: [
            SizedBox(
              width: 32,
              child:
                  Text('$n', style: AppText.brushNo.copyWith(color: p.primary)),
            ),
            const SizedBox(width: Sp.x3),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meta != null)
                      JpLabel(meta.titleJp,
                          style: AppText.jpSm(1)
                              .copyWith(fontWeight: FontWeight.w600)),
                    Text(sub,
                        style: AppText.bodySm.copyWith(color: p.inkMuted)),
                  ]),
            ),
            const SizedBox(width: Sp.x3),
            ProgressRing(value: lp?.fraction ?? 0),
          ]),
        ),
      );
    }

    final id = item.id ?? '';
    return ColoredBox(
      color: p.surfaceAlt,
      child: InkWell(
        onTap: () => context.push('/ms/$id'),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
          child: Row(children: [
            _BookTile(text: item.type == 'matome' ? 'ま' : '復', primary: false),
            const SizedBox(width: Sp.x3),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.titleJp != null)
                      JpLabel(item.titleJp!,
                          style: AppText.jpSm(1)
                              .copyWith(fontWeight: FontWeight.w600)),
                    if (item.subtitle != null)
                      Text(item.subtitle!,
                          style: AppText.bodySm.copyWith(color: p.inkMuted)),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 2),
              decoration: BoxDecoration(
                  color: p.secondarySubtle, borderRadius: Radii.fullAll),
              child: Text('Ulangan',
                  style: AppText.caption.copyWith(color: p.secondary)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CardBox extends StatelessWidget {
  const _CardBox({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _KanaExpandableCard extends StatefulWidget {
  const _KanaExpandableCard();

  @override
  State<_KanaExpandableCard> createState() => _KanaExpandableCardState();
}

class _KanaExpandableCardState extends State<_KanaExpandableCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _CardBox(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Sp.x4, vertical: Sp.x3),
              child: Row(children: [
                const _BookTile(text: 'あ', primary: true),
                const SizedBox(width: Sp.x3),
                Expanded(
                  child: Text('はじめに · Huruf & pelafalan',
                      style: AppText.bodyStrong),
                ),
                AppIcon(
                  _open ? AppIcons.chevronDown : AppIcons.chevronRight,
                  color: p.inkSubtle,
                ),
              ]),
            ),
          ),
          if (_open) ...[
            Divider(height: 1, thickness: 1, color: p.border),
            _subRow(context, 'あ', 'Hiragana', '/kana/hira', p),
            Divider(height: 1, thickness: 1, color: p.border),
            _subRow(context, 'ア', 'Katakana', '/kana/kata', p),
          ],
        ],
      ),
    );
  }

  Widget _subRow(BuildContext context, String glyph, String label, String route,
      AppPalette p) {
    return InkWell(
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        child: Row(children: [
          const SizedBox(width: Sp.x2),
          SizedBox(
            width: 32,
            child: Text(glyph,
                textAlign: TextAlign.center,
                style: AppText.brushTile.copyWith(color: p.primary)),
          ),
          const SizedBox(width: Sp.x3),
          Expanded(child: Text(label, style: AppText.body)),
          AppIcon(AppIcons.chevronRight, color: p.inkSubtle),
        ]),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.text, required this.primary});
  final String text;
  final bool primary;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: Sizes.tile,
      height: Sizes.tile,
      decoration: BoxDecoration(
        color: primary ? p.primarySubtle : p.secondarySubtle,
        borderRadius: Radii.mdAll,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: AppText.brushTile
            .copyWith(color: primary ? p.primaryStrong : p.secondary),
      ),
    );
  }
}

String _tileForRoute(String route) {
  for (final e in S.sectionTile.entries) {
    if (route.contains('/${e.key}')) return e.value;
  }
  return '課';
}

String _relativeTime(DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(at.year, at.month, at.day);
  final diff = today.difference(date).inDays;
  if (diff <= 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  if (diff < 30) return '$diff hari lalu';
  final d = at.day.toString().padLeft(2, '0');
  final m = at.month.toString().padLeft(2, '0');
  return '$d/$m/${at.year}';
}
