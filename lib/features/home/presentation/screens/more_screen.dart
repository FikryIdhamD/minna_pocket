import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/widgets/app_icon.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final bookmarkCount =
        ref.watch(userDataProvider.select((u) => u.bookmarks.length));
    final dataVersion =
        ref.watch(manifestProvider).valueOrNull?.dataVersion ?? '-';

    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(Sp.screen),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: Radii.lgAll,
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: AppIcon(AppIcons.search, color: p.ink),
                        title: const Text('Pencarian'),
                        trailing:
                            AppIcon(AppIcons.chevronRight, color: p.inkMuted),
                        onTap: () => context.push('/search'),
                      ),
                      Divider(height: 1, thickness: 1, color: p.border),
                      ListTile(
                        leading: AppIcon(AppIcons.star, color: p.ink),
                        title: const Text('Tersimpan'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bookmarkCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: Sp.x2),
                                child: Text(
                                  '$bookmarkCount',
                                  style: AppText.bodySm
                                      .copyWith(color: p.inkMuted),
                                ),
                              ),
                            AppIcon(AppIcons.chevronRight, color: p.inkMuted),
                          ],
                        ),
                        onTap: () => context.push('/bookmarks'),
                      ),
                      Divider(height: 1, thickness: 1, color: p.border),
                      ListTile(
                        leading: AppIcon(AppIcons.settings, color: p.ink),
                        title: const Text('Pengaturan'),
                        trailing:
                            AppIcon(AppIcons.chevronRight, color: p.inkMuted),
                        onTap: () => context.push('/settings'),
                      ),
                      Divider(height: 1, thickness: 1, color: p.border),
                      ListTile(
                        leading: AppIcon(AppIcons.info, color: p.ink),
                        title: const Text('Tentang'),
                        trailing:
                            AppIcon(AppIcons.chevronRight, color: p.inkMuted),
                        onTap: () => _showAbout(context, dataVersion),
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

  void _showAbout(BuildContext context, String dataVersion) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Minna Pocket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versi data: $dataVersion', style: AppText.bodyStrong),
            const SizedBox(height: Sp.x2),
            const Text(
              'Isi dari buku Minna no Nihongo Shokyu I (3A Corporation). Untuk penggunaan pribadi.',
            ),
            const SizedBox(height: Sp.x3),
            const Text(
              'Lisensi font: Noto Sans JP, Klee One, Plus Jakarta Sans (OFL).\nLisensi ikon: Lucide Icons (ISC).',
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
