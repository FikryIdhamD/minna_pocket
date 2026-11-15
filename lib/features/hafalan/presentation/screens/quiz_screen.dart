import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/srs.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/async_view.dart';
import '../../domain/providers/quiz_builder.dart';
import 'flashcard_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.deck});

  final String deck;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<QuizQuestion>? _questions;
  int _index = 0;
  String? _selected;
  int _correct = 0;
  final List<QuizQuestion> _wrong = [];
  Timer? _autoNext;

  @override
  void dispose() {
    _autoNext?.cancel();
    super.dispose();
  }

  void _init(List<QuizQuestion> source) {
    _questions ??= List<QuizQuestion>.from(source);
  }

  void _pick(QuizQuestion q, String opt) {
    if (_selected != null) return;
    final ok = opt == q.correctAnswer;
    setState(() {
      _selected = opt;
      if (ok) {
        _correct++;
      } else {
        _wrong.add(q);
      }
    });
    if (!ok) {
      ref.read(userDataProvider.notifier).srsReview(q.card.key, SrsGrade.lupa);
      return;
    }
    _autoNext?.cancel();
    _autoNext = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _next();
    });
  }

  void _next() {
    _autoNext?.cancel();
    setState(() {
      _index++;
      _selected = null;
    });
  }

  void _retryAll() {
    _autoNext?.cancel();
    setState(() {
      _questions = null;
      _index = 0;
      _selected = null;
      _correct = 0;
      _wrong.clear();
    });
    ref.invalidate(quizProvider(widget.deck));
  }

  void _retryWrong() {
    _autoNext?.cancel();
    setState(() {
      _questions = List<QuizQuestion>.from(_wrong);
      _index = 0;
      _selected = null;
      _correct = 0;
      _wrong.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final quizAsync = ref.watch(quizProvider(widget.deck));
    final title = 'Kuis ${deckTitle(widget.deck)}';

    return quizAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const SkeletonList(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ErrorView(
          message: S.loadError,
          onRetry: () => ref.invalidate(quizProvider(widget.deck)),
        ),
      ),
      data: (source) {
        if (source.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Center(
              child: Text('Tidak ada soal kuis.', style: AppText.body),
            ),
          );
        }
        _init(source);
        final qs = _questions!;
        final done = _index >= qs.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
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
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: Sizes.maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.all(Sp.screen),
                  child: done
                      ? _summaryView(qs.length, p)
                      : _questionView(qs[_index], p),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _questionView(QuizQuestion q, AppPalette p) {
    final isWrongPick = _selected != null && _selected != q.correctAnswer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: MediaQuery.sizeOf(context).height * 0.34,
          padding: const EdgeInsets.all(Sp.x5),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: Radii.lgAll,
            border: Border.all(color: p.border),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                q.prompt,
                style: AppText.brushCard.copyWith(color: p.ink),
              ),
            ),
          ),
        ),
        const SizedBox(height: Sp.x4),
        for (var i = 0; i < q.options.length; i++) ...[
          if (i > 0) const SizedBox(height: Sp.x2),
          _optionButton(q, q.options[i], p),
        ],
        const Spacer(),
        if (isWrongPick)
          FilledButton(
            onPressed: _next,
            child: const Text('Berikutnya'),
          ),
      ],
    );
  }

  Widget _optionButton(QuizQuestion q, String opt, AppPalette p) {
    final answered = _selected != null;
    final isCorrect = opt == q.correctAnswer;
    final isSelected = opt == _selected;

    Color? bg;
    Color? border;
    Color? fg;
    if (answered) {
      if (isCorrect) {
        bg = p.successSubtle;
        border = p.success;
        fg = p.success;
      } else if (isSelected) {
        bg = p.dangerSubtle;
        border = p.danger;
        fg = p.danger;
      }
    }

    return OutlinedButton(
      onPressed: answered ? null : () => _pick(q, opt),
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg ?? p.ink,
        disabledForegroundColor: fg ?? p.inkMuted,
        side: BorderSide(
            color: border ?? p.border, width: border != null ? 1.8 : 1),
        padding: const EdgeInsets.symmetric(vertical: Sp.x3, horizontal: Sp.x4),
      ),
      child: Text(opt, style: AppText.bodyStrong),
    );
  }

  Widget _summaryView(int total, AppPalette p) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppIcon(AppIcons.checkCircle, size: 48, color: p.success),
        const SizedBox(height: Sp.x3),
        Text(
          '$_correct / $total benar',
          textAlign: TextAlign.center,
          style: AppText.title,
        ),
        const SizedBox(height: Sp.x5),
        FilledButton(
          onPressed: _retryAll,
          child: const Text('Ulangi'),
        ),
        if (_wrong.isNotEmpty) ...[
          const SizedBox(height: Sp.x2),
          OutlinedButton(
            onPressed: _retryWrong,
            child: const Text(S.repeatWrong),
          ),
        ],
        const SizedBox(height: Sp.x2),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Kembali'),
        ),
      ],
    );
  }
}
