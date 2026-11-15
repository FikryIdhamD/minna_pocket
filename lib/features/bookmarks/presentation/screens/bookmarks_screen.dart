import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../shared/domain/models/models.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../search/domain/providers/route_for_ref.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  String _filter = 'all';

  static const _filters = [
    ('all', 'Semua'),
    ('kalimat', 'Kalimat'),
    ('kosakata', 'Kosa Kata'),
    ('tata_bahasa', 'Tata Bahasa'),
    ('latihan', 'Latihan'),
  ];

  bool _matchFilter(Bookmark b) {
    if (_filter == 'all') return true;
    if (_filter == 'latihan') {
      return b.kind == 'latihan' || b.kind == 'mondaishuu';
    }
    return b.kind == _filter;
  }

  String? _lessonLabel(String ref) {
    final head = ref.split('.').first;
    if (head.startsWith('L') && head.length >= 2) {
      final n = int.tryParse(head.substring(1));
      if (n != null) return 'Bab $n';
    }
    return null;
  }

  Future<void> _editNote(BuildContext context, Bookmark b) async {
    final ctl = TextEditingController(text: b.note);
    final res = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Ubah catatan'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Tulis catatan...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctl.text.trim()),
            child: const Text(S.save),
          ),
        ],
      ),
    );
    ctl.dispose();
    if (res != null) {
      ref.read(userDataProvider.notifier).setBookmarkNote(b.ref, res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final all = ref.watch(userDataProvider.select((u) => u.bookmarks));
    final list = all.where(_matchFilter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tersimpan')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Sp.screen, Sp.x2, Sp.screen, Sp.x2),
                  child: Wrap(
                    spacing: Sp.x2,
                    runSpacing: Sp.x2,
                    children: [
                      for (final (key, label) in _filters)
                        ChoiceChip(
                          label: Text(label),
                          selected: _filter == key,
                          onSelected: (_) => setState(() => _filter = key),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(Sp.screen),
                            child: Text(
                              S.emptyBookmarks,
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(color: p.inkMuted),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                              Sp.screen, Sp.x2, Sp.screen, Sp.x6),
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: Radii.lgAll,
                                border: Border.all(color: p.border),
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0; i < list.length; i++) ...[
                                    if (i > 0)
                                      Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: p.border),
                                    _row(context, list[i], p),
                                  ],
                                ],
                              ),
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

  Widget _row(BuildContext context, Bookmark b, AppPalette p) {
    final lesson = _lessonLabel(b.ref);
    return ListTile(
      title: Text(b.label, style: AppText.jpSm(1).copyWith(color: p.ink)),
      subtitle: (b.note.isNotEmpty || lesson != null)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.note.isNotEmpty)
                  Text(
                    b.note,
                    style: AppText.bodySm.copyWith(color: p.secondary),
                  ),
                if (lesson != null)
                  Text(
                    lesson,
                    style: AppText.caption.copyWith(color: p.inkMuted),
                  ),
              ],
            )
          : null,
      trailing: PopupMenuButton<String>(
        icon: AppIcon(AppIcons.more, color: p.inkMuted),
        onSelected: (v) {
          if (v == 'edit') _editNote(context, b);
          if (v == 'delete') {
            ref.read(userDataProvider.notifier).toggleBookmark(
                  ref: b.ref,
                  kind: b.kind,
                  label: b.label,
                );
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Ubah catatan')),
          PopupMenuItem(value: 'delete', child: Text('Hapus')),
        ],
      ),
      onTap: () => context.push(routeForRef(b.ref)),
    );
  }
}
