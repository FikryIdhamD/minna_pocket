// Menu tekan-lama untuk teks/item buku: Ucapkan, Simpan ⭐, Salin, Tandai salah 🚩, ✨ AI.
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH. (docs/05_Spesifikasi_Layar.md §K-4)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/ai_assist/data/datasource/ai_key_store.dart';
import '../../features/ai_assist/domain/providers/ai_session.dart';
import '../../features/ai_assist/presentation/widgets/ai_panel.dart';
import '../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../services/tts_service/domain/providers/tts_service.dart';
import '../domain/models/jp_text.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/text_theme.dart';
import '../utils/strings.dart';
import 'app_icon.dart';

/// Aksi tambahan di bagian atas menu (mis. "Ulangi baris ini" di Kaiwa).
class JpExtraAction {
  const JpExtraAction({required this.icon, required this.label, required this.onTap});
  final String icon; // AppIcons.*
  final String label;
  final VoidCallback onTap;
}

/// [kind] untuk Tersimpan: "kalimat" | "kosakata" | "tata_bahasa" | "latihan" | "mondaishuu".
/// [ai] null = tidak ada tombol ✨.
Future<void> showJpActions(
  BuildContext context, {
  required JpText text,
  required String refId,
  required String kind,
  required String label,
  AiRequest? ai,
  List<JpExtraAction> extra = const [],
}) =>
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _JpActions(text: text, refId: refId, kind: kind, label: label, ai: ai, extra: extra),
    );

class _JpActions extends ConsumerWidget {
  const _JpActions({required this.text, required this.refId, required this.kind, required this.label, this.ai, this.extra = const []});
  final JpText text;
  final String refId, kind, label;
  final AiRequest? ai;
  final List<JpExtraAction> extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final saved = ref.watch(userDataProvider.select((u) => u.bookmarks.any((b) => b.ref == refId)));
    final aiOn = ref.watch(aiEnabledProvider).valueOrNull ?? false;
    Widget tile(String icon, String title, VoidCallback onTap, {String? sub, Color? color}) => ListTile(
          leading: AppIcon(icon, color: color ?? p.ink),
          title: Text(title, style: AppText.body.copyWith(color: color ?? p.ink)),
          subtitle: sub == null ? null : Text(sub, style: AppText.caption.copyWith(color: p.inkSubtle)),
          onTap: onTap,
        );
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Sp.screen, 0, Sp.screen, Sp.x2),
          child: Text(text.jp, style: AppText.jpSm(1).copyWith(color: p.inkMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        for (final e in extra)
          tile(e.icon, e.label, () {
            Navigator.pop(context);
            e.onTap();
          }),
        tile(AppIcons.speaker, S.speak, () {
          ref.read(ttsServiceProvider).speak(text.reading);
        }, sub: S.syntheticVoice),
        tile(AppIcons.star, saved ? S.bookmarkRemove : S.bookmarkAdd, () {
          ref.read(userDataProvider.notifier).toggleBookmark(ref: refId, kind: kind, label: label);
          Navigator.pop(context);
        }),
        tile(AppIcons.copy, S.copyText, () {
          Clipboard.setData(ClipboardData(text: text.jp));
          Navigator.pop(context);
        }),
        tile(AppIcons.flag, S.flagWrong, () async {
          await showFlagDialog(context, ref, refId: refId, text: text.jp);
          if (context.mounted) Navigator.pop(context);
        }),
        if (ai != null && aiOn)
          tile(AppIcons.sparkles, aiActionLabelFor(ai!), () {
            final rootContext = Navigator.of(context, rootNavigator: true).context;
            Navigator.pop(context);
            showAiPanel(rootContext, ai!);
          }, color: p.secondary),
      ]),
    );
  }
}

String aiActionLabelFor(AiRequest r) => '✨ ${r.action.name == 'explainSentence' ? 'Jelaskan kalimat ini' : 'Tanya AI'}';

Future<void> showFlagDialog(BuildContext context, WidgetRef ref, {required String refId, required String text}) async {
  final ctl = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text(S.flagWrong),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: AppText.jpSm(1)),
        const SizedBox(height: Sp.x3),
        TextField(controller: ctl, decoration: const InputDecoration(hintText: S.flagNoteHint), maxLines: 2),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(S.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text(S.save)),
      ],
    ),
  );
  if (ok == true) {
    ref.read(userDataProvider.notifier).addFlag(refId, text, ctl.text.trim());
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.flagSaved)));
  }
  ctl.dispose();
}
