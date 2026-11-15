import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';

class FlagsScreen extends ConsumerWidget {
  const FlagsScreen({super.key});

  String _yyyymmdd() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}';
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final flags = ref.watch(userDataProvider.select((u) => u.flags));

    return Scaffold(
      appBar: AppBar(title: const Text('Tandaan salah ketik')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
            child: flags.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada tandaan.',
                      style: AppText.body.copyWith(color: p.inkMuted),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(Sp.screen),
                          itemCount: flags.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: Sp.x2),
                          itemBuilder: (_, i) {
                            final f = flags[i];
                            return Container(
                              padding: const EdgeInsets.all(Sp.x3),
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: Radii.mdAll,
                                border: Border.all(color: p.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.text,
                                      style: AppText.jpSm(1)
                                          .copyWith(color: p.ink)),
                                  if (f.note.isNotEmpty) ...[
                                    const SizedBox(height: Sp.x1),
                                    Text(f.note, style: AppText.bodySm),
                                  ],
                                  const SizedBox(height: Sp.x1),
                                  Text(
                                    '${f.ref} · ${_fmtDate(f.at)}',
                                    style: AppText.caption
                                        .copyWith(color: p.inkMuted),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(Sp.screen),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              onPressed: () async {
                                final json = ref
                                    .read(userDataProvider.notifier)
                                    .exportFlagsJson();
                                final saved =
                                    await FilePicker.platform.saveFile(
                                  fileName:
                                      'minna_pocket_tandaan_${_yyyymmdd()}.json',
                                  bytes: utf8.encode(json),
                                );
                                if (saved != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Tandaan diekspor.')),
                                  );
                                }
                              },
                              child: const Text('Ekspor'),
                            ),
                            const SizedBox(height: Sp.x2),
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: p.danger),
                              onPressed: () => _confirmClear(context, ref),
                              child: const Text('Hapus semua'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus semua tandaan?'),
        content: const Text('Semua tandaan salah ketik akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: p.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(userDataProvider.notifier).clearFlags();
    }
  }
}
