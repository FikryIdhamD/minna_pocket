// Pengaturan global aplikasi (docs/05_Spesifikasi_Layar.md §S-30 Settings).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Di-override di main_bookN.dart dengan instance yang sudah dimuat.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider harus di-override di main'),
);

enum DisplayMode { kana, romaji }

enum AiProvider { anthropic, gemini, openai }

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.textScale = 1.0,
    this.displayMode = DisplayMode.kana,
    this.showTranslation = false,
    this.audioSpeed = 1.0,
    this.autoPause = true,
    this.autoRepeat = false,
    this.kaiwaAutoScroll = true,
    this.ttsRate = 0.45,
    this.newCardsPerDay = 10,
    this.aiProvider = AiProvider.anthropic,
    this.aiModel = '',
    this.reviewReminderDays = 30,
  });

  final ThemeMode themeMode;
  final double textScale; // 0.9 | 1.0 | 1.15 | 1.3
  final DisplayMode displayMode; // tombol あ | Ro
  final bool showTranslation; // terjemahan default tampil?
  final double audioSpeed; // 0.75 | 1.0  (global)
  final bool autoPause; // Mondai: berhenti di akhir tiap segmen
  final bool autoRepeat; // ulangi audio saat selesai
  final bool kaiwaAutoScroll;
  final double ttsRate; // 0.3..0.6
  final int newCardsPerDay; // 5 | 10 | 20
  final AiProvider aiProvider;
  final String aiModel; // kosong = pakai default penyedia (07_Fitur_AI §2)
  final int reviewReminderDays; // pengingat backup

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? textScale,
    DisplayMode? displayMode,
    bool? showTranslation,
    double? audioSpeed,
    bool? autoPause,
    bool? autoRepeat,
    bool? kaiwaAutoScroll,
    double? ttsRate,
    int? newCardsPerDay,
    AiProvider? aiProvider,
    String? aiModel,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        textScale: textScale ?? this.textScale,
        displayMode: displayMode ?? this.displayMode,
        showTranslation: showTranslation ?? this.showTranslation,
        audioSpeed: audioSpeed ?? this.audioSpeed,
        autoPause: autoPause ?? this.autoPause,
        autoRepeat: autoRepeat ?? this.autoRepeat,
        kaiwaAutoScroll: kaiwaAutoScroll ?? this.kaiwaAutoScroll,
        ttsRate: ttsRate ?? this.ttsRate,
        newCardsPerDay: newCardsPerDay ?? this.newCardsPerDay,
        aiProvider: aiProvider ?? this.aiProvider,
        aiModel: aiModel ?? this.aiModel,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _p = 'settings.';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final p = _prefs;
    return AppSettings(
      themeMode: ThemeMode.values[p.getInt('${_p}themeMode') ?? 0],
      textScale: p.getDouble('${_p}textScale') ?? 1.0,
      displayMode: DisplayMode.values[p.getInt('${_p}displayMode') ?? 0],
      showTranslation: p.getBool('${_p}showTranslation') ?? false,
      audioSpeed: p.getDouble('${_p}audioSpeed') ?? 1.0,
      autoPause: p.getBool('${_p}autoPause') ?? true,
      autoRepeat: p.getBool('${_p}autoRepeat') ?? false,
      kaiwaAutoScroll: p.getBool('${_p}kaiwaAutoScroll') ?? true,
      ttsRate: p.getDouble('${_p}ttsRate') ?? 0.45,
      newCardsPerDay: p.getInt('${_p}newCardsPerDay') ?? 10,
      aiProvider: AiProvider.values[p.getInt('${_p}aiProvider') ?? 0],
      aiModel: p.getString('${_p}aiModel') ?? '',
    );
  }

  Future<void> _save(AppSettings s) async {
    state = s;
    final p = _prefs;
    await p.setInt('${_p}themeMode', s.themeMode.index);
    await p.setDouble('${_p}textScale', s.textScale);
    await p.setInt('${_p}displayMode', s.displayMode.index);
    await p.setBool('${_p}showTranslation', s.showTranslation);
    await p.setDouble('${_p}audioSpeed', s.audioSpeed);
    await p.setBool('${_p}autoPause', s.autoPause);
    await p.setBool('${_p}autoRepeat', s.autoRepeat);
    await p.setBool('${_p}kaiwaAutoScroll', s.kaiwaAutoScroll);
    await p.setDouble('${_p}ttsRate', s.ttsRate);
    await p.setInt('${_p}newCardsPerDay', s.newCardsPerDay);
    await p.setInt('${_p}aiProvider', s.aiProvider.index);
    await p.setString('${_p}aiModel', s.aiModel);
  }

  Future<void> update(AppSettings Function(AppSettings) f) => _save(f(state));

  Future<void> toggleDisplayMode() => update((s) =>
      s.copyWith(displayMode: s.displayMode == DisplayMode.kana ? DisplayMode.romaji : DisplayMode.kana));

  /// Label kecepatan ditekan: 0.75 ↔ 1.0
  Future<void> toggleSpeed() => update((s) => s.copyWith(audioSpeed: s.audioSpeed < 1.0 ? 1.0 : 0.75));
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
