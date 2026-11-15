// JpTextView — penampil teks Jepang (docs/04_Design_System.md §6.1, docs/03 §2.2).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
//
// Mode あ (kana) : teks asli tanpa furigana. Token kanji ditekan → furigana muncul (sorot salem).
// Mode Ro       : baris utama romaji, di bawahnya teks Jepang kecil abu-abu. Token kanji bergaris
//                 bawah titik-titik di kedua baris; menekan salah satu menyorot pasangannya.
// Token blank   : diganti widget dari [blankBuilder] (indeks blank mulai 0), default garis kosong.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/jp_text.dart';
import '../domain/providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/text_theme.dart';

enum JpSize { body, title, small }

typedef BlankBuilder = Widget Function(BuildContext context, int blankIndex);

class JpTextView extends ConsumerStatefulWidget {
  const JpTextView(
    this.text, {
    super.key,
    this.size = JpSize.body,
    this.color,
    this.mode,
    this.blankBuilder,
    this.interactive = true,
    this.textAlign = TextAlign.start,
    this.blankIndexOffset = 0,
  });

  final JpText text;
  final JpSize size;
  final Color? color;

  /// null = ikuti pengaturan global (tombol あ | Ro).
  final DisplayMode? mode;
  final BlankBuilder? blankBuilder;

  /// false = tidak bisa ditekan (dipakai di label/daftar).
  final bool interactive;
  final TextAlign textAlign;

  /// Ditambahkan ke indeks blank (untuk soal berbaris banyak: blank baris ke-2 melanjutkan nomor).
  final int blankIndexOffset;

  @override
  ConsumerState<JpTextView> createState() => _JpTextViewState();
}

class _JpTextViewState extends ConsumerState<JpTextView> {
  final Set<int> _on = {};
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void didUpdateWidget(covariant JpTextView old) {
    super.didUpdateWidget(old);
    if (!identical(old.text, widget.text)) _on.clear();
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _toggle(int i) => setState(() => _on.contains(i) ? _on.remove(i) : _on.add(i));

  TapGestureRecognizer? _tap(int i) {
    if (!widget.interactive) return null;
    final r = TapGestureRecognizer()..onTap = () => _toggle(i);
    _recognizers.add(r);
    return r;
  }

  TextStyle _baseStyle(double scale) => switch (widget.size) {
        JpSize.title => AppText.jpTitle(scale),
        JpSize.small => AppText.jpSm(scale),
        JpSize.body => AppText.jp(scale),
      };

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final settings = ref.watch(settingsProvider);
    final mode = widget.mode ?? settings.displayMode;
    final scale = settings.textScale;
    final p = context.palette;
    final color = widget.color ?? p.ink;
    if (mode == DisplayMode.romaji) return _buildRomaji(context, scale, color, p);
    return _buildKana(context, scale, color, p);
  }

  Widget _blank(BuildContext context, int idx, AppPalette p, double scale) {
    final b = widget.blankBuilder;
    if (b != null) return b(context, idx + widget.blankIndexOffset);
    return Container(
      width: 64 * scale,
      height: 24 * scale,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.inkSubtle, width: 1.5))),
    );
  }

  // ------------------------------------------------------------------ mode あ
  Widget _buildKana(BuildContext context, double scale, Color color, AppPalette p) {
    final base = _baseStyle(scale).copyWith(color: color);
    final furi = AppText.furigana(scale).copyWith(color: p.primaryStrong);
    final spans = <InlineSpan>[];
    var blankIdx = 0;
    for (var i = 0; i < widget.text.tokens.length; i++) {
      final t = widget.text.tokens[i];
      final deco = t.u ? TextDecoration.underline : TextDecoration.none;
      if (t.blank) {
        final idx = blankIdx++;
        spans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: _blank(context, idx, p, scale)));
      } else if (t.k) {
        final on = _on.contains(i);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.interactive ? () => _toggle(i) : null,
            child: CustomPaint(
              foregroundPainter: on ? _FuriganaPainter(t.r ?? '', furi) : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: on ? p.highlight : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(t.s, style: base.copyWith(decoration: deco)),
              ),
            ),
          ),
        ));
      } else {
        spans.add(TextSpan(text: t.s, style: base.copyWith(decoration: deco)));
      }
    }
    return Text.rich(TextSpan(children: spans, style: base), textAlign: widget.textAlign);
  }

  // ------------------------------------------------------------------ mode Ro
  Widget _buildRomaji(BuildContext context, double scale, Color color, AppPalette p) {
    final roStyle = AppText.romaji(scale).copyWith(color: color);
    final jpStyle = AppText.jpUnderRomaji(scale).copyWith(color: p.inkSubtle);
    final dotted = TextDecoration.underline;
    final roSpans = <InlineSpan>[];
    final jpSpans = <InlineSpan>[];
    var blankIdx = 0;
    var first = true;
    for (var i = 0; i < widget.text.tokens.length; i++) {
      final t = widget.text.tokens[i];
      if (t.blank) {
        final idx = blankIdx++;
        roSpans.add(WidgetSpan(alignment: PlaceholderAlignment.middle, child: _blank(context, idx, p, scale)));
        jpSpans.add(TextSpan(text: '＿', style: jpStyle));
        continue;
      }
      var ro = t.ro;
      if (first) {
        ro = ro.trimLeft();
        first = false;
      }
      if (t.k) {
        final on = _on.contains(i);
        final lead = ro.length - ro.trimLeft().length;
        if (lead > 0) roSpans.add(TextSpan(text: ro.substring(0, lead), style: roStyle));
        roSpans.add(TextSpan(
          text: ro.substring(lead),
          recognizer: _tap(i),
          style: roStyle.copyWith(
            decoration: dotted,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: p.primary,
            decorationThickness: 2,
            backgroundColor: on ? p.highlight : null,
          ),
        ));
        jpSpans.add(TextSpan(
          text: t.s,
          recognizer: _tap(i),
          style: jpStyle.copyWith(
            decoration: dotted,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: p.primary,
            backgroundColor: on ? p.highlight : null,
            color: on ? p.ink : jpStyle.color,
          ),
        ));
      } else {
        roSpans.add(TextSpan(
          text: ro,
          style: roStyle.copyWith(decoration: t.u ? TextDecoration.underline : TextDecoration.none),
        ));
        jpSpans.add(TextSpan(text: t.s, style: jpStyle));
      }
    }
    final cross = widget.textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: cross,
      children: [
        Text.rich(TextSpan(children: roSpans), textAlign: widget.textAlign),
        Text.rich(TextSpan(children: jpSpans), textAlign: widget.textAlign),
      ],
    );
  }
}

/// Menggambar furigana di atas kotak kanji tanpa mengubah layout (memakai ruang tinggi-baris).
class _FuriganaPainter extends CustomPainter {
  _FuriganaPainter(this.text, this.style);
  final String text;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    final dx = (size.width - tp.width) / 2;
    final dy = -tp.height + 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _FuriganaPainter old) => old.text != text || old.style != style;
}

/// Label Jepang statis tanpa interaksi & selalu mode あ (untuk daftar, judul kartu, chip).
class JpLabel extends StatelessWidget {
  const JpLabel(this.text, {super.key, this.style, this.maxLines, this.overflow});
  final JpText text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(
        text.jp,
        style: style ?? AppText.jpSm(1).copyWith(color: context.palette.ink),
        maxLines: maxLines,
        overflow: overflow,
      );
}
