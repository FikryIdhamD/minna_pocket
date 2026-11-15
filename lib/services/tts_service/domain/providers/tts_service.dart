// Suara pengucapan sintetis (TTS Android) — docs/01 §4.12. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
// Selalu ucapkan BACAAN kana (JpText.reading), bukan teks kanji mentah.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../shared/domain/providers/settings_provider.dart';

class TtsService {
  TtsService(this._ref);
  final Ref _ref;
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.setLanguage('ja-JP');
    await _tts.awaitSpeakCompletion(true);
    _ready = true;
  }

  /// true jika paket suara Jepang tersedia di HP.
  Future<bool> isJapaneseAvailable() async {
    final v = await _tts.isLanguageAvailable('ja-JP');
    return v == true;
  }

  Future<void> speak(String kana) async {
    await _init();
    await _tts.setSpeechRate(_ref.read(settingsProvider).ttsRate);
    await _tts.stop();
    await _tts.speak(kana);
  }

  Future<void> stop() => _tts.stop();
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final s = TtsService(ref);
  ref.onDispose(s.stop);
  return s;
});
