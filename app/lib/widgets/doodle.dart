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

  /// The app's leaf green (design/tokens.json secondary, dark-mode tone), for sprouts.
  static const leaf = Color(0xFF6FA565);

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

/// A report page with three bars, in the house style (home's report tile).
class DoodleReport extends StatelessWidget {
  const DoodleReport({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _ReportPainter()),
  );
}

class _ReportPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final page = Path()..addRRect(RRect.fromLTRBR(4, 3, 20, 21, const Radius.circular(2)));
    canvas.drawPath(page, Paint()..color = Doodle.cream);
    final ink = Doodle.line(Doodle.ink, 1.4);
    final bars = [(7.0, 14.0, Doodle.honey), (11.0, 10.0, Doodle.persimmonLight), (15.0, 7.5, Doodle.persimmon)];
    for (final (i, (x, top, color)) in bars.indexed) {
      final bar = Path()..addRect(Rect.fromLTRB(x, top, x + 2.6, 18));
      canvas.drawPath(bar, Paint()..color = color);
      Doodle.hatch(canvas, bar, Doodle.ink.withValues(alpha: 0.25), gap: 1.6, width: 0.5);
      Doodle.crayon(canvas, bar, Doodle.line(Doodle.ink, 0.9), wobble: 0.3, step: 1, seed: 20 + i);
    }
    Doodle.crayon(canvas, page, ink, wobble: 0.45, step: 1.2, seed: 11);
  }

  @override
  bool shouldRepaint(_ReportPainter old) => false;
}

/// A light bulb with a little glow, in the house style (one-time tips).
class DoodleBulb extends StatelessWidget {
  const DoodleBulb({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _BulbPainter()),
  );
}

class _BulbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final glass = Path()
      ..moveTo(9, 16)
      ..quadraticBezierTo(5, 12.5, 6.5, 8)
      ..quadraticBezierTo(8.5, 3.5, 12, 3.5)
      ..quadraticBezierTo(15.5, 3.5, 17.5, 8)
      ..quadraticBezierTo(19, 12.5, 15, 16)
      ..close();
    final base = Path()..addRRect(RRect.fromLTRBR(9, 16.5, 15, 20, const Radius.circular(1.2)));
    canvas.drawPath(glass, Paint()..color = Doodle.honey);
    Doodle.hatch(canvas, Path()..addRect(const Rect.fromLTRB(5, 9, 12, 17)), Doodle.persimmonLight, gap: 2, width: 0.7);
    canvas.drawPath(glass, Paint()..color = Doodle.honey.withValues(alpha: 0.55));
    canvas.drawPath(base, Paint()..color = Doodle.cream);
    final ink = Doodle.line(Doodle.ink, 1.4);
    Doodle.crayon(canvas, glass, ink, wobble: 0.45, step: 1.2, seed: 31);
    Doodle.crayon(canvas, base, ink, wobble: 0.35, step: 1, seed: 32);
    final glow = Doodle.line(Doodle.persimmon, 1.3);
    for (final (i, (a, b)) in [
      (const Offset(3, 4), const Offset(4.6, 5.4)),
      (const Offset(21, 4), const Offset(19.4, 5.4)),
      (const Offset(12, 0.6), const Offset(12, 2)),
    ].indexed) {
      Doodle.crayon(
        canvas,
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy),
        glow,
        wobble: 0.2,
        step: 0.6,
        seed: 40 + i,
      );
    }
  }

  @override
  bool shouldRepaint(_BulbPainter old) => false;
}

/// The fairy's mark for each growth stage: a sprout, an apron, a key ring,
/// a cape, a crown. Drawn in the house style.
class DoodleStageMark extends StatelessWidget {
  const DoodleStageMark(this.stage, {super.key, this.size = 24});

  /// 0 sprout · 1 little · 2 keeper · 3 steady · 4 guardian.
  final int stage;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _StagePainter(stage)),
  );
}

class _StagePainter extends CustomPainter {
  _StagePainter(this.stage);

  final int stage;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final ink = Doodle.line(Doodle.ink, 1.4);
    void fillDraw(Path p, Color c, int seed, {bool hatch = false}) {
      canvas.drawPath(p, Paint()..color = c);
      if (hatch) Doodle.hatch(canvas, p, Doodle.ink.withValues(alpha: 0.22), gap: 1.8, width: 0.6);
      Doodle.crayon(canvas, p, ink, wobble: 0.45, step: 1.1, seed: seed);
    }

    switch (stage) {
      case 0: // sprout: a stem and two leaves
        Doodle.crayon(
          canvas,
          Path()
            ..moveTo(12, 21)
            ..quadraticBezierTo(12, 15, 12, 11),
          ink,
          wobble: 0.3,
          step: 1,
          seed: 50,
        );
        fillDraw(
          Path()
            ..moveTo(12, 12)
            ..quadraticBezierTo(5, 12, 4, 6)
            ..quadraticBezierTo(10, 5, 12, 12)
            ..close(),
          Doodle.leaf,
          51,
          hatch: true,
        );
        fillDraw(
          Path()
            ..moveTo(12, 11)
            ..quadraticBezierTo(18, 9, 20, 4)
            ..quadraticBezierTo(13, 4, 12, 11)
            ..close(),
          Doodle.leaf,
          52,
        );
      case 1: // apron with a pocket
        fillDraw(
          Path()
            ..moveTo(8, 4)
            ..lineTo(16, 4)
            ..lineTo(16, 9)
            ..quadraticBezierTo(20, 10, 19, 20)
            ..lineTo(5, 20)
            ..quadraticBezierTo(4, 10, 8, 9)
            ..close(),
          Doodle.persimmonLight,
          53,
          hatch: true,
        );
        fillDraw(Path()..addRRect(RRect.fromLTRBR(9, 13, 15, 17, const Radius.circular(1))), Doodle.cream, 54);
      case 2: // key ring with two keys
        Doodle.crayon(canvas, Path()..addOval(const Rect.fromLTRB(4, 3, 12, 11)), ink, wobble: 0.35, step: 1, seed: 55);
        for (final (i, x) in [10.0, 14.0].indexed) {
          final key = Path()
            ..addOval(Rect.fromCircle(center: Offset(x, 11), radius: 2.6))
            ..moveTo(x + 1, 13)
            ..lineTo(x + 6, 20)
            ..moveTo(x + 4, 17.5)
            ..lineTo(x + 6, 16);
          canvas.drawCircle(Offset(x, 11), 2.6, Paint()..color = Doodle.honey);
          Doodle.crayon(canvas, key, ink, wobble: 0.35, step: 0.9, seed: 56 + i);
        }
      case 3: // cape
        fillDraw(
          Path()
            ..moveTo(9, 4)
            ..lineTo(15, 4)
            ..quadraticBezierTo(20, 12, 21, 20)
            ..quadraticBezierTo(12, 17, 3, 20)
            ..quadraticBezierTo(4, 12, 9, 4)
            ..close(),
          Doodle.persimmon,
          58,
          hatch: true,
        );
        canvas.drawCircle(const Offset(12, 5), 1.8, Paint()..color = Doodle.honey);
      default: // crown
        fillDraw(
          Path()
            ..moveTo(4, 18)
            ..lineTo(4, 8)
            ..lineTo(8.5, 12)
            ..lineTo(12, 5)
            ..lineTo(15.5, 12)
            ..lineTo(20, 8)
            ..lineTo(20, 18)
            ..close(),
          Doodle.honey,
          59,
          hatch: true,
        );
        for (final x in [8.0, 12.0, 16.0]) {
          canvas.drawCircle(Offset(x, 15), 1.2, Paint()..color = Doodle.persimmon);
        }
    }
  }

  @override
  bool shouldRepaint(_StagePainter old) => old.stage != stage;
}
