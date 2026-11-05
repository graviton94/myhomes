// A medal for an achievement, in the house style but with clean lines: two
// ribbon tails, a scalloped rim in the medal's colour, a cream face with
// the achievement's icon, and its step as stars on the rim (bronze one,
// silver two, gold three). Not earned yet: all pale.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'app_icons.dart';
import 'doodle.dart';

class MedalView extends StatelessWidget {
  const MedalView({super.key, required this.achievement, required this.medal, this.size = 64});

  final Achievement achievement;
  final Medal medal;
  final double size;

  /// Rim, face and icon colours per medal.
  static (Color, Color, Color) colors(Medal m) => switch (m) {
    Medal.gold => (const Color(0xFFF0B840), const Color(0xFFFCEFC9), const Color(0xFF855700)),
    Medal.silver => (const Color(0xFFB9B2A6), const Color(0xFFF1EEE9), const Color(0xFF5E574D)),
    Medal.bronze => (const Color(0xFFC98B5A), const Color(0xFFF6E2D1), const Color(0xFF7A4A24)),
    Medal.none => (const Color(0xFFD9CFC2), const Color(0xFFF4ECE1), const Color(0xFFA89B8C)),
  };

  @override
  Widget build(BuildContext context) {
    final (_, _, ink) = colors(medal);
    // A one-step achievement is gold at once, so it shows three stars too.
    final stars = medal == Medal.none ? 0 : medal.index;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MedalPainter(medal, stars),
        child: Align(
          alignment: const Alignment(0, -0.32),
          child: Icon(
            iconFor(achievement.icon) ?? Icons.star_rounded,
            size: size * 0.3,
            color: ink.withValues(alpha: medal == Medal.none ? 0.5 : 1),
          ),
        ),
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  const _MedalPainter(this.medal, this.stars);

  final Medal medal;
  final int stars;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final (ring, face, _) = MedalView.colors(medal);
    final lock = medal == Medal.none;
    final ink = Paint()
      ..color = lock ? const Color(0xFFCFC3B4) : Doodle.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.1, s * 0.022)
      ..strokeJoin = StrokeJoin.round;
    final ribbon = Paint()..color = lock ? const Color(0xFFE9DCCB) : Doodle.persimmon;

    Path tail(double x0, double x1, double x2) => Path()
      ..moveTo(x0 * s, 0.62 * s)
      ..lineTo(x1 * s, 0.97 * s)
      ..lineTo((x1 + x2) / 2 * s, 0.90 * s)
      ..lineTo(x2 * s, 0.97 * s)
      ..lineTo((x0 + 0.13) * s, 0.66 * s)
      ..close();
    for (final t in [tail(0.30, 0.24, 0.42), tail(0.57, 0.58, 0.76)]) {
      canvas.drawPath(t, ribbon);
      canvas.drawPath(t, ink);
    }

    final cx = s / 2, cy = s * 0.42;
    final rim = Path();
    for (var k = 0; k <= 96; k++) {
      final a = k / 96 * 2 * math.pi;
      final r = s * (0.355 + 0.018 * math.cos(a * 14));
      final p = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      k == 0 ? rim.moveTo(p.dx, p.dy) : rim.lineTo(p.dx, p.dy);
    }
    rim.close();
    canvas.drawPath(rim, Paint()..color = ring);
    canvas.drawPath(rim, ink);
    canvas.drawCircle(Offset(cx, cy), s * 0.27, Paint()..color = face);
    canvas.drawCircle(Offset(cx, cy), s * 0.27, ink);

    if (stars == 0) return;
    final r = s * 0.075, gap = r * 2.15;
    for (var k = 0; k < stars; k++) {
      final c = Offset(cx - (stars - 1) * gap / 2 + k * gap, cy + s * 0.30);
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final rr = i.isEven ? r : r * 0.45;
        final p = c + Offset(rr * math.cos(a), rr * math.sin(a));
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFF6DF));
      canvas.drawPath(star, ink..strokeWidth = math.max(1.0, s * 0.018));
    }
  }

  @override
  bool shouldRepaint(_MedalPainter old) => old.medal != medal || old.stars != stars;
}
