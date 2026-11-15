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
import '../../../../shared/widgets/async_view.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../domain/providers/route_for_ref.dart';
import '../../domain/providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _ctl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _setQuery(String v) {
    if (_ctl.text != v) {
      _ctl.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    }
    setState(() => _query = v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final history = ref.watch(userDataProvider.select((u) => u.searchHistory));
    final trimmed = _query.trim();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: S.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: Sp.x2),
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              tooltip: 'Hapus',
              onPressed: () => _setQuery(''),
              icon: AppIcon(AppIcons.close, color: p.ink),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
            child: trimmed.isEmpty
                ? _historyView(history, p)
                : _resultsView(trimmed, p),
          ),
        ),
      ),
    );
  }

  Widget _historyView(List<String> history, AppPalette p) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          S.searchHint,
          style: AppText.bodySm.copyWith(color: p.inkMuted),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(Sp.screen),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'RIWAYAT',
                style: AppText.overline.copyWith(color: p.inkMuted),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(userDataProvider.notifier).clearSearchHistory(),
              child: const Text('Hapus riwayat'),
            ),
          ],
        ),
        const SizedBox(height: Sp.x2),
        Wrap(
          spacing: Sp.x2,
          runSpacing: Sp.x2,
          children: [
            for (final h in history)
              ActionChip(
                label: Text(h),
                onPressed: () => _setQuery(h),
              ),
          ],
        ),
      ],
    );
  }

  Widget _resultsView(String query, AppPalette p) {
    final resAsync = ref.watch(searchResultsProvider(query));
    return resAsync.when(
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorView(
        message: S.loadError,
        onRetry: () => ref.invalidate(searchResultsProvider(query)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Text(
              S.emptySearch,
              style: AppText.body.copyWith(color: p.inkMuted),
            ),
          );
        }

        const groups = [
          ('kosakata', 'KOSA KATA'),
          ('kalimat', 'KALIMAT'),
          ('tata_bahasa', 'TATA BAHASA'),
          ('referensi', 'KATA REFERENSI'),
        ];

        final byType = <String, List<SearchEntry>>{};
        for (final e in list) {
          byType.putIfAbsent(e.type, () => []).add(e);
        }

        return ListView(
          padding: const EdgeInsets.all(Sp.screen),
          children: [
            for (final (type, label) in groups)
              if (byType[type]?.isNotEmpty ?? false) ...[
                Padding(
                  padding: const EdgeInsets.only(top: Sp.x2, bottom: Sp.x2),
                  child: Text(
                    label,
                    style: AppText.overline.copyWith(color: p.inkMuted),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: Radii.lgAll,
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < byType[type]!.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, thickness: 1, color: p.border),
                        _resultTile(query, byType[type]![i], p),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Sp.x3),
              ],
          ],
        );
      },
    );
  }

  Widget _resultTile(String query, SearchEntry e, AppPalette p) {
    return ListTile(
      title: JpLabel(
        JpText(jp: e.jp, tokens: const []),
        style: AppText.jpSm(1).copyWith(color: p.ink),
      ),
      subtitle: Text(
        e.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.bodySm.copyWith(color: p.inkMuted),
      ),
      trailing: Text(
        'Bab ${e.lesson}',
        style: AppText.caption.copyWith(color: p.inkMuted),
      ),
      onTap: () {
        ref.read(userDataProvider.notifier).addSearch(query);
        context.push(routeForRef(e.ref));
      },
    );
  }
}
