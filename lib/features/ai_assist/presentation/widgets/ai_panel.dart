// Panel ✨ AI (bottom sheet). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH. (docs/07_Fitur_AI.md §5)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../domain/providers/ai_session.dart';
import '../../domain/repositories/ai_prompts.dart';

Future<void> showAiPanel(BuildContext context, AiRequest req) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(heightFactor: 0.85, child: _AiPanel(req: req)),
    );

class _AiPanel extends ConsumerStatefulWidget {
  const _AiPanel({required this.req});
  final AiRequest req;
  @override
  ConsumerState<_AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends ConsumerState<_AiPanel> {
  final _ctl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(aiSessionProvider.notifier).start(widget.req));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = ref.watch(aiSessionProvider);
    final n = ref.read(aiSessionProvider.notifier);
    final bubbles = <Widget>[];
    for (var i = 1; i < s.messages.length; i++) {
      final m = s.messages[i];
      bubbles.add(m.role == 'assistant' ? _AiBubble(text: m.text) : _UserBubble(text: m.text));
    }
    if (s.loading) bubbles.add(_AiBubble(text: s.streaming.isEmpty ? '…' : s.streaming));
    if (s.error != null) {
      bubbles.add(Padding(
        padding: const EdgeInsets.only(top: Sp.x3),
        child: Row(children: [
          AppIcon(AppIcons.alert, size: 18, color: p.danger),
          const SizedBox(width: Sp.x2),
          Expanded(child: Text(s.error!, style: AppText.body.copyWith(color: p.danger))),
          TextButton(onPressed: n.refresh, child: const Text(S.retry)),
        ]),
      ));
    }
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.screen, 0, Sp.x2, Sp.x2),
          child: Row(children: [
            AppIcon(AppIcons.sparkles, size: 20, color: p.secondary),
            const SizedBox(width: Sp.x2),
            Expanded(child: Text(aiActionLabel(widget.req.action), style: AppText.headline)),
            if (!s.loading)
              IconButton(tooltip: S.aiRefresh, onPressed: n.refresh, icon: AppIcon(AppIcons.reset, size: 20, color: p.inkMuted)),
            IconButton(tooltip: S.close, onPressed: () => Navigator.pop(context), icon: AppIcon(AppIcons.close, color: p.inkMuted)),
          ]),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: Sp.screen),
          padding: const EdgeInsets.symmetric(horizontal: Sp.x3, vertical: Sp.x2),
          decoration: BoxDecoration(color: p.secondarySubtle, borderRadius: Radii.smAll),
          child: Text(S.aiLabel, style: AppText.caption.copyWith(color: p.secondary)),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(Sp.screen), children: bubbles),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Sp.screen, Sp.x2, Sp.x2, Sp.x3),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctl,
                  enabled: !s.loading,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: S.aiAskFollowUp),
                  onSubmitted: (_) => _send(n),
                ),
              ),
              IconButton(onPressed: s.loading ? null : () => _send(n), icon: AppIcon(AppIcons.arrowRight, color: p.primary)),
            ]),
          ),
        ),
      ]),
    );
  }

  void _send(AiSession n) {
    final t = _ctl.text;
    _ctl.clear();
    n.followUp(t);
  }
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onLongPress: () => Clipboard.setData(ClipboardData(text: text)),
      child: Container(
        margin: const EdgeInsets.only(bottom: Sp.x3),
        padding: const EdgeInsets.all(Sp.x4),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: Radii.mdAll,
          border: Border.all(color: p.secondary, width: 1.2),
        ),
        child: SelectableText(text, style: AppText.body.copyWith(color: p.ink, height: 1.55)),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: Sp.x3, left: Sp.x10),
        padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
        decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: Radii.mdAll),
        child: Text(text, style: AppText.body),
      ),
    );
  }
}
