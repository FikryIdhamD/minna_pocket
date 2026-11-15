import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/content_service/domain/providers/content_providers.dart';
import '../../../../services/progress_service/domain/providers/user_data_provider.dart';
import '../../../../services/tts_service/domain/providers/tts_service.dart';
import '../../../../shared/domain/models/models.dart';
import '../../../../shared/domain/providers/settings_provider.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/text_theme.dart';
import '../../../../shared/utils/strings.dart';
import '../../../../shared/widgets/app_icon.dart';
import '../../../../shared/widgets/jp_text_view.dart';
import '../../../ai_assist/data/datasource/ai_cache.dart';
import '../../../ai_assist/data/datasource/ai_key_store.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _fallbackPreview = JpText(
    jp: 'わたしはマイク・ミラーです。',
    tokens: [
      JpToken(s: 'わたしはマイク・ミラーです。', ro: 'Watashi wa Maiku Miraa desu.'),
    ],
  );

  String _yyyymmdd() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}'
        '${n.month.toString().padLeft(2, '0')}'
        '${n.day.toString().padLeft(2, '0')}';
  }

  String _providerLabel(AiProvider p) => switch (p) {
        AiProvider.anthropic => 'Claude',
        AiProvider.gemini => 'Gemini',
        AiProvider.openai => 'OpenAI',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final aiOn = ref.watch(aiEnabledProvider).valueOrNull ?? false;
    final flagCount = ref.watch(userDataProvider.select((u) => u.flags.length));
    final l1 = ref.watch(lessonProvider(1)).valueOrNull;
    final previewText = l1?.sections.bunkei.firstOrNull?.jp ?? _fallbackPreview;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Sizes.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(Sp.screen),
              children: [
                _groupLabel('TAMPILAN', p),
                _card(
                  p,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Tema',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: Sp.x2),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                              value: ThemeMode.system, label: Text('Sistem')),
                          ButtonSegment(
                              value: ThemeMode.light, label: Text('Terang')),
                          ButtonSegment(
                              value: ThemeMode.dark, label: Text('Gelap')),
                        ],
                        selected: {s.themeMode},
                        onSelectionChanged: (v) =>
                            n.update((x) => x.copyWith(themeMode: v.first)),
                      ),
                      const SizedBox(height: Sp.x4),
                      const Text('Ukuran huruf',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: Sp.x2),
                      DropdownButtonFormField<double>(
                        value: const [0.9, 1.0, 1.15, 1.3].contains(s.textScale)
                            ? s.textScale
                            : 1.0,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 0.9, child: Text('Kecil')),
                          DropdownMenuItem(value: 1.0, child: Text('Normal')),
                          DropdownMenuItem(value: 1.15, child: Text('Besar')),
                          DropdownMenuItem(
                              value: 1.3, child: Text('Sangat besar')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            n.update((x) => x.copyWith(textScale: v));
                          }
                        },
                      ),
                      const SizedBox(height: Sp.x3),
                      Container(
                        padding: const EdgeInsets.all(Sp.x3),
                        decoration: BoxDecoration(
                          color: p.surfaceAlt,
                          borderRadius: Radii.mdAll,
                        ),
                        child: JpTextView(previewText, interactive: false),
                      ),
                      const SizedBox(height: Sp.x4),
                      const Text('Mode teks bawaan',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: Sp.x2),
                      SegmentedButton<DisplayMode>(
                        segments: const [
                          ButtonSegment(
                              value: DisplayMode.kana, label: Text('あ')),
                          ButtonSegment(
                              value: DisplayMode.romaji, label: Text('Ro')),
                        ],
                        selected: {s.displayMode},
                        onSelectionChanged: (v) =>
                            n.update((x) => x.copyWith(displayMode: v.first)),
                      ),
                      const SizedBox(height: Sp.x2),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tampilkan terjemahan otomatis'),
                        value: s.showTranslation,
                        onChanged: (v) =>
                            n.update((x) => x.copyWith(showTranslation: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.x5),
                _groupLabel('AUDIO', p),
                _card(
                  p,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Kecepatan', style: AppText.bodyStrong),
                      const SizedBox(height: Sp.x2),
                      SegmentedButton<double>(
                        segments: const [
                          ButtonSegment(value: 0.75, label: Text('0.75×')),
                          ButtonSegment(value: 1.0, label: Text('1×')),
                        ],
                        selected: {s.audioSpeed < 1 ? 0.75 : 1.0},
                        onSelectionChanged: (v) =>
                            n.update((x) => x.copyWith(audioSpeed: v.first)),
                      ),
                      const SizedBox(height: Sp.x2),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Jeda otomatis tiap soal'),
                        subtitle: const Text(
                            'Mondai: audio berhenti setelah tiap soal'),
                        value: s.autoPause,
                        onChanged: (v) =>
                            n.update((x) => x.copyWith(autoPause: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Ulangi otomatis'),
                        subtitle: const Text(
                            'Putar lagi dari awal saat audio selesai'),
                        value: s.autoRepeat,
                        onChanged: (v) =>
                            n.update((x) => x.copyWith(autoRepeat: v)),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Gulir otomatis (Kaiwa)'),
                        value: s.kaiwaAutoScroll,
                        onChanged: (v) =>
                            n.update((x) => x.copyWith(kaiwaAutoScroll: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.x5),
                _groupLabel('SUARA PENGUCAPAN 🔊', p),
                _card(
                  p,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Text('Kecepatan bicara',
                                  style: AppText.bodyStrong)),
                          Text(s.ttsRate.toStringAsFixed(2),
                              style:
                                  AppText.bodySm.copyWith(color: p.inkMuted)),
                        ],
                      ),
                      Slider(
                        min: 0.3,
                        max: 0.6,
                        divisions: 6,
                        value: s.ttsRate.clamp(0.3, 0.6),
                        onChanged: (v) =>
                            n.update((x) => x.copyWith(ttsRate: v)),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cek suara Jepang'),
                        trailing:
                            AppIcon(AppIcons.chevronRight, color: p.inkMuted),
                        onTap: () => _checkTts(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.x5),
                _groupLabel('HAFALAN', p),
                _card(
                  p,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Kartu baru per hari', style: AppText.bodyStrong),
                      const SizedBox(height: Sp.x2),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 5, label: Text('5')),
                          ButtonSegment(value: 10, label: Text('10')),
                          ButtonSegment(value: 20, label: Text('20')),
                        ],
                        selected: {s.newCardsPerDay},
                        onSelectionChanged: (v) => n
                            .update((x) => x.copyWith(newCardsPerDay: v.first)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Sp.x5),
                _groupLabel('AI', p),
                _listCard(
                  p,
                  [
                    ListTile(
                      leading: AppIcon(AppIcons.sparkles, color: p.primary),
                      title: const Text('Penjelasan AI'),
                      subtitle: Text(
                        aiOn
                            ? '${_providerLabel(s.aiProvider)} · aktif'
                            : 'Belum diatur',
                      ),
                      trailing:
                          AppIcon(AppIcons.chevronRight, color: p.inkMuted),
                      onTap: () => context.push('/settings/ai'),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.x5),
                _groupLabel('DATA', p),
                _listCard(
                  p,
                  [
                    ListTile(
                      leading: AppIcon(AppIcons.download, color: p.ink),
                      title: const Text('Backup sekarang'),
                      onTap: () => _backup(context, ref),
                    ),
                    Divider(height: 1, thickness: 1, color: p.border),
                    ListTile(
                      leading: AppIcon(AppIcons.upload, color: p.ink),
                      title: const Text('Pulihkan dari backup'),
                      onTap: () => _restore(context, ref),
                    ),
                    Divider(height: 1, thickness: 1, color: p.border),
                    ListTile(
                      leading: AppIcon(AppIcons.flag, color: p.ink),
                      title: Text('Tandaan salah ketik ($flagCount)'),
                      trailing:
                          AppIcon(AppIcons.chevronRight, color: p.inkMuted),
                      onTap: () => context.push('/settings/flags'),
                    ),
                    Divider(height: 1, thickness: 1, color: p.border),
                    ListTile(
                      leading: AppIcon(AppIcons.trash, color: p.ink),
                      title: const Text('Hapus cache AI'),
                      onTap: () async {
                        await ref.read(aiCacheProvider).clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cache AI dihapus.')),
                          );
                        }
                      },
                    ),
                    Divider(height: 1, thickness: 1, color: p.border),
                    ListTile(
                      leading: AppIcon(AppIcons.trash, color: p.danger),
                      title: Text(
                        'Hapus semua data',
                        style: TextStyle(color: p.danger),
                      ),
                      onTap: () => _resetAll(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.x5),
                _groupLabel('PANDUAN', p),
                _listCard(
                  p,
                  [
                    ListTile(
                      leading: AppIcon(AppIcons.help, color: p.ink),
                      title: const Text('Tampilkan panduan awal'),
                      trailing:
                          AppIcon(AppIcons.chevronRight, color: p.inkMuted),
                      onTap: () => context.push('/onboarding'),
                    ),
                  ],
                ),
                const SizedBox(height: Sp.x6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupLabel(String text, AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Sp.x2),
      child: Text(text, style: AppText.overline.copyWith(color: p.inkMuted)),
    );
  }

  Widget _card(AppPalette p, Widget child) {
    return Container(
      padding: const EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }

  Widget _listCard(AppPalette p, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: Radii.lgAll,
        border: Border.all(color: p.border),
      ),
      child: Column(children: children),
    );
  }

  Future<void> _checkTts(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(ttsServiceProvider).isJapaneseAvailable();
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Suara Jepang tersedia.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Suara Jepang belum terpasang'),
        content: const Text(
          'Suara Jepang belum terpasang. Buka Pengaturan Android → Bahasa & input → Output text-to-speech, lalu pasang data suara Jepang.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final json = ref.read(userDataProvider.notifier).exportBackupJson();
    final saved = await FilePicker.platform.saveFile(
      fileName: 'minna_pocket_backup_${_yyyymmdd()}.json',
      bytes: utf8.encode(json),
    );
    if (saved != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup tersimpan.')),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Pulihkan dari backup'),
        content: const Text('Data saat ini akan diganti. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    final bytes = res?.files.singleOrNull?.bytes;
    if (bytes == null) return;

    try {
      await ref
          .read(userDataProvider.notifier)
          .importBackupJson(utf8.decode(bytes));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data dipulihkan.')),
        );
      }
    } on FormatException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Future<void> _resetAll(BuildContext context, WidgetRef ref) async {
    final p = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus semua data?'),
        content: const Text(
          'Seluruh progres belajar, skor, jawaban, tersimpan, dan riwayat akan dihapus permanen.',
        ),
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
    if (ok != true) return;
    await ref.read(userDataProvider.notifier).resetAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data dihapus.')),
      );
    }
  }
}
