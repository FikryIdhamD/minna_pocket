import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../services/tts_service/domain/providers/tts_service.dart';
import '../../../../shared/domain/models/models.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/srs.dart';

class KanaGrid extends ConsumerWidget {
  const KanaGrid({super.key, required this.table, this.script});

  final KanaTable table;
  final String? script;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final srs = ref.watch(userDataProvider.select((u) => u.srs));
    final cols = table.rows.fold<int>(
      1,
      (m, r) => r.length > m ? r.length : m,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < table.rows.length; r++) ...[
          if (r > 0) const SizedBox(height: Sp.x2),
          Row(
            children: [
              for (var c = 0; c < cols; c++) ...[
                if (c > 0) const SizedBox(width: Sp.x2),
                Expanded(
                  child: _cellWidget(
                    context,
                    ref,
                    c < table.rows[r].length ? table.rows[r][c] : null,
                    srs,
                    p,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _cellWidget(
    BuildContext context,
    WidgetRef ref,
    KanaCell? cell,
    Map<String, SrsCard> srs,
    AppPalette p,
  ) {
    if (cell == null) return const SizedBox(height: 64);
    final card = script == null ? null : srs['$script:${cell.kana}'];
    final mastered = card != null && isMastered(card);

    return Material(
      color: p.surface,
      borderRadius: Radii.mdAll,
      child: InkWell(
        borderRadius: Radii.mdAll,
        onTap: () => ref.read(ttsServiceProvider).speak(cell.kana),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: Radii.mdAll,
            border: Border.all(color: p.border),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cell.kana,
                      style: AppText.brushTile.copyWith(
                        fontSize: AppText.brushTile.fontSize! * 1.4,
                        color: p.ink,
                      ),
                    ),
                    Text(
                      cell.romaji,
                      style: AppText.caption.copyWith(color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              if (mastered)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
