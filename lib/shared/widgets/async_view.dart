// Pembungkus AsyncValue: loading = skeleton, error = pesan + Coba lagi. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/text_theme.dart';
import '../utils/strings.dart';

class AsyncView<T> extends StatelessWidget {
  const AsyncView(
      {super.key, required this.value, required this.data, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => value.when(
        data: data,
        loading: () => const SkeletonList(),
        error: (e, _) => ErrorView(message: S.loadError, onRetry: onRetry),
      );
}

class SkeletonList extends StatefulWidget {
  const SkeletonList({super.key, this.rows = 6});
  final int rows;

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = p.surfaceAlt;
    final hi = Color.lerp(base, p.surface, 0.72) ?? p.surface;
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        final dx = -1.5 + 3.0 * _ctl.value;
        final grad = LinearGradient(
          begin: Alignment(dx - 0.6, -0.2),
          end: Alignment(dx + 0.6, 0.2),
          colors: [base, hi, base],
        );
        return ListView.separated(
          padding: const EdgeInsets.all(Sp.screen),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.rows,
          separatorBuilder: (_, __) => const SizedBox(height: Sp.x3),
          itemBuilder: (_, i) => Container(
            height: i == 0 ? 96 : 56,
            decoration:
                BoxDecoration(gradient: grad, borderRadius: Radii.mdAll),
          ),
        );
      },
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Sp.x8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message,
                style: AppText.body.copyWith(color: context.palette.inkMuted),
                textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: Sp.x4),
              OutlinedButton(onPressed: onRetry, child: const Text(S.retry)),
            ],
          ]),
        ),
      );
}
