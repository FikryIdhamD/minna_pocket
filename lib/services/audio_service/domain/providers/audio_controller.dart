// Pemutar audio tunggal untuk seluruh aplikasi (docs/06_Algoritma.md §5).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
//
// Pemakaian di layar:
//   final audio = ref.watch(audioControllerProvider);              // state (rebuild ±10x/detik saat main)
//   final ctl = ref.read(audioControllerProvider.notifier);
//   await ctl.open('audio/L01_kaiwa.m4a');                          // path relatif dari JSON
//   ctl.playFrom(line.t!)                                           // putar dari awal baris (lanjut terus)
//   ctl.playSegment(seg.t, tag: 'L01.mondai.1#q2')                  // putar satu segmen (jeda otomatis jika aktif)
//   ctl.toggleLoopCurrent()                                         // ulangi segmen/baris aktif terus-menerus
//   ctl.togglePlay(); ctl.stop();

import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../shared/domain/models/json_utils.dart';
import '../../../../shared/domain/providers/settings_provider.dart';
import '../../../content_service/domain/providers/content_providers.dart';

@immutable
class AudioState {
  const AudioState({
    this.source,
    this.playing = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.range,
    this.loop = false,
    this.tag,
    this.error,
  });
  final String? source; // path relatif yang sedang dimuat
  final bool playing;
  final Duration position;
  final Duration duration;

  /// Rentang aktif (segmen Mondai / baris Kaiwa yang diulang). Null = putar bebas.
  final TimeRange? range;
  final bool loop; // ulangi [range] terus
  final String? tag; // penanda pemanggil, mis. id soal yang sedang diputar
  final String? error;

  double get positionSec => position.inMilliseconds / 1000.0;
  double get progress => duration.inMilliseconds == 0 ? 0 : position.inMilliseconds / duration.inMilliseconds;

  AudioState copyWith({
    String? source,
    bool? playing,
    Duration? position,
    Duration? duration,
    TimeRange? range,
    bool clearRange = false,
    bool? loop,
    String? tag,
    bool clearTag = false,
    String? error,
  }) =>
      AudioState(
        source: source ?? this.source,
        playing: playing ?? this.playing,
        position: position ?? this.position,
        duration: duration ?? this.duration,
        range: clearRange ? null : (range ?? this.range),
        loop: loop ?? this.loop,
        tag: clearTag ? null : (tag ?? this.tag),
        error: error,
      );
}

class AudioController extends Notifier<AudioState> {
  late final AudioPlayer _player;
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _stopAtRangeEnd = false;

  @override
  AudioState build() {
    _player = AudioPlayer();
    _initSession();
    _subs.add(_player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        final auto = ref.read(settingsProvider).autoRepeat;
        if (auto) {
          _player.seek(Duration.zero);
        } else {
          _player.pause();
          _player.seek(Duration.zero);
        }
      }
      state = state.copyWith(playing: s.playing && s.processingState != ProcessingState.completed);
    }));
    _subs.add(_player.durationStream.listen((d) => state = state.copyWith(duration: d ?? Duration.zero)));
    _subs.add(_player.createPositionStream(minPeriod: const Duration(milliseconds: 80), maxPeriod: const Duration(milliseconds: 200)).listen(_onPosition));
    ref.listen<double>(settingsProvider.select((s) => s.audioSpeed), (_, v) => _player.setSpeed(v), fireImmediately: true);
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
      _player.dispose();
    });
    return const AudioState();
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  void _onPosition(Duration p) {
    final r = state.range;
    if (r != null && state.playing) {
      final sec = p.inMilliseconds / 1000.0;
      if (sec >= r.end) {
        if (state.loop) {
          _player.seek(r.startDuration);
        } else if (_stopAtRangeEnd) {
          _player.pause();
          _stopAtRangeEnd = false;
          state = state.copyWith(position: p, clearRange: true);
          return;
        }
      }
    }
    state = state.copyWith(position: p);
  }

  /// Muat file (path relatif dari JSON). Tidak memutar. Aman dipanggil berulang untuk file yang sama.
  Future<void> open(String relativePath) async {
    if (state.source == relativePath) return;
    await _player.stop();
    state = AudioState(source: relativePath);
    try {
      final env = ref.read(appEnvProvider);
      await _player.setAsset(env.asset(relativePath));
      await _player.setSpeed(ref.read(settingsProvider).audioSpeed);
    } catch (e) {
      state = state.copyWith(error: 'Audio tidak bisa diputar');
    }
  }

  Future<void> togglePlay() async {
    if (state.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    state = const AudioState();
  }

  Future<void> seek(Duration d) => _player.seek(d);

  /// Putar dari awal [t] lalu lanjut sampai akhir file (Kaiwa: tekan baris).
  Future<void> playFrom(TimeRange t, {String? tag}) async {
    _stopAtRangeEnd = false;
    state = state.copyWith(clearRange: true, loop: false, tag: tag, clearTag: tag == null);
    await _player.seek(t.startDuration);
    unawaited(_player.play());
  }

  /// Putar satu segmen. Berhenti di akhir segmen jika jeda otomatis aktif (Mondai).
  Future<void> playSegment(TimeRange t, {String? tag}) async {
    final autoPause = ref.read(settingsProvider).autoPause;
    _stopAtRangeEnd = autoPause;
    state = state.copyWith(range: t, loop: false, tag: tag, clearTag: tag == null);
    await _player.seek(t.startDuration);
    unawaited(_player.play());
  }

  /// Ulangi rentang [t] terus sampai dipanggil lagi (tekan lama baris Kaiwa / tombol 🔁).
  Future<void> loopRange(TimeRange t, {String? tag}) async {
    _stopAtRangeEnd = false;
    state = state.copyWith(range: t, loop: true, tag: tag, clearTag: tag == null);
    await _player.seek(t.startDuration);
    unawaited(_player.play());
  }

  void stopLoop() => state = state.copyWith(loop: false, clearRange: true);

  /// Tombol 🔁: aktif → ulangi rentang yang sedang/terakhir diputar; nonaktif → berhenti mengulang.
  void toggleLoopCurrent(TimeRange? current) {
    if (state.loop) {
      stopLoop();
    } else if (current != null) {
      loopRange(current, tag: state.tag);
    }
  }
}

final audioControllerProvider = NotifierProvider<AudioController, AudioState>(AudioController.new);
