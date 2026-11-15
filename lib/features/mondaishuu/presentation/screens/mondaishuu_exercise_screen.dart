import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/mondaishuu.dart';
import '../../../../shared/domain/models/user_data.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/answer_checker.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/book_image.dart';
import '../../../../shared/widgets/content_blocks.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/kana_text_field.dart';
import '../../../../shared/widgets/mode_toggle.dart';
import '../../../ai_assist/data/datasource/ai_key_store.dart';
import '../../../ai_assist/domain/providers/ai_session.dart';
import '../../../ai_assist/domain/repositories/ai_prompts.dart';
import '../../../ai_assist/presentation/widgets/ai_panel.dart';

class MondaishuuExerciseScreen extends ConsumerStatefulWidget {
  const MondaishuuExerciseScreen({
    super.key,
    required this.setId,
    required this.exNo,
    this.onlyWrong = false,
  });
  final String setId;
  final int exNo;
  final bool onlyWrong;

  @override
  ConsumerState<MondaishuuExerciseScreen> createState() =>
      _MondaishuuExerciseScreenState();
}

class _MondaishuuExerciseScreenState
    extends ConsumerState<MondaishuuExerciseScreen> {
  final Map<String, String> _input = {};
  final Map<String, BlankResult> _result = {};
  final Set<String> _revealed = {};
  final Set<String> _markedCorrect = {};
  bool _checked = false;
  bool _shuffled = false;
  bool _initialized = false;
  List<MsItem> _items = const [];

  void _initFromExercise(MsExercise ex) {
    if (_initialized) return;
    _initialized = true;
    final ud = ref.read(userDataProvider.notifier);
    final score = ref.read(userDataProvider).msScores[ex.id];
    final base = widget.onlyWrong && score != null
        ? ex.items.where((it) {
            final st = score.items[it.id];
            return st == ItemStatus.wrong || st == ItemStatus.assisted;
          }).toList()
        : List<MsItem>.from(ex.items);
    _items = base;
    for (final it in _items) {
      for (var k = 0; k < it.blanks.length; k++) {
        final key = '${it.id}#$k';
        final saved = ud.answer(key);
        if (saved != null && saved.isNotEmpty) {
          _input[key] = saved;
        }
      }
    }
  }

  void _toggleShuffle(MsExercise ex) {
    setState(() {
      _shuffled = !_shuffled;
      if (_shuffled) {
        _items = List<MsItem>.from(_items)..shuffle(Random());
      } else {
        final ids = {for (final it in _items) it.id};
        _items = ex.items.where((it) => ids.contains(it.id)).toList();
      }
    });
  }

  void _resetAll(MsExercise ex) {
    ref.read(userDataProvider.notifier).clearAnswers('${ex.id}.');
    setState(() {
      _input.clear();
      _result.clear();
      _revealed.clear();
      _markedCorrect.clear();
      _checked = false;
    });
  }

  void _check(MsExercise ex) {
    final ud = ref.read(userDataProvider.notifier);
    final nextRes = <String, BlankResult>{};
    final statuses = <String, ItemStatus>{};

    for (final it in _items) {
      var allOk = true;
      for (var k = 0; k < it.blanks.length; k++) {
        final key = '${it.id}#$k';
        final val = _input[key] ?? '';
        final r = checkBlank(it.blanks[k], val);
        nextRes[key] = r;
        if (r == BlankResult.wrong) {
          allOk = false;
        }
        ud.setAnswer(key, val);
      }
      if (it.autoGraded) {
        final ok = allOk || _markedCorrect.contains(it.id);
        statuses[it.id] = ok
            ? (_revealed.contains(it.id)
                ? ItemStatus.assisted
                : ItemStatus.correct)
            : ItemStatus.wrong;
      }
    }

    ud.recordMsAttempt(ex.id, statuses);
    setState(() {
      _result
        ..clear()
        ..addAll(nextRes);
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final setAsync = ref.watch(mondaishuuProvider(widget.setId));
    final aiOn = ref.watch(aiEnabledProvider).valueOrNull ?? false;

    return setAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const SkeletonList()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
            message: S.loadError,
            onRetry: () => ref.invalidate(mondaishuuProvider(widget.setId))),
      ),
      data: (set) {
        final ex = set.exercises.where((e) => e.no == widget.exNo).firstOrNull;
        if (ex == null) {
          return Scaffold(
              appBar: AppBar(), body: const ErrorView(message: S.loadError));
        }
        _initFromExercise(ex);

        final exIdx = set.exercises.indexWhere((e) => e.no == widget.exNo);
        final nextEx = exIdx >= 0 && exIdx + 1 < set.exercises.length
            ? set.exercises[exIdx + 1].no
            : null;
        final hasInput = _input.values.any((v) => v.trim().isNotEmpty);

        var gradedTotal = 0;
        var correctCount = 0;
        if (_checked) {
          for (final it in _items) {
            if (!it.autoGraded) continue;
            gradedTotal++;
            final ok = _markedCorrect.contains(it.id) ||
                List.generate(it.blanks.length,
                        (k) => _result['${it.id}#$k'] == BlankResult.correct)
                    .every((x) => x);
            if (ok) correctCount++;
          }
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Kembali',
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go('/ms/${widget.setId}'),
              icon: AppIcon(AppIcons.arrowLeft, color: p.ink),
            ),
            titleSpacing: 0,
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              JpLabel(set.titleJp, style: AppText.headline),
              Text('Latihan ${widget.exNo}',
                  style: AppText.caption.copyWith(color: p.inkMuted)),
            ]),
            actions: [
              const Padding(
                  padding: EdgeInsets.only(right: Sp.x1), child: ModeToggle()),
              if (set.lessons.isNotEmpty)
                IconButton(
                  tooltip: S.grammarPanel,
                  onPressed: () => showGrammarSheet(context, set.lessons.first),
                  icon: AppIcon(AppIcons.book, color: p.ink),
                ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'shuffle') _toggleShuffle(ex);
                  if (v == 'reset') _resetAll(ex);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'shuffle',
                    child: Text(_shuffled ? 'Urutan asli' : S.shuffle),
                  ),
                  const PopupMenuItem(
                      value: 'reset', child: Text(S.resetNumber)),
                ],
              ),
            ],
          ),
          bottomNavigationBar: _bottomBar(
              context, ex, hasInput, correctCount, gradedTotal, nextEx, p),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: ListView(
                  padding: const EdgeInsets.all(Sp.screen),
                  children: [
                    if (ex.instructionJp != null) ...[
                      JpTextView(ex.instructionJp!),
                      const SizedBox(height: Sp.x3),
                    ],
                    if (ex.image != null) ...[
                      BookImage(ex.image!),
                      const SizedBox(height: Sp.x4),
                    ],
                    if (ex.options.isNotEmpty) ...[
                      _optionsCard(ex.options, p),
                      const SizedBox(height: Sp.x4),
                    ],
                    if (ex.example != null) ...[
                      _exampleCard(ex.example!, p),
                      const SizedBox(height: Sp.x4),
                    ],
                    for (var i = 0; i < _items.length; i++) ...[
                      if (i > 0) const SizedBox(height: Sp.x3),
                      _itemCard(context, set, ex, _items[i], aiOn, p),
                    ],
                    const SizedBox(height: Sp.x6),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _optionsCard(List<MsOption> options, AppPalette p) {
    return Container(
      padding: const EdgeInsets.all(Sp.x3),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: Sp.x1),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${options[i].key}. ',
                style: AppText.bodyStrong.copyWith(color: p.inkMuted)),
            Expanded(
              child: options[i].usedByExample
                  ? Text(
                      options[i].jp.jp,
                      style: AppText.jpSm(1).copyWith(
                        color: p.inkSubtle,
                        decoration: TextDecoration.lineThrough,
                      ),
                    )
                  : JpTextView(options[i].jp, size: JpSize.small),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _exampleCard(MsLines ex, AppPalette p) {
    var offset = 0;
    return Container(
      padding: const EdgeInsets.all(Sp.x4),
      decoration:
          BoxDecoration(color: p.secondarySubtle, borderRadius: Radii.lgAll),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 2),
            decoration:
                BoxDecoration(color: p.secondary, borderRadius: Radii.smAll),
            child: Text(S.example,
                style: AppText.caption.copyWith(color: p.onPrimary)),
          ),
        ]),
        const SizedBox(height: Sp.x2),
        for (final ln in ex.linesJp) ...[
          () {
            final lineOffset = offset;
            offset += ln.tokens.where((t) => t.blank).length;
            return JpTextView(
              ln,
              blankIndexOffset: lineOffset,
              blankBuilder: (_, idx) {
                final b = idx < ex.blanks.length ? ex.blanks[idx] : null;
                final ans = b == null
                    ? ''
                    : (b.answersJp.isNotEmpty
                        ? b.answersJp.first.jp
                        : (b.answer ?? ''));
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: p.highlightBg,
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(ans,
                      style: AppText.jp(1).copyWith(color: p.primaryStrong)),
                );
              },
            );
          }(),
        ],
      ]),
    );
  }

  Widget _itemCard(
    BuildContext context,
    MondaishuuSet set,
    MsExercise ex,
    MsItem item,
    bool aiOn,
    AppPalette p,
  ) {
    final isRevealed = _revealed.contains(item.id);
    final isMarked = _markedCorrect.contains(item.id);
    final itemWrong = _checked &&
        item.autoGraded &&
        !isMarked &&
        List.generate(item.blanks.length, (k) => _result['${item.id}#$k'])
            .any((r) => r == BlankResult.wrong);
    final hasWrongSentence = itemWrong &&
        List.generate(item.blanks.length, (k) => k).any((k) =>
            _result['${item.id}#$k'] == BlankResult.wrong &&
            item.blanks[k].type == BlankType.sentence);

    var offset = 0;
    return Container(
      key: ValueKey('ms_item_${item.id}'),
      padding: const EdgeInsets.all(Sp.x3),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('${item.no})', style: AppText.bodyStrong),
          const Spacer(),
          IconButton(
            tooltip: S.showAnswer,
            onPressed: () => setState(() => _revealed.add(item.id)),
            icon: AppIcon(AppIcons.hint,
                size: 20, color: isRevealed ? p.secondary : p.inkMuted),
          ),
        ]),
        if (item.image != null) ...[
          BookImage(item.image!),
          const SizedBox(height: Sp.x2),
        ],
        for (final ln in item.linesJp) ...[
          () {
            final lineOffset = offset;
            offset += ln.tokens.where((t) => t.blank).length;
            return JpTextView(
              ln,
              blankIndexOffset: lineOffset,
              blankBuilder: (ctx, idx) =>
                  _buildBlank(ctx, ex, item, idx, isMarked, p),
            );
          }(),
        ],
        if (itemWrong) ...[
          const SizedBox(height: Sp.x2),
          Wrap(spacing: Sp.x2, runSpacing: Sp.x1, children: [
            TextButton(
              onPressed: () => setState(() {
                for (var k = 0; k < item.blanks.length; k++) {
                  _input.remove('${item.id}#$k');
                  _result.remove('${item.id}#$k');
                }
                _checked = false;
              }),
              child: const Text('↻ ${S.tryAgain}'),
            ),
            TextButton(
              onPressed: () => setState(() => _revealed.add(item.id)),
              child: const Text('💡 ${S.showAnswer}'),
            ),
            if (hasWrongSentence)
              TextButton(
                onPressed: () => setState(() => _markedCorrect.add(item.id)),
                child: const Text(S.markCorrect),
              ),
            if (aiOn)
              TextButton(
                onPressed: () {
                  final userAns = List.generate(item.blanks.length,
                      (k) => _input['${item.id}#$k'] ?? '').join(' / ');
                  final keyAns = item.blanks
                      .map((b) => b.answersJp.isNotEmpty
                          ? b.answersJp.first.jp
                          : (b.answer ?? ''))
                      .join(' / ');
                  showAiPanel(
                    context,
                    AiRequest(
                      action: AiAction.whyWrong,
                      lesson: set.lessons.isNotEmpty ? set.lessons.first : 1,
                      refId: item.id,
                      target: item.linesJp.map((l) => l.jp).join(' '),
                      bookContext: ex.instructionJp?.jp ?? '',
                      userAnswer: userAns,
                      keyAnswer: keyAns,
                    ),
                  );
                },
                child: const Text('✨ Kenapa salah?'),
              ),
          ]),
        ],
        if (isRevealed) ...[
          const SizedBox(height: Sp.x2),
          _revealedAnswer(item, p),
        ],
      ]),
    );
  }

  Widget _buildBlank(BuildContext context, MsExercise ex, MsItem item, int idx,
      bool isMarked, AppPalette p) {
    if (idx >= item.blanks.length) return const SizedBox.shrink();
    final b = item.blanks[idx];
    final key = '${item.id}#$idx';
    final res = _result[key];
    final state = !_checked || b.type == BlankType.free
        ? FieldState.normal
        : ((res == BlankResult.correct || isMarked)
            ? FieldState.correct
            : FieldState.wrong);

    void onTextChanged(String v) {
      final hadInput = _input.values.any((s) => s.trim().isNotEmpty);
      _input[key] = v;
      final nowHasInput = _input.values.any((s) => s.trim().isNotEmpty);
      if (hadInput != nowHasInput) setState(() {});
    }

    switch (b.type) {
      case BlankType.text:
        return KanaTextField(
          key: ValueKey('ms_blank_$key'),
          width: 110,
          initial: _input[key] ?? '',
          state: state,
          onChanged: onTextChanged,
        );
      case BlankType.sentence:
      case BlankType.free:
        return KanaTextField(
          key: ValueKey('ms_blank_$key'),
          width: 200,
          initial: _input[key] ?? '',
          state: state,
          onChanged: onTextChanged,
        );
      case BlankType.choice:
        return Wrap(
          key: ValueKey('ms_blank_$key'),
          spacing: Sp.x2,
          runSpacing: Sp.x1,
          children: [
            for (final c in b.choicesJp)
              ChoiceChip(
                label: JpLabel(c),
                selected: _input[key] == c.jp,
                onSelected: (_) => setState(() => _input[key] = c.jp),
              ),
          ],
        );
      case BlankType.option:
        final val = _input[key] ?? '';
        return ActionChip(
          key: ValueKey('ms_blank_$key'),
          label: Text(val.isEmpty ? '?' : val),
          backgroundColor: state == FieldState.correct
              ? p.successSubtle
              : (state == FieldState.wrong ? p.dangerSubtle : null),
          onPressed: () => _pickOption(context, ex.options, key, p),
        );
    }
  }

  Future<void> _pickOption(BuildContext context, List<MsOption> options,
      String key, AppPalette p) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final opt in options)
              ListTile(
                enabled: !opt.usedByExample,
                leading: Text('${opt.key}.', style: AppText.bodyStrong),
                title:
                    JpTextView(opt.jp, size: JpSize.small, interactive: false),
                onTap:
                    opt.usedByExample ? null : () => Navigator.pop(c, opt.key),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _input[key] = picked);
    }
  }

  Widget _revealedAnswer(MsItem item, AppPalette p) {
    final parts = <String>[];
    for (final b in item.blanks) {
      if (b.type == BlankType.option) {
        parts.add(b.answer ?? '');
      } else {
        parts.add(b.answersJp.map((a) => a.jp).join(' ／ '));
      }
    }
    final text = parts.where((s) => s.isNotEmpty).join(' · ');
    if (!item.autoGraded) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(S.modelAnswer,
            style: AppText.caption.copyWith(color: p.secondary)),
        const SizedBox(height: 2),
        Text(text, style: AppText.jpSm(1).copyWith(color: p.secondary)),
      ]);
    }
    return Text(
      'Jawaban: $text',
      style: AppText.jpSm(1).copyWith(color: p.secondary),
    );
  }

  Widget _bottomBar(
    BuildContext context,
    MsExercise ex,
    bool hasInput,
    int correctCount,
    int gradedTotal,
    int? nextEx,
    AppPalette p,
  ) {
    return Container(
      decoration: BoxDecoration(
          color: p.bg, border: Border(top: BorderSide(color: p.border))),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Sp.screen),
          child: !_checked
              ? SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: hasInput ? () => _check(ex) : null,
                    child: const Text(S.check),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      Text('Skor $correctCount / $gradedTotal',
                          style: AppText.headline),
                      const SizedBox(height: Sp.x2),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: hasInput ? () => _check(ex) : null,
                          child: const Text('Periksa lagi'),
                        ),
                      ),
                      const SizedBox(height: Sp.x2),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _resetAll(ex),
                            child: const Text(S.resetNumber),
                          ),
                        ),
                        const SizedBox(width: Sp.x3),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              if (nextEx != null) {
                                context.pushReplacement(
                                    '/ms/${widget.setId}/ex/$nextEx');
                              } else {
                                context.pushReplacement(
                                    '/ms/${widget.setId}/result');
                              }
                            },
                            child: Text(nextEx != null
                                ? 'Latihan berikutnya'
                                : 'Lihat ringkasan'),
                          ),
                        ),
                      ]),
                    ]),
        ),
      ),
    );
  }
}
