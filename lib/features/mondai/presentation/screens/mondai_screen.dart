import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_route.dart';
import '../../../../services/audio_service/domain/providers/audio_controller.dart';
import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/lesson.dart';
import '../../../../shared/domain/models/mondaishuu.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/audio_widgets.dart';
import '../../../../shared/widgets/book_image.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/kana_text_field.dart';
import '../../../../shared/widgets/section_scaffold.dart';
import '../../../ai_assist/data/datasource/ai_key_store.dart';
import '../../../ai_assist/domain/providers/ai_session.dart';
import '../../../ai_assist/domain/repositories/ai_prompts.dart';
import '../../../ai_assist/presentation/widgets/ai_panel.dart';
import '../../../bunkei_reibun/presentation/screens/bunkei_screen.dart';

const _circled = ['①', '②', '③', '④', '⑤', '⑥'];

class MondaiScreen extends ConsumerStatefulWidget {
  const MondaiScreen({super.key, required this.lesson, required this.no});
  final int lesson;
  final int no;

  @override
  ConsumerState<MondaiScreen> createState() => _MondaiScreenState();
}

class _MondaiScreenState extends ConsumerState<MondaiScreen> {
  late final AudioController _audio =
      ref.read(audioControllerProvider.notifier);
  String? _openedAudio;

  @override
  void dispose() {
    _audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lessonAsync = ref.watch(lessonProvider(widget.lesson));
    final manifest = ref.watch(manifestProvider).valueOrNull;
    final audio = ref.watch(audioControllerProvider);
    ref.watch(userDataProvider.select((u) => u.answers));
    final ud = ref.read(userDataProvider.notifier);
    final aiOn = ref.watch(aiEnabledProvider).valueOrNull ?? false;

    return lessonAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(lessonProvider(widget.lesson))),
      ),
      data: (l) {
        final m = l.sections.mondai.where((x) => x.no == widget.no).firstOrNull;
        if (m == null) {
          return Scaffold(
              appBar: AppBar(), body: const ErrorView(message: S.loadError));
        }

        if (m.kind.isListening && m.audio != null && _openedAudio != m.audio) {
          _openedAudio = m.audio;
          Future.microtask(() => _audio.open(m.audio!));
        }

        final secMeta = manifest?.lesson(widget.lesson)?.section('mondai');
        final nums =
            secMeta?.numbers ?? [for (final x in l.sections.mondai) x.no];
        final audioNums = secMeta?.audioNumbers ?? const <int>[];
        final idx = nums.indexOf(widget.no);
        final prevNo = idx > 0 ? nums[idx - 1] : null;
        final nextNo = idx >= 0 && idx + 1 < nums.length ? nums[idx + 1] : null;
        final msSet =
            _msForLesson(manifest?.mondaishuu ?? const [], widget.lesson);
        final cdLabel = (m.cdTrack ?? '').replaceAll('CD', '');

        return SectionScaffold(
          title: '${S.sectionJp['mondai']} ${S.sectionNames['mondai']}',
          subtitle: '${S.lesson} ${widget.lesson} · ${S.number} ${widget.no}',
          lesson: widget.lesson,
          doneRef: '${l.id}.mondai.${widget.no}',
          trackRoute: '/lesson/${widget.lesson}/mondai/${widget.no}',
          trackLabel:
              '${S.lesson} ${widget.lesson} · ${S.sectionNames['mondai']} · ${S.number} ${widget.no}',
          showModeToggle: true,
          showGrammar: true,
          showAudioSettings: m.kind.isListening,
          bottomBar: NumberNavBar(
            prevRoute: prevNo != null
                ? sectionRoute(widget.lesson, 'mondai', no: prevNo)
                : null,
            nextRoute: nextNo != null
                ? sectionRoute(widget.lesson, 'mondai', no: nextNo)
                : null,
            nextLabel: '${S.number} ${nextNo ?? widget.no + 1}',
          ),
          body: (ctx, _) => [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < nums.length; i++) ...[
                  if (i > 0) const SizedBox(width: Sp.x2),
                  _numTab(
                    x: nums[i],
                    active: nums[i] == widget.no,
                    hasAudio: audioNums.contains(nums[i]),
                    p: p,
                    onTap: () => context.pushReplacement(
                        sectionRoute(widget.lesson, 'mondai', no: nums[i])),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: Sp.x4),
            if (m.kind.isListening) ...[
              SegmentPlayer(
                  mondai: m, title: 'CD $cdLabel · Mondai ${widget.no}'),
              const SizedBox(height: Sp.x4),
            ],
            if (m.image != null) ...[
              BookImage(m.image!),
              const SizedBox(height: Sp.x4),
            ],
            if (m.instructionJp != null) ...[
              Container(
                padding: const EdgeInsets.all(Sp.x3),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: Radii.mdAll,
                  border: Border.all(color: p.border),
                ),
                child: JpTextView(m.instructionJp!),
              ),
              const SizedBox(height: Sp.x4),
            ],
            if (m.passageJp.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(Sp.x4),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: Radii.mdAll,
                  border: Border.all(color: p.border),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (m.passageTitleJp != null) ...[
                        JpTextView(m.passageTitleJp!, textAlign: TextAlign.end),
                        const SizedBox(height: Sp.x3),
                      ],
                      for (var i = 0; i < m.passageJp.length; i++) ...[
                        if (i > 0) const SizedBox(height: Sp.x3),
                        JpTextView(m.passageJp[i]),
                      ],
                    ]),
              ),
              const SizedBox(height: Sp.x4),
            ],
            if (m.examples.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(Sp.x4),
                decoration: BoxDecoration(
                    color: p.secondarySubtle, borderRadius: Radii.lgAll),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < m.examples.length; i++) ...[
                        if (i > 0) const SizedBox(height: Sp.x4),
                        _exampleBlock(m, i, p),
                      ],
                    ]),
              ),
              const SizedBox(height: Sp.x4),
            ],
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: Radii.lgAll,
                border: Border.all(color: p.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (var i = 0; i < m.questions.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: p.border),
                  _questionRow(m, i, audio, ud, p),
                ],
              ]),
            ),
            const SizedBox(height: Sp.x4),
            Container(
              padding: const EdgeInsets.all(Sp.x3),
              decoration: BoxDecoration(
                borderRadius: Radii.mdAll,
                border: Border.all(color: p.border),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AppIcon(AppIcons.info, size: 18, color: p.inkMuted),
                const SizedBox(width: Sp.x2),
                Expanded(
                    child: Text(S.noKeyMondai,
                        style: AppText.bodySm.copyWith(color: p.inkMuted))),
              ]),
            ),
            if (aiOn || msSet != null) ...[
              const SizedBox(height: Sp.x3),
              Wrap(spacing: Sp.x3, runSpacing: Sp.x2, children: [
                if (aiOn)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.secondary,
                      side: BorderSide(color: p.secondary),
                    ),
                    onPressed: () {
                      final qText = m.questions
                          .map((q) =>
                              '${q.no ?? ''}) ${q.linesJp.map((e) => e.jp).join(' ')}')
                          .join('\n');
                      final exText = m.examples
                          .map((e) =>
                              '${e.labelJp.jp}: ${e.linesJp.map((l) => l.jp).join(' ')} ${e.answer ?? ''}')
                          .join('\n');
                      showAiPanel(
                        context,
                        AiRequest(
                          action: AiAction.exampleAnswer,
                          lesson: widget.lesson,
                          refId: m.id,
                          target: qText,
                          bookContext: lessonBookContext(l, exText),
                        ),
                      );
                    },
                    child: const Text('✨ Contoh jawaban AI'),
                  ),
                if (msSet != null)
                  OutlinedButton(
                    onPressed: () => context.push('/ms/${msSet.id}'),
                    child: Text('Mondaishuu Bab ${widget.lesson}'),
                  ),
              ]),
            ],
            const SizedBox(height: Sp.x2),
            Center(
              child: TextButton(
                onPressed: () => ud.clearAnswers('${m.id}.'),
                child: const Text(S.clearAnswers),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _numTab({
    required int x,
    required bool active,
    required bool hasAudio,
    required AppPalette p,
    required VoidCallback onTap,
  }) {
    final fg = active ? p.onPlayer : p.ink;
    return Material(
      color: active ? p.player : p.surface,
      borderRadius: Radii.mdAll,
      child: InkWell(
        borderRadius: Radii.mdAll,
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: Sp.x3),
          decoration: BoxDecoration(
            borderRadius: Radii.mdAll,
            border: active ? null : Border.all(color: p.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('$x', style: AppText.bodyStrong.copyWith(color: fg)),
            if (hasAudio) ...[
              const SizedBox(width: Sp.x1),
              AppIcon(AppIcons.headphones, size: 16, color: fg),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _exampleBlock(Mondai m, int i, AppPalette p) {
    final ex = m.examples[i];
    final seg = m.kind.isListening ? m.exampleSegment(i) : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child: JpLabel(ex.labelJp,
                style: AppText.caption.copyWith(color: p.secondary))),
        if (seg != null) SegmentPlayButton(range: seg.t, tag: '${m.id}#ex$i'),
      ]),
      const SizedBox(height: Sp.x2),
      _exampleContent(m.kind, ex, p),
    ]);
  }

  Widget _exampleContent(MondaiKind kind, MondaiExample ex, AppPalette p) {
    switch (kind) {
      case MondaiKind.listenChoiceImage:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (ex.image != null) ...[
            BookImage(ex.image!),
            const SizedBox(height: Sp.x2),
          ],
          _staticNumberChips(ex.options ?? 3, ex.answer),
        ]);
      case MondaiKind.listenTrueFalse:
        return Text(ex.answer ?? '',
            style: AppText.title.copyWith(color: p.secondary));
      case MondaiKind.trueFalse:
        if (ex.image != null) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookImage(ex.image!),
                const SizedBox(height: Sp.x2),
                _staticNumberChips(ex.options ?? 2, ex.answer),
              ]);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(ex.answer ?? '',
              style: AppText.title.copyWith(color: p.secondary)),
          const SizedBox(width: Sp.x3),
          if (ex.linesJp.isNotEmpty) Expanded(child: JpTextView(ex.linesJp[0])),
        ]);
      case MondaiKind.listenChoice:
        return Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            for (final ln in ex.linesJp)
              ChoiceChip(
                label: JpLabel(ln),
                selected: ln.jp == ex.answer,
                onSelected: null,
              ),
          ],
        );
      case MondaiKind.listenWrite:
      case MondaiKind.fill:
      case MondaiKind.compose:
      case MondaiKind.write:
      case MondaiKind.choice:
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final ln in ex.linesJp) JpTextView(ln),
            ]);
    }
  }

  Widget _staticNumberChips(int count, String? answer) {
    return Wrap(
      spacing: Sp.x2,
      children: [
        for (var k = 1; k <= count; k++)
          ChoiceChip(
            label: Text(k <= _circled.length ? _circled[k - 1] : '$k'),
            selected: answer == '$k',
            onSelected: null,
          ),
      ],
    );
  }

  Widget _questionRow(
      Mondai m, int i, AudioState audio, UserDataNotifier ud, AppPalette p) {
    final q = m.questions[i];
    final seg = m.kind.isListening ? m.questionSegment(i) : null;
    final isActive = seg != null &&
        audio.playing &&
        audio.positionSec >= seg.t.start - 0.05 &&
        audio.positionSec < seg.t.end + 0.3;

    return Container(
      color: isActive ? p.highlightBg : null,
      padding: const EdgeInsets.symmetric(horizontal: Sp.x4, vertical: Sp.x3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (seg != null) ...[
          SegmentPlayButton(range: seg.t, tag: '${m.id}#q$i'),
          const SizedBox(width: Sp.x2),
        ],
        if (q.no != null)
          SizedBox(
            width: 28,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${q.no})',
                  style: AppText.bodyStrong.copyWith(color: p.inkMuted)),
            ),
          ),
        Expanded(child: _questionInput(m.kind, q, ud)),
      ]),
    );
  }

  Widget _questionInput(
      MondaiKind kind, MondaiQuestion q, UserDataNotifier ud) {
    switch (kind) {
      case MondaiKind.listenWrite:
        final key = '${q.id}#0';
        return KanaTextField(
          initial: ud.answer(key) ?? '',
          onChanged: (v) => ud.setAnswer(key, v),
          hint: S.typeAnswer,
        );
      case MondaiKind.listenChoiceImage:
        final key = '${q.id}#0';
        final current = ud.answer(key);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (q.image != null) ...[
            BookImage(q.image!),
            const SizedBox(height: Sp.x2),
          ],
          _numberChoiceChips(
              q.options ?? 3, current, (v) => ud.setAnswer(key, v)),
        ]);
      case MondaiKind.listenTrueFalse:
        final key = '${q.id}#0';
        return _tfChips(ud.answer(key), (v) => ud.setAnswer(key, v));
      case MondaiKind.trueFalse:
        final key = '${q.id}#0';
        if (q.image != null) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookImage(q.image!),
                const SizedBox(height: Sp.x2),
                _numberChoiceChips(q.options ?? 2, ud.answer(key),
                    (v) => ud.setAnswer(key, v)),
              ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (q.linesJp.isNotEmpty) ...[
            JpTextView(q.linesJp[0]),
            const SizedBox(height: Sp.x2),
          ],
          _tfChips(ud.answer(key), (v) => ud.setAnswer(key, v)),
        ]);
      case MondaiKind.listenChoice:
        final key = '${q.id}#0';
        final current = ud.answer(key);
        return Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            for (final c in q.choicesJp)
              ChoiceChip(
                label: JpLabel(c),
                selected: current == c.jp,
                onSelected: (_) => ud.setAnswer(key, c.jp),
              ),
          ],
        );
      case MondaiKind.fill:
      case MondaiKind.compose:
      case MondaiKind.write:
        var offset = 0;
        final w = kind == MondaiKind.write ? 220.0 : 96.0;
        final widgets = <Widget>[];
        for (final ln in q.linesJp) {
          final lineOffset = offset;
          widgets.add(JpTextView(
            ln,
            blankIndexOffset: lineOffset,
            blankBuilder: (c, idx) {
              final k = '${q.id}#$idx';
              return KanaTextField(
                width: w,
                initial: ud.answer(k) ?? '',
                onChanged: (v) => ud.setAnswer(k, v),
              );
            },
          ));
          offset += ln.tokens.where((t) => t.blank).length;
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: widgets);
      case MondaiKind.choice:
        final groups = q.choiceGroups;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final ln in q.linesJp) JpTextView(ln),
          for (var g = 0; g < groups.length; g++) ...[
            const SizedBox(height: Sp.x2),
            if (groups.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: Sp.x1),
                child: Text('(${g + 1})', style: AppText.caption),
              ),
            Wrap(
              spacing: Sp.x2,
              runSpacing: Sp.x2,
              children: [
                for (final c in groups[g])
                  ChoiceChip(
                    label: JpLabel(c),
                    selected: ud.answer('${q.id}#$g') == c.jp,
                    onSelected: (_) => ud.setAnswer('${q.id}#$g', c.jp),
                  ),
              ],
            ),
          ],
        ]);
    }
  }

  Widget _numberChoiceChips(
      int count, String? current, ValueChanged<String> onPick) {
    return Wrap(
      spacing: Sp.x2,
      children: [
        for (var k = 1; k <= count; k++)
          ChoiceChip(
            label: Text(k <= _circled.length ? _circled[k - 1] : '$k'),
            selected: current == '$k',
            onSelected: (_) => onPick('$k'),
          ),
      ],
    );
  }

  Widget _tfChips(String? current, ValueChanged<String> onPick) {
    return Wrap(
      spacing: Sp.x2,
      children: [
        for (final sym in const ['○', '×'])
          ChoiceChip(
            label: Text(sym),
            selected: current == sym,
            onSelected: (_) => onPick(sym),
          ),
      ],
    );
  }
}

MondaishuuMeta? _msForLesson(List<MondaishuuMeta> list, int lesson) {
  for (final m in list) {
    if (m.lessons.contains(lesson)) return m;
  }
  return null;
}
