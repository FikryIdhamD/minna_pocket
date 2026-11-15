// Komponen audio: MiniPlayer (Kaiwa), SegmentPlayer (Mondai), SpeedChip, AudioSettingsSheet, SegmentPlayButton.
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH. (docs/05_Spesifikasi_Layar.md §K-3)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio_service/domain/providers/audio_controller.dart';
import '../domain/models/json_utils.dart';
import '../domain/models/lesson.dart';
import '../domain/providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/text_theme.dart';
import 'app_icon.dart';

String fmtTime(Duration d) {
  final s = d.inSeconds;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Label kecepatan global; ditekan = 0.75 ↔ 1.
class SpeedChip extends ConsumerWidget {
  const SpeedChip({super.key, this.onDark = true});
  final bool onDark;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final v = ref.watch(settingsProvider.select((s) => s.audioSpeed));
    final fg = onDark ? p.onPlayer : p.ink;
    return Semantics(
      button: true,
      label: 'Kecepatan audio ${v < 1 ? '0,75' : '1'} kali. Ketuk untuk mengganti',
      child: InkWell(
        borderRadius: Radii.fullAll,
        onTap: () => ref.read(settingsProvider.notifier).toggleSpeed(),
        child: Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 56),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(borderRadius: Radii.fullAll, border: Border.all(color: fg.withAlpha(77))),
          child: Text(v < 1 ? '0.75×' : '1×', style: AppText.caption.copyWith(color: fg)),
        ),
      ),
    );
  }
}

class _PlayCircle extends StatelessWidget {
  const _PlayCircle({required this.playing, required this.onTap, this.size = 48});
  final bool playing;
  final VoidCallback onTap;
  final double size;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: playing ? 'Jeda' : 'Putar',
      child: Material(
        color: p.audio,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: AppIcon(playing ? AppIcons.pause : AppIcons.play, color: p.onAudio, size: 22)),
          ),
        ),
      ),
    );
  }
}

/// Pemutar menempel di bawah layar Kaiwa. Letakkan di Stack (Positioned bottom 16, kiri/kanan 12).
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key, required this.title});
  final String title; // mis. "CD 01 · Kaiwa"
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final a = ref.watch(audioControllerProvider);
    final ctl = ref.read(audioControllerProvider.notifier);
    return Container(
      padding: const EdgeInsets.fromLTRB(Sp.x2, Sp.x3, Sp.x3, Sp.x3),
      decoration: BoxDecoration(
        color: p.player,
        borderRadius: Radii.lgAll,
        boxShadow: [BoxShadow(color: p.ink.withAlpha(40), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        _PlayCircle(playing: a.playing, onTap: ctl.togglePlay),
        const SizedBox(width: Sp.x3),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(child: Text(title, style: AppText.caption.copyWith(color: p.onPlayer), overflow: TextOverflow.ellipsis)),
              if (a.loop) ...[AppIcon(AppIcons.repeatOne, size: 14, color: p.audio), const SizedBox(width: 6)],
              Text('${fmtTime(a.position)} / ${fmtTime(a.duration)}', style: AppText.caption.copyWith(color: p.onPlayerMuted)),
            ]),
            const SizedBox(height: Sp.x2),
            _Bar(value: a.progress, onSeek: (f) => ctl.seek(Duration(milliseconds: (a.duration.inMilliseconds * f).round()))),
          ]),
        ),
        const SizedBox(width: Sp.x3),
        const SpeedChip(),
      ]),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.onSeek});
  final double value;
  final ValueChanged<double> onSeek;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, c) {
      void seek(Offset o) => onSeek((o.dx / c.maxWidth).clamp(0.0, 1.0).toDouble());
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => seek(d.localPosition),
        onHorizontalDragUpdate: (d) => seek(d.localPosition),
        child: SizedBox(
          height: 16,
          child: Center(
            child: ClipRRect(
              borderRadius: Radii.fullAll,
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0).toDouble(),
                minHeight: 4,
                backgroundColor: p.onPlayer.withAlpha(46),
                valueColor: AlwaysStoppedAnimation(p.audio),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Pemutar bersegmen untuk satu nomor Mondai (di atas daftar soal).
class SegmentPlayer extends ConsumerWidget {
  const SegmentPlayer({super.key, required this.mondai, required this.title});
  final Mondai mondai;
  final String title; // mis. "CD 02 · Mondai 1"

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final a = ref.watch(audioControllerProvider);
    final ctl = ref.read(audioControllerProvider.notifier);
    final autoPause = ref.watch(settingsProvider.select((s) => s.autoPause));
    final segs = mondai.segments;
    final pos = a.positionSec;
    var current = -1;
    for (var i = 0; i < segs.length; i++) {
      if (pos >= segs[i].t.start - 0.05 && pos < segs[i].t.end + 0.3) current = i;
    }
    final nEx = mondai.examples.length;
    final status = current < 0
        ? '${mondai.questions.length} soal'
        : (current < nEx ? 'Contoh' : 'Soal ${current - nEx + 1} dari ${mondai.questions.length}');
    final total = mondai.duration ?? (a.duration.inMilliseconds / 1000.0);
    return Container(
      padding: const EdgeInsets.all(Sp.x4),
      decoration: BoxDecoration(color: p.player, borderRadius: Radii.lgAll),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _PlayCircle(
            playing: a.playing,
            size: 52,
            onTap: () {
              if (a.playing) {
                ctl.pause();
              } else if (current >= 0 && current + 1 < segs.length && pos >= segs[current].t.end) {
                ctl.playSegment(segs[current + 1].t);
              } else {
                ctl.togglePlay();
              }
            },
          ),
          const SizedBox(width: Sp.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.bodyStrong.copyWith(color: p.onPlayer)),
              Text('$status${autoPause ? ' · jeda otomatis' : ''}', style: AppText.caption.copyWith(color: p.onPlayerMuted)),
            ]),
          ),
          Semantics(
            button: true,
            label: 'Ulangi soal ini terus',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => ctl.toggleLoopCurrent(current >= 0 ? segs[current].t : null),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: a.loop ? p.audio.withAlpha(41) : Colors.transparent,
                  border: Border.all(color: a.loop ? p.audio : p.onPlayer.withAlpha(77)),
                ),
                child: Center(child: AppIcon(AppIcons.repeatOne, size: 20, color: a.loop ? p.audio : p.onPlayer)),
              ),
            ),
          ),
          const SizedBox(width: Sp.x2),
          const SpeedChip(),
        ]),
        const SizedBox(height: Sp.x4),
        Row(children: [
          for (var i = 0; i < segs.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              flex: ((segs[i].t.end - segs[i].t.start) * 10).round().clamp(5, 100000).toInt(),
              child: _SegBox(
                label: segs[i].label,
                done: current > i,
                current: current == i,
                fill: current == i ? ((pos - segs[i].t.start) / (segs[i].t.end - segs[i].t.start)).clamp(0.0, 1.0).toDouble() : 0,
                onTap: () => ctl.playSegment(segs[i].t, tag: '${mondai.id}#$i'),
              ),
            ),
          ],
        ]),
        const SizedBox(height: Sp.x2),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(fmtTime(a.position), style: AppText.caption.copyWith(color: p.onPlayerMuted)),
          Text(fmtTime(Duration(milliseconds: (total * 1000).round())), style: AppText.caption.copyWith(color: p.onPlayerMuted)),
        ]),
      ]),
    );
  }
}

class _SegBox extends StatelessWidget {
  const _SegBox({required this.label, required this.done, required this.current, required this.fill, required this.onTap});
  final String label;
  final bool done, current;
  final double fill;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: 'Putar segmen $label',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: done ? p.audio.withAlpha(71) : p.onPlayer.withAlpha(31),
            borderRadius: BorderRadius.circular(6),
            border: current ? Border.all(color: p.audio, width: 1.5) : null,
          ),
          child: Stack(children: [
            if (current) FractionallySizedBox(widthFactor: fill, child: Container(color: p.audio.withAlpha(71))),
            Center(child: Text(label, style: AppText.caption.copyWith(color: current || done ? p.onPlayer : p.onPlayerMuted))),
          ]),
        ),
      ),
    );
  }
}

/// Tombol ▶ bulat kecil di samping satu soal/contoh. Menampilkan ikon suara bila segmen ini sedang diputar.
class SegmentPlayButton extends ConsumerWidget {
  const SegmentPlayButton({super.key, required this.range, required this.tag});
  final TimeRange range;
  final String tag;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final a = ref.watch(audioControllerProvider);
    final on = a.playing && a.positionSec >= range.start - 0.05 && a.positionSec < range.end + 0.3;
    return Semantics(
      button: true,
      label: on ? 'Sedang diputar' : 'Putar soal ini',
      child: Material(
        color: on ? p.audio : p.surface,
        shape: CircleBorder(side: BorderSide(color: on ? p.audio : p.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => ref.read(audioControllerProvider.notifier).playSegment(range, tag: tag),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: AppIcon(on ? AppIcons.speaker : AppIcons.play, size: 18, color: on ? p.onAudio : p.ink)),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet pengaturan audio global (ikon 🎧 di app bar).
Future<void> showAudioSettingsSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _AudioSettingsSheet(),
    );

class _AudioSettingsSheet extends ConsumerWidget {
  const _AudioSettingsSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sp.screen, 0, Sp.screen, Sp.x4),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pengaturan audio', style: AppText.headline),
          const SizedBox(height: Sp.x1),
          Text('Berlaku untuk semua audio.', style: AppText.bodySm.copyWith(color: context.palette.inkMuted)),
          const SizedBox(height: Sp.x4),
          Text('Kecepatan', style: AppText.bodyStrong),
          const SizedBox(height: Sp.x2),
          SegmentedButton<double>(
            segments: const [ButtonSegment(value: 0.75, label: Text('0.75×')), ButtonSegment(value: 1.0, label: Text('1×'))],
            selected: {s.audioSpeed < 1 ? 0.75 : 1.0},
            onSelectionChanged: (v) => n.update((x) => x.copyWith(audioSpeed: v.first)),
          ),
          const SizedBox(height: Sp.x2),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Jeda otomatis tiap soal'),
            subtitle: const Text('Mondai: audio berhenti setelah tiap soal'),
            value: s.autoPause,
            onChanged: (v) => n.update((x) => x.copyWith(autoPause: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ulangi otomatis'),
            subtitle: const Text('Putar lagi dari awal saat audio selesai'),
            value: s.autoRepeat,
            onChanged: (v) => n.update((x) => x.copyWith(autoRepeat: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gulir otomatis Kaiwa'),
            subtitle: const Text('Baris yang diputar selalu terlihat'),
            value: s.kaiwaAutoScroll,
            onChanged: (v) => n.update((x) => x.copyWith(kaiwaAutoScroll: v)),
          ),
        ]),
      ),
    );
  }
}
