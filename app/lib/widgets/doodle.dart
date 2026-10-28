import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The house style for every drawn graphic (CLAUDE.md): brown crayon lines
/// that wobble a little, flat fills from the fairy's palette, hatching for
/// shading. Colours are the ones in design/fairy/parts.svg.
abstract final class Doodle {
  static const ink = Color(0xFF3F2E22);
  static const cream = Color(0xFFFFFDF8);
  static const honey = Color(0xFFF2B33D);
  static const honeyLight = Color(0xFFFCEFC9);
  static const persimmon = Color(0xFFBF4F24);
  static const persimmonLight = Color(0xFFEFA27C);
  static const cheek = Color(0xFFEE8F80);

  static Paint line(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Draws [path] (up to [upTo] of its length) as a slightly shaky crayon line.
  /// [wobble] is in the canvas's units; [seed] keeps the shake the same each frame.
  static void crayon(Canvas canvas, Path path, Paint paint, {double upTo = 1, double wobble = 1.1, double step = 2.5, int seed = 1}) {
    final rnd = math.Random(seed);
    for (final m in path.computeMetrics()) {
      final end = m.length * upTo;
      if (end <= 0) continue;
      final pts = <Offset>[];
      for (var d = 0.0; d <= end; d += step) {
        final tan = m.getTangentForOffset(d)!;
        final n = Offset(-tan.vector.dy, tan.vector.dx);
        pts.add(tan.position + n * ((rnd.nextDouble() - 0.5) * wobble));
      }
      final last = m.getTangentForOffset(end);
      if (last != null) pts.add(last.position);
      if (pts.length < 2) continue;
      canvas.drawPath(Path()..addPolygon(pts, m.isClosed && upTo >= 1), paint);
    }
  }

  /// Parallel hatch lines inside [clip], like the fairy's hat.
  static void hatch(Canvas canvas, Path clip, Color color, {double gap = 3, double angle = 0.6, double width = 1}) {
    final b = clip.getBounds();
    canvas.save();
    canvas.clipPath(clip);
    final paint = line(color, width);
    final d = b.longestSide * 2;
    final dir = Offset(math.cos(angle), math.sin(angle));
    final n = Offset(-dir.dy, dir.dx);
    for (var k = -d; k <= d; k += gap) {
      final c = b.center + n * k;
      canvas.drawLine(c - dir * d, c + dir * d, paint);
    }
    canvas.restore();
  }
}

/// A megaphone in the house style, for the "last change" line.
class DoodleMegaphone extends StatelessWidget {
  const DoodleMegaphone({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MegaphonePainter()),
  );
}

class _MegaphonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    // Cone opening to the right, a little handle under it, sound lines.
    final cone = Path()
      ..moveTo(3, 9.5)
      ..lineTo(7, 9.2)
      ..lineTo(15.5, 4.2)
      ..quadraticBezierTo(17, 3.8, 17, 5.3)
      ..lineTo(17, 17.7)
      ..quadraticBezierTo(17, 19.2, 15.5, 18.8)
      ..lineTo(7, 14.2)
      ..lineTo(3, 14)
      ..close();
    final handle = Path()
      ..moveTo(7.2, 14.3)
      ..lineTo(8.6, 19.6)
      ..quadraticBezierTo(9, 20.6, 10, 20.3)
      ..lineTo(11, 20)
      ..lineTo(10.4, 15.6);
    canvas.drawPath(cone, Paint()..color = Doodle.honey);
    // Shading on the narrow end, kept inside the cone.
    canvas.save();
    canvas.clipPath(cone);
    Doodle.hatch(canvas, Path()..addRect(const Rect.fromLTRB(3, 3, 9.5, 15)), Doodle.persimmonLight, gap: 2.2, width: 0.8);
    canvas.restore();
    canvas.drawPath(handle, Paint()..color = Doodle.cream);
    final ink = Doodle.line(Doodle.ink, 1.5);
    Doodle.crayon(canvas, cone, ink, wobble: 0.45, step: 1.2, seed: 3);
    Doodle.crayon(canvas, handle, ink, wobble: 0.45, step: 1.2, seed: 4);
    Doodle.crayon(
      canvas,
      Path()
        ..moveTo(7, 9.2)
        ..lineTo(7, 14.2),
      ink,
      wobble: 0.3,
      step: 1,
      seed: 5,
    );
    final sound = Doodle.line(Doodle.persimmon, 1.6);
    Doodle.crayon(
      canvas,
      Path()
        ..moveTo(19.3, 9)
        ..quadraticBezierTo(20.6, 11.5, 19.3, 14),
      sound,
      wobble: 0.4,
      step: 1,
      seed: 6,
    );
    Doodle.crayon(
      canvas,
      Path()
        ..moveTo(21.3, 6.6)
        ..quadraticBezierTo(23.6, 11.5, 21.3, 16.4),
      sound,
      wobble: 0.4,
      step: 1,
      seed: 7,
    );
  }

  @override
  bool shouldRepaint(_MegaphonePainter old) => false;
}
