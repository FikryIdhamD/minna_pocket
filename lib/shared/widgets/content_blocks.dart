// Penampil blok penjelasan (Tata Bahasa, Kata Referensi) + panel 📖 Tata Bahasa.
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH. (docs/05_Spesifikasi_Layar.md §K-5)

import 'package:flutter/material.dart' hide TableCell;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/content_service/domain/providers/content_providers.dart';
import '../domain/models/lesson.dart';
import '../domain/providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/text_theme.dart';
import 'async_view.dart';
import 'book_image.dart';
import 'jp_text_view.dart';

class ContentBlocksView extends StatelessWidget {
  const ContentBlocksView({super.key, required this.blocks, this.showTr = true});
  final List<ContentBlock> blocks;
  final bool showTr;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final b in blocks) Padding(padding: const EdgeInsets.only(bottom: Sp.x4), child: _block(context, b))],
      );

  Widget _block(BuildContext context, ContentBlock b) {
    final p = context.palette;
    switch (b.type) {
      case BlockType.h:
        return JpTextView(b.textRich!, size: JpSize.small, mode: DisplayMode.kana, color: p.ink);
      case BlockType.p:
        return JpTextView(b.textRich!, size: JpSize.small, mode: DisplayMode.kana, color: p.ink);
      case BlockType.note:
        return Container(
          padding: const EdgeInsets.all(Sp.x3),
          decoration: BoxDecoration(color: p.secondarySubtle, borderRadius: Radii.mdAll),
          child: JpTextView(b.textRich!, size: JpSize.small, mode: DisplayMode.kana, color: p.ink),
        );
      case BlockType.ex:
        return Container(
          padding: const EdgeInsets.all(Sp.x3),
          decoration: BoxDecoration(color: p.surface, borderRadius: Radii.mdAll, border: Border.all(color: p.border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (b.mark != null) Padding(padding: const EdgeInsets.only(right: Sp.x2, top: 6), child: Text(b.mark!, style: AppText.bodyStrong.copyWith(color: p.primaryStrong))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final l in b.lines) ...[
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (l.speakerJp != null) Padding(padding: const EdgeInsets.only(right: Sp.x2, top: 8), child: JpLabel(l.speakerJp!, style: AppText.jpSm(1).copyWith(color: p.inkMuted))),
                    Expanded(child: JpTextView(l.jp)),
                  ]),
                  for (final v in l.variantsJp) JpTextView(v, size: JpSize.small, color: p.inkMuted, interactive: false),
                  if (showTr && l.tr != null) Padding(padding: const EdgeInsets.only(bottom: Sp.x1), child: Text(l.tr!, style: AppText.bodySm.copyWith(color: p.secondary))),
                ],
              ]),
            ),
          ]),
        );
      case BlockType.table:
        return TableBlockView(block: b);
      case BlockType.image:
        return BookImage(b.image!, semanticLabel: b.caption);
    }
  }
}

class TableBlockView extends StatelessWidget {
  const TableBlockView({super.key, required this.block});
  final ContentBlock block;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget cell(TableCell c, {bool header = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: Sp.x2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final it in c.items) ...[
              if (it.jp != null) JpTextView(it.jp!, size: JpSize.small, mode: DisplayMode.kana),
              if (it.tr != null && it.tr!.isNotEmpty) Text(it.tr!, style: AppText.caption.copyWith(color: header ? p.inkMuted : p.secondary)),
            ],
          ]),
        );
    return Container(
      decoration: BoxDecoration(color: p.surface, borderRadius: Radii.mdAll, border: Border.all(color: p.border)),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder(horizontalInside: BorderSide(color: p.border), verticalInside: BorderSide(color: p.border)),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          if (block.header.isNotEmpty)
            TableRow(decoration: BoxDecoration(color: p.surfaceAlt), children: [for (final c in block.header) cell(c, header: true)]),
          for (final r in block.rows) TableRow(children: [for (final c in r) cell(c)]),
        ],
      ),
    );
  }
}

/// Panel 📖: semua poin Tata Bahasa bab [lesson] dalam bottom sheet.
Future<void> showGrammarSheet(BuildContext context, int lesson) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.85, child: _GrammarSheet(lesson: lesson)),
    );

class _GrammarSheet extends ConsumerWidget {
  const _GrammarSheet({required this.lesson});
  final int lesson;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return AsyncView<Lesson>(
      value: ref.watch(lessonProvider(lesson)),
      onRetry: () => ref.invalidate(lessonProvider(lesson)),
      data: (l) => ListView(
        padding: const EdgeInsets.fromLTRB(Sp.screen, 0, Sp.screen, Sp.x8),
        children: [
          Text('Tata Bahasa · Bab $lesson', style: AppText.headline),
          const SizedBox(height: Sp.x3),
          for (final b in l.sections.bunpou)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Row(children: [
                  Text('${b.no}. ', style: AppText.bodyStrong.copyWith(color: p.secondary)),
                  Expanded(child: JpTextView(b.titleRich, size: JpSize.small, mode: DisplayMode.kana, interactive: false)),
                ]),
                children: [ContentBlocksView(blocks: b.blocks)],
              ),
            ),
        ],
      ),
    );
  }
}
