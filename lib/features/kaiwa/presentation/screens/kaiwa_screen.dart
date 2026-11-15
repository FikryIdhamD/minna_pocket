import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/audio_service/domain/providers/audio_controller.dart';
import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../shared/domain/models/lesson.dart';
import '../../../../shared/domain/providers/settings_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/audio_widgets.dart';
import '../../../../shared/widgets/book_image.dart';
import '../../../../shared/widgets/jp_actions.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/section_scaffold.dart';
import '../../../ai_assist/domain/providers/ai_session.dart';
import '../../../ai_assist/domain/repositories/ai_prompts.dart';
import '../../../bunkei_reibun/presentation/screens/bunkei_screen.dart';

class KaiwaScreen extends ConsumerStatefulWidget {
  const KaiwaScreen({super.key, required this.lesson});
  final int lesson;

  @override
  ConsumerState<KaiwaScreen> createState() => _KaiwaScreenState();
}

class _KaiwaScreenState extends ConsumerState<KaiwaScreen> {
  late final AudioController _audio =
      ref.read(audioControllerProvider.notifier);
  final ScrollController _scrollController = ScrollController();
  final Set<String> _openTr = {};
  final List<GlobalKey> _lineKeys = [];
  bool _openedAudio = false;
  int _lastActiveIdx = -1;

  @override
  void dispose() {
    _audio.stop();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lessonAsync = ref.watch(lessonProvider(widget.lesson));
    final audio = ref.watch(audioControllerProvider);
    final autoScroll =
        ref.watch(settingsProvider.select((s) => s.kaiwaAutoScroll));

    return lessonAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(lessonProvider(widget.lesson))),
      ),
      data: (l) {
        final kaiwa = l.sections.kaiwa;
        if (kaiwa == null)
          return Scaffold(
              appBar: AppBar(), body: const ErrorView(message: S.loadError));

        if (!_openedAudio) {
          _openedAudio = true;
          Future.microtask(() => _audio.open(kaiwa.audio));
        }

        while (_lineKeys.length < kaiwa.lines.length) {
          _lineKeys.add(GlobalKey());
        }

        var activeIdx = -1;
        for (var i = 0; i < kaiwa.lines.length; i++) {
          final t = kaiwa.lines[i].t;
          if (t != null &&
              ((audio.playing && t.contains(audio.positionSec)) ||
                  (audio.loop && audio.range == t))) {
            activeIdx = i;
            break;
          }
        }
        if (autoScroll && activeIdx != -1 && activeIdx != _lastActiveIdx) {
          _lastActiveIdx = activeIdx;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final ctx = _lineKeys[activeIdx].currentContext;
            if (ctx != null) {
              Scrollable.ensureVisible(ctx,
                  alignment: 0.35, duration: const Duration(milliseconds: 250));
            }
          });
        } else if (activeIdx == -1) {
          _lastActiveIdx = -1;
        }

        final ctxText = lessonBookContext(l);
        final cdLabel = (kaiwa.cdTrack ?? '').replaceAll('CD', '');

        return SectionScaffold(
          title: '${S.sectionJp['kaiwa']} ${S.sectionNames['kaiwa']}',
          lesson: widget.lesson,
          doneRef: '${l.id}.kaiwa',
          trackRoute: '/lesson/${widget.lesson}/kaiwa',
          trackLabel:
              '${S.lesson} ${widget.lesson} · ${S.sectionNames['kaiwa']}',
          showModeToggle: true,
          showTranslationToggle: true,
          showAudioSettings: true,
          scrollController: _scrollController,
          floating: MiniPlayer(title: 'CD $cdLabel · Kaiwa'),
          body: (ctx, showTr) => [
            JpTextView(kaiwa.titleJp, size: JpSize.title),
            const SizedBox(height: 2),
            Text(kaiwa.titleTr,
                style: AppText.bodySm.copyWith(color: p.secondary)),
            const SizedBox(height: Sp.x3),
            BookImage(kaiwa.image),
            const SizedBox(height: Sp.x3),
            Text(
              'Tekan kanji untuk furigana · ketuk baris untuk memutar dari situ · tekan lama untuk menu',
              style: AppText.caption.copyWith(color: p.inkSubtle),
            ),
            const SizedBox(height: Sp.x3),
            for (var i = 0; i < kaiwa.lines.length; i++) ...[
              if (kaiwa.lines[i].breakBefore)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sp.x2),
                  child: Divider(
                      height: 1, thickness: 1, color: p.border, indent: 56),
                ),
              _buildLine(
                context,
                kaiwa: kaiwa,
                line: kaiwa.lines[i],
                index: i,
                isActive: i == activeIdx,
                showTrAll: showTr,
                audio: audio,
                ctxText: ctxText,
                p: p,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLine(
    BuildContext context, {
    required Kaiwa kaiwa,
    required DialogLine line,
    required int index,
    required bool isActive,
    required bool showTrAll,
    required AudioState audio,
    required String ctxText,
    required AppPalette p,
  }) {
    final key = line.id ?? '${kaiwa.id}#$index';
    final trVisible = (showTrAll || _openTr.contains(key)) && line.tr != null;
    return GestureDetector(
      key: _lineKeys[index],
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (audio.loop) _audio.stopLoop();
        if (line.t != null) _audio.playFrom(line.t!);
        setState(() => _openTr.add(key));
      },
      onLongPress: () => showJpActions(
        context,
        text: line.jp,
        refId: key,
        kind: 'kalimat',
        label: line.jp.jp,
        ai: AiRequest(
          action: AiAction.explainSentence,
          lesson: widget.lesson,
          refId: key,
          target: line.jp.jp,
          bookContext: ctxText,
        ),
        extra: [
          if (line.t != null)
            JpExtraAction(
              icon: AppIcons.repeatOne,
              label: 'Ulangi baris ini terus',
              onTap: () {
                _audio.loopRange(line.t!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Mengulang baris ini. Ketuk ⏸ untuk berhenti.')),
                );
              },
            ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: Sp.x2, horizontal: Sp.x3),
        decoration: BoxDecoration(
          color: isActive ? p.highlightBg : null,
          borderRadius: Radii.mdAll,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 56,
            child: line.turnStart && line.speakerJp != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: JpLabel(line.speakerJp!,
                        style: AppText.jpSm(1).copyWith(color: p.inkMuted)),
                  )
                : null,
          ),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JpTextView(line.jp),
                  if (trVisible) ...[
                    const SizedBox(height: Sp.x1),
                    Text(line.tr!,
                        style: AppText.bodySm.copyWith(color: p.secondary)),
                  ],
                ]),
          ),
        ]),
      ),
    );
  }
}
