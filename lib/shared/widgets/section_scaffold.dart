// Kerangka layar konten bab (docs/05_Spesifikasi_Layar.md §K-1, K-2).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/progress_service/domain/providers/user_data_provider.dart';
import '../domain/providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/text_theme.dart';
import '../utils/strings.dart';
import 'app_icon.dart';
import 'audio_widgets.dart';
import 'content_blocks.dart';
import 'mode_toggle.dart';

/// [body] menerima `showTr` (status tombol terjemahan semua baris).
/// [doneRef] diisi → bagian otomatis ditandai selesai saat digulir sampai bawah + tombol DoneFooter.
/// [floating] widget menempel di bawah (mis. MiniPlayer). Body diberi padding bawah 112 jika ada.
/// [bottomBar] mis. NumberNavBar.
class SectionScaffold extends ConsumerStatefulWidget {
  const SectionScaffold({
    super.key,
    required this.title,
    required this.lesson,
    required this.body,
    this.subtitle,
    this.doneRef,
    this.trackRoute,
    this.trackLabel,
    this.showModeToggle = true,
    this.showTranslationToggle = false,
    this.showAudioSettings = false,
    this.showGrammar = false,
    this.floating,
    this.bottomBar,
    this.scrollController,
  });

  final String title; // mis. "会話 Kaiwa"
  final String? subtitle; // default "Bab N"
  final int lesson;
  final List<Widget> Function(BuildContext context, bool showTr) body;
  final String? doneRef;
  final String? trackRoute; // route untuk tombol Lanjutkan
  final String? trackLabel; // label tombol Lanjutkan, mis. "Bab 1 · Kaiwa"
  final bool showModeToggle;
  final bool showTranslationToggle;
  final bool showAudioSettings;
  final bool showGrammar;
  final Widget? floating;
  final Widget? bottomBar;
  final ScrollController? scrollController;

  @override
  ConsumerState<SectionScaffold> createState() => _SectionScaffoldState();
}

class _SectionScaffoldState extends ConsumerState<SectionScaffold> {
  late bool _showTr;
  bool _autoDone = false;

  @override
  void initState() {
    super.initState();
    _showTr = ref.read(settingsProvider).showTranslation;
    final r = widget.trackRoute, l = widget.trackLabel;
    if (r != null && l != null) {
      Future.microtask(() => ref.read(userDataProvider.notifier).setLastOpened(r, l));
    }
  }

  bool _onScroll(ScrollNotification n) {
    final ref0 = widget.doneRef;
    if (ref0 != null && !_autoDone && n.metrics.extentAfter < 24 && n.metrics.maxScrollExtent >= 0) {
      _autoDone = true;
      if (!ref.read(userDataProvider).done.contains(ref0)) ref.read(userDataProvider.notifier).setDone(ref0, true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final children = [
      ...widget.body(context, _showTr),
      if (widget.doneRef != null) ...[const SizedBox(height: Sp.x6), DoneFooter(refId: widget.doneRef!)],
      SizedBox(height: widget.floating != null ? 112 : Sp.x8),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: AppIcon(AppIcons.arrowLeft, color: p.ink),
        ),
        titleSpacing: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title, style: AppText.headline.copyWith(fontFamilyFallback: const ['NotoSansJP'])),
          Text(widget.subtitle ?? '${S.lesson} ${widget.lesson}', style: AppText.caption.copyWith(color: p.inkMuted)),
        ]),
        actions: [
          if (widget.showModeToggle) const Padding(padding: EdgeInsets.only(right: Sp.x1), child: ModeToggle()),
          if (widget.showTranslationToggle)
            IconButton(
              tooltip: _showTr ? S.hideTranslation : S.showTranslation,
              onPressed: () => setState(() => _showTr = !_showTr),
              icon: AppIcon(AppIcons.translate, color: _showTr ? p.secondary : p.ink),
            ),
          if (widget.showGrammar)
            IconButton(
              tooltip: S.grammarPanel,
              onPressed: () => showGrammarSheet(context, widget.lesson),
              icon: AppIcon(AppIcons.book, color: p.ink),
            ),
          if (widget.showAudioSettings)
            IconButton(
              tooltip: 'Pengaturan audio',
              onPressed: () => showAudioSettingsSheet(context),
              icon: AppIcon(AppIcons.headphones, color: p.ink),
            ),
          const SizedBox(width: Sp.x1),
        ],
      ),
      bottomNavigationBar: widget.bottomBar,
      body: SafeArea(
        top: false,
        bottom: widget.bottomBar == null,
        child: Stack(children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(Sp.screen, Sp.x2, Sp.screen, 0),
                  children: children,
                ),
              ),
            ),
          ),
          if (widget.floating != null)
            Positioned(left: Sp.x3, right: Sp.x3, bottom: Sp.x4, child: widget.floating!),
        ]),
      ),
    );
  }
}

/// Tombol "Tandai selesai" / "Batalkan selesai" di akhir konten.
class DoneFooter extends ConsumerWidget {
  const DoneFooter({super.key, required this.refId});
  final String refId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final done = ref.watch(userDataProvider.select((u) => u.done.contains(refId)));
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => ref.read(userDataProvider.notifier).setDone(refId, !done),
        icon: AppIcon(done ? AppIcons.checkCircle : AppIcons.check, size: 18, color: done ? p.success : p.ink),
        label: Text(done ? S.markUndone : S.markDone),
      ),
    );
  }
}

/// Bar bawah ‹ Sebelumnya | Berikutnya ›. Rute null = tombol nonaktif.
class NumberNavBar extends StatelessWidget {
  const NumberNavBar({super.key, this.prevRoute, this.nextRoute, required this.nextLabel});
  final String? prevRoute;
  final String? nextRoute;
  final String nextLabel; // mis. "Nomor 2"
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(color: p.bg, border: Border(top: BorderSide(color: p.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Sp.screen, Sp.x3, Sp.screen, Sp.x3),
          child: Row(children: [
            SizedBox(
              width: 52,
              height: Sizes.button,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: prevRoute == null ? null : () => context.pushReplacement(prevRoute!),
                child: AppIcon(AppIcons.chevronLeft, color: prevRoute == null ? p.inkSubtle : p.ink),
              ),
            ),
            const SizedBox(width: Sp.x3),
            Expanded(
              child: FilledButton(
                onPressed: nextRoute == null ? () => context.pop() : () => context.pushReplacement(nextRoute!),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(nextRoute == null ? S.done : nextLabel),
                  const SizedBox(width: Sp.x2),
                  if (nextRoute != null) AppIcon(AppIcons.arrowRight, size: 20, color: p.onPrimary),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
