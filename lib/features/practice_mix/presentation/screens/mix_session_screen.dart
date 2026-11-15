import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/domain/models/models.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/answer_checker.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/book_image.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../../shared/widgets/kana_text_field.dart';
import '../../domain/providers/mix_providers.dart';

class MixSessionScreen extends ConsumerStatefulWidget {
  const MixSessionScreen({super.key});

  @override
  ConsumerState<MixSessionScreen> createState() => _MixSessionScreenState();
}

class _MixSessionScreenState extends ConsumerState<MixSessionScreen> {
  List<MixQuestion>? _questions;
  int _index = 0;
  int _correct = 0;
  final List<MixQuestion> _wrong = [];

  // State untuk satu soal aktif
  final Map<int, String> _msInput = {};
  final Map<int, BlankResult> _msResult = {};
  bool _msChecked = false;
  String? _vocabPicked;

  void _init(List<MixQuestion> source) {
    _questions ??= List<MixQuestion>.from(source);
  }

  void _nextQuestion() {
    setState(() {
      _index++;
      _msInput.clear();
      _msResult.clear();
      _msChecked = false;
      _vocabPicked = null;
    });
  }

  void _checkMs(MixMsQuestion q) {
    final res = <int, BlankResult>{};
    var allOk = true;
    for (var k = 0; k < q.item.blanks.length; k++) {
      final r = checkBlank(q.item.blanks[k], _msInput[k] ?? '');
      res[k] = r;
      if (r == BlankResult.wrong) allOk = false;
    }
    setState(() {
      _msResult
        ..clear()
        ..addAll(res);
      _msChecked = true;
      if (allOk) {
        _correct++;
      } else {
        _wrong.add(q);
      }
    });
  }

  void _pickVocab(MixVocabQuestion q, String opt) {
    if (_vocabPicked != null) return;
    final ok = opt == q.item.tr;
    setState(() {
      _vocabPicked = opt;
      if (ok) {
        _correct++;
      } else {
        _wrong.add(q);
      }
    });
  }

  void _retryWrong() {
    setState(() {
      _questions = List<MixQuestion>.from(_wrong);
      _index = 0;
      _correct = 0;
      _wrong.clear();
      _msInput.clear();
      _msResult.clear();
      _msChecked = false;
      _vocabPicked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final qsAsync = ref.watch(mixQuestionsProvider);

    return qsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Latihan Campuran')),
        body: const SkeletonList(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Latihan Campuran')),
        body: ErrorView(
          message: S.loadError,
          onRetry: () => ref.invalidate(mixQuestionsProvider),
        ),
      ),
      data: (source) {
        _init(source);
        final qs = _questions!;
        if (qs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Latihan Campuran')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(Sp.screen),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tidak ada soal untuk pilihan ini.',
                        style: AppText.body),
                    const SizedBox(height: Sp.x4),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Kembali'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final done = _index >= qs.length;
        final progress = done ? 1.0 : (_index + 1) / qs.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Latihan Campuran'),
            actions: [
              if (!done)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: Sp.screen),
                    child: Text(
                      '${_index + 1} / ${qs.length}',
                      style: AppText.bodySm.copyWith(color: p.inkMuted),
                    ),
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: LinearProgressIndicator(value: progress),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: done
                    ? _summaryView(qs.length, p)
                    : _questionBody(qs[_index], p),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _questionBody(MixQuestion q, AppPalette p) {
    return switch (q) {
      MixMsQuestion() => _msBody(q, p),
      MixVocabQuestion() => _vocabBody(q, p),
    };
  }

  Widget _msBody(MixMsQuestion q, AppPalette p) {
    final hasInput = _msInput.values.any((v) => v.trim().isNotEmpty);
    var offset = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Sp.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bab ${q.lesson} · Mondaishuu',
                  style: AppText.caption.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Sp.x2),
                if (q.exercise.instructionJp != null) ...[
                  JpTextView(q.exercise.instructionJp!),
                  const SizedBox(height: Sp.x3),
                ],
                if (q.exercise.image != null) ...[
                  BookImage(q.exercise.image!),
                  const SizedBox(height: Sp.x3),
                ],
                if (q.exercise.example != null) ...[
                  _msExample(q.exercise, q.exercise.example!, p),
                  const SizedBox(height: Sp.x3),
                ],
                Container(
                  padding: const EdgeInsets.all(Sp.x3),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: Radii.lgAll,
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (q.item.image != null) ...[
                        BookImage(q.item.image!),
                        const SizedBox(height: Sp.x2),
                      ],
                      for (final ln in q.item.linesJp)
                        () {
                          final lineOffset = offset;
                          offset += ln.tokens.where((t) => t.blank).length;
                          return JpTextView(
                            ln,
                            blankIndexOffset: lineOffset,
                            blankBuilder: (ctx, idx) =>
                                _msBlank(ctx, q, idx, p),
                          );
                        }(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Sp.screen),
          child: !_msChecked
              ? FilledButton(
                  onPressed: hasInput ? () => _checkMs(q) : null,
                  child: const Text(S.check),
                )
              : FilledButton(
                  onPressed: _nextQuestion,
                  child: const Text('Berikutnya'),
                ),
        ),
      ],
    );
  }

  Widget _msExample(MsExercise ex, MsLines example, AppPalette p) {
    var offset = 0;
    return Container(
      padding: const EdgeInsets.all(Sp.x3),
      decoration: BoxDecoration(
        color: p.secondarySubtle,
        borderRadius: Radii.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: Sp.x2, vertical: 2),
              decoration: BoxDecoration(
                color: p.secondary,
                borderRadius: Radii.smAll,
              ),
              child: Text(S.example,
                  style: AppText.caption.copyWith(color: p.onPrimary)),
            ),
          ),
          const SizedBox(height: Sp.x2),
          for (final ln in example.linesJp)
            () {
              final lineOffset = offset;
              offset += ln.tokens.where((t) => t.blank).length;
              return JpTextView(
                ln,
                blankIndexOffset: lineOffset,
                blankBuilder: (_, idx) {
                  final b =
                      idx < example.blanks.length ? example.blanks[idx] : null;
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
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(ans,
                        style: AppText.jp(1).copyWith(color: p.primaryStrong)),
                  );
                },
              );
            }(),
        ],
      ),
    );
  }

  Widget _msBlank(
      BuildContext context, MixMsQuestion q, int idx, AppPalette p) {
    if (idx >= q.item.blanks.length) return const SizedBox.shrink();
    final b = q.item.blanks[idx];
    final res = _msResult[idx];
    final state = !_msChecked
        ? FieldState.normal
        : (res == BlankResult.correct ? FieldState.correct : FieldState.wrong);

    void onTextChanged(String v) {
      final hadInput = _msInput.values.any((s) => s.trim().isNotEmpty);
      _msInput[idx] = v;
      final nowHasInput = _msInput.values.any((s) => s.trim().isNotEmpty);
      if (hadInput != nowHasInput) setState(() {});
    }

    Widget kanaField(double width) {
      final focusColor = switch (state) {
        FieldState.correct => p.success,
        FieldState.wrong => p.danger,
        FieldState.normal => p.inkMuted,
      };
      return Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                focusedBorder: OutlineInputBorder(
                  borderRadius: Radii.smAll,
                  borderSide: BorderSide(
                    color: focusColor,
                    width: state == FieldState.normal ? 1.5 : 1.8,
                  ),
                ),
              ),
        ),
        child: KanaTextField(
          key: ValueKey('mix_${_index}_${q.item.id}_$idx'),
          width: width,
          enabled: !_msChecked,
          initial: _msInput[idx] ?? '',
          state: state,
          onChanged: onTextChanged,
        ),
      );
    }

    switch (b.type) {
      case BlankType.text:
        return kanaField(110);
      case BlankType.sentence:
      case BlankType.free:
        return kanaField(200);
      case BlankType.choice:
        return Wrap(
          key: ValueKey('mix_${_index}_${q.item.id}_$idx'),
          spacing: Sp.x2,
          runSpacing: Sp.x1,
          children: [
            for (final c in b.choicesJp)
              ChoiceChip(
                label: JpLabel(c),
                selected: _msInput[idx] == c.jp,
                onSelected: _msChecked
                    ? null
                    : (_) => setState(() => _msInput[idx] = c.jp),
              ),
          ],
        );
      case BlankType.option:
        final val = _msInput[idx] ?? '';
        return ActionChip(
          key: ValueKey('mix_${_index}_${q.item.id}_$idx'),
          label: Text(val.isEmpty ? '?' : val),
          backgroundColor: state == FieldState.correct
              ? p.successSubtle
              : (state == FieldState.wrong ? p.dangerSubtle : null),
          onPressed: _msChecked
              ? null
              : () => _pickOption(context, q.exercise.options, idx),
        );
    }
  }

  Future<void> _pickOption(
      BuildContext context, List<MsOption> options, int idx) async {
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
      setState(() => _msInput[idx] = picked);
    }
  }

  Widget _vocabBody(MixVocabQuestion q, AppPalette p) {
    final word = q.item.kanjiJp ?? q.item.kanaJp;

    return Padding(
      padding: const EdgeInsets.all(Sp.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bab ${q.lesson} · Kosa Kata',
            style: AppText.caption.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Sp.x4),
          Container(
            padding: const EdgeInsets.all(Sp.x5),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: Radii.lgAll,
              border: Border.all(color: p.border),
            ),
            child: Center(
              child: JpTextView(
                word,
                size: JpSize.title,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: Sp.x4),
          for (var i = 0; i < q.options.length; i++) ...[
            if (i > 0) const SizedBox(height: Sp.x2),
            _vocabOption(q, q.options[i], p),
          ],
          const Spacer(),
          if (_vocabPicked != null)
            FilledButton(
              onPressed: _nextQuestion,
              child: const Text('Berikutnya'),
            ),
        ],
      ),
    );
  }

  Widget _vocabOption(MixVocabQuestion q, String opt, AppPalette p) {
    final answered = _vocabPicked != null;
    final isCorrect = opt == q.item.tr;
    final isPicked = opt == _vocabPicked;

    Color? bg;
    Color? border;
    Color? fg;
    if (answered) {
      if (isCorrect) {
        bg = p.successSubtle;
        border = p.success;
        fg = p.success;
      } else if (isPicked) {
        bg = p.dangerSubtle;
        border = p.danger;
        fg = p.danger;
      }
    }

    return OutlinedButton(
      onPressed: answered ? null : () => _pickVocab(q, opt),
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg ?? p.ink,
        disabledForegroundColor: fg ?? p.inkMuted,
        side: BorderSide(
            color: border ?? p.border, width: border != null ? 1.8 : 1),
        padding: const EdgeInsets.symmetric(vertical: Sp.x3, horizontal: Sp.x4),
      ),
      child: Text(opt, textAlign: TextAlign.center, style: AppText.bodyStrong),
    );
  }

  Widget _summaryView(int total, AppPalette p) {
    final wrongByLesson = <int, int>{};
    for (final w in _wrong) {
      wrongByLesson[w.lesson] = (wrongByLesson[w.lesson] ?? 0) + 1;
    }
    final topWeak = wrongByLesson.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = topWeak.take(3).toList();

    String wrongText(MixQuestion q) => switch (q) {
          MixMsQuestion() => q.item.linesJp.map((l) => l.jp).join(' '),
          MixVocabQuestion() =>
            '${(q.item.kanjiJp ?? q.item.kanaJp).jp} — ${q.item.tr}',
        };

    return ListView(
      padding: const EdgeInsets.all(Sp.screen),
      children: [
        const SizedBox(height: Sp.x3),
        AppIcon(AppIcons.checkCircle, size: 48, color: p.success),
        const SizedBox(height: Sp.x3),
        Text(
          '$_correct / $total benar',
          textAlign: TextAlign.center,
          style: AppText.title,
        ),
        if (_wrong.isNotEmpty) ...[
          const SizedBox(height: Sp.x5),
          Text(
            'SOAL SALAH',
            style: AppText.overline.copyWith(color: p.inkMuted),
          ),
          const SizedBox(height: Sp.x2),
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: Radii.lgAll,
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _wrong.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: p.border),
                  ListTile(
                    title: Text(
                      wrongText(_wrong[i]),
                      style: AppText.jpSm(1).copyWith(color: p.ink),
                    ),
                    trailing: Text(
                      'Bab ${_wrong[i].lesson}',
                      style: AppText.caption.copyWith(color: p.inkMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Sp.x5),
          Text(
            'Bab yang paling sering salah',
            style: AppText.bodyStrong,
          ),
          const SizedBox(height: Sp.x2),
          Wrap(
            spacing: Sp.x2,
            runSpacing: Sp.x2,
            children: [
              for (final e in top3)
                OutlinedButton(
                  onPressed: () => context.push('/lesson/${e.key}'),
                  child: Text('Bab ${e.key} (${e.value})'),
                ),
            ],
          ),
        ],
        const SizedBox(height: Sp.x6),
        if (_wrong.isNotEmpty) ...[
          FilledButton(
            onPressed: _retryWrong,
            child: const Text('Ulangi yang salah'),
          ),
          const SizedBox(height: Sp.x2),
        ],
        OutlinedButton(
          onPressed: () => context.pop(),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}
