// Pembungkus AsyncValue: loading = skeleton, error = pesan + Coba lagi. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/text_theme.dart';
import '../utils/strings.dart';

class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, this.onRetry});
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

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6});
  final int rows;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.separated(
      padding: const EdgeInsets.all(Sp.screen),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows,
      separatorBuilder: (_, __) => const SizedBox(height: Sp.x3),
      itemBuilder: (_, i) => Container(
        height: i == 0 ? 96 : 56,
        decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: Radii.mdAll),
      ),
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
            Text(message, style: AppText.body.copyWith(color: context.palette.inkMuted), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: Sp.x4),
              OutlinedButton(onPressed: onRetry, child: const Text(S.retry)),
            ],
          ]),
        ),
      );
}
