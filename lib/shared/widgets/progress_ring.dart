// Lingkaran progres kecil. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 36, this.stroke = 4});
  final double value; // 0..1
  final double size;
  final double stroke;
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RingPainter(value.clamp(0, 1).toDouble(), stroke, p.surfaceAlt, p.primary)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.w, this.track, this.fill);
  final double v, w;
  final Color track, fill;
  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(w / 2, w / 2, s.width - w, s.height - w);
    final pt = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    c.drawArc(r, 0, math.pi * 2, false, pt..color = track);
    if (v > 0) c.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, pt..color = fill);
  }

  @override
  bool shouldRepaint(covariant _RingPainter o) => o.v != v || o.fill != fill || o.track != track;
}
