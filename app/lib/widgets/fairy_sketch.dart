import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_parsing/path_parsing.dart';

import 'doodle.dart';
import 'fairy.dart';

/// The fairy drawing itself in, line by line, the way a crayon sketch is
/// made: legs, body, face, hat, ribbon, eyes, cheeks, waving arm and star.
/// Then the finished (baked) fairy fades in over the lines. Paths come from
/// design/fairy/parts.svg (base shape + "hello" eyes and arms), in the same
/// -10 -8 140 163 view box tool/bake_fairy.mjs bakes the images with, so the
/// lines sit exactly under the finished picture.
class FairySketch extends StatelessWidget {
  const FairySketch({super.key, required this.progress, this.height = 176});

  /// 0 = blank, 0.75 = lines done, 1 = finished fairy.
  final Animation<double> progress;
  final double height;

  static const _ink = Color(0xFF3F2E22);
  static const _ribbon = Color(0xFFBF4F24);
  static const _cheek = Color(0xFFEE8F80);
  static const _star = Color(0xFFF2B33D);

  static final List<_Stroke> _strokes = [
    _Stroke(_svg('M52 106 L49 126 L43 128 M68 106 L71 126 L77 128'), _ink, 3.2),
    _Stroke(
      _svg(
        'M40 68 C37 86 33 97 26 108 C33 104 38 110 45 106 C51 111 55 105 60 110 C65 105 69 111 75 106 C82 110 87 104 94 108 C87 97 83 86 80 68 Z',
      ),
      _ink,
      3.2,
    ),
    _Stroke(Path()..addOval(Rect.fromCircle(center: const Offset(60, 54), radius: 25)), _ink, 3.2),
    _Stroke(_svg('M40 37 Q50 24 58 6 Q63 14 74 13 Q69 20 80 37 Q60 31 40 37 Z'), _ink, 3.2),
    _Stroke(_svg('M31 39 Q60 29 89 39 Q86 44 82 43 Q60 35 38 43 Q34 44 31 39 Z'), _ink, 3.2),
    _Stroke(_svg('M43 76 Q60 83 77 76'), _ribbon, 4.5),
    _Stroke(
      Path()
        ..addOval(Rect.fromCenter(center: const Offset(51, 54), width: 6.8, height: 10.4))
        ..addOval(Rect.fromCenter(center: const Offset(69, 54), width: 6.8, height: 10.4)),
      _ink,
      2,
      fill: true,
    ),
    _Stroke(_svg('M39 63 l3 -3 l2 3 l3 -3 l2 3 M71 63 l3 -3 l2 3 l3 -3 l2 3'), _cheek, 2.2),
    _Stroke(_svg('M40 86 L25 76 L20 66 M80 86 L98 77 L108 60'), _ink, 3.2),
    _Stroke(_starAt(109, 55, 1), _star, 2.4),
    _Stroke(_starAt(61, 25, .9), _star, 2.2),
  ];

  static Path _svg(String d) {
    final p = _PathBuilder();
    writeSvgPathDataToPath(d, p);
    return p.path;
  }

  static Path _starAt(double x, double y, double s) =>
      _svg('M0 -6 L1.53 -2.1 L5.71 -1.85 L2.47 0.8 L3.53 4.85 L0 2.6 L-3.53 4.85 L-2.47 0.8 L-5.71 -1.85 L-1.53 -2.1 Z').transform(
        (Matrix4.identity()
              ..translateByDouble(x, y, 0, 1)
              ..scaleByDouble(s, s, 1, 1))
            .storage,
      );

  @override
  Widget build(BuildContext context) {
    final width = height * 360 / 420;
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;
        final lines = (t / 0.75).clamp(0.0, 1.0);
        final colour = Curves.easeOut.transform(((t - 0.68) / 0.32).clamp(0.0, 1.0));
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1 - colour,
                child: CustomPaint(painter: _SketchPainter(_strokes, lines)),
              ),
              if (colour > 0)
                Opacity(
                  opacity: colour,
                  child: Transform.scale(
                    scale: 0.96 + 0.04 * Curves.easeOutBack.transform(colour),
                    child: Fairy(FairyPose.hello, height: height),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Stroke {
  _Stroke(this.path, this.color, this.width, {this.fill = false}) : length = path.computeMetrics().fold(0.0, (n, m) => n + m.length);

  final Path path;
  final Color color;
  final double width;
  final double length;

  /// Filled once its outline is complete (the eyes).
  final bool fill;
}

class _SketchPainter extends CustomPainter {
  _SketchPainter(this.strokes, this.t);

  final List<_Stroke> strokes;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 140, size.height / 163);
    canvas.translate(10, 8);
    // Each stroke gets time in proportion to its length, like a hand drawing it.
    final total = strokes.fold(0.0, (n, s) => n + s.length);
    var budget = t * total;
    Offset? tip;
    for (final s in strokes) {
      if (budget <= 0) break;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (budget >= s.length) {
        canvas.drawPath(s.path, paint);
        if (s.fill) canvas.drawPath(s.path, paint..style = PaintingStyle.fill);
      } else {
        var left = budget;
        for (final m in s.path.computeMetrics()) {
          if (left <= 0) break;
          final upTo = left.clamp(0, m.length).toDouble();
          canvas.drawPath(m.extractPath(0, upTo), paint);
          tip = m.getTangentForOffset(upTo)?.position ?? tip;
          left -= m.length;
        }
      }
      budget -= s.length;
    }
    if (tip != null && t > 0 && t < 1) _pencil(canvas, tip);
  }

  /// A crayon-drawn pencil whose point sits on the line being drawn: honey
  /// body with hatching, sharpened wood, a pink eraser, wobbly brown outline.
  void _pencil(Canvas canvas, Offset tip) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(-0.75); // leaning up and to the right, like a right hand
    final outline = Path()
      ..moveTo(0, 0)
      ..lineTo(-3.6, -8)
      ..lineTo(-3.6, -36.5)
      ..quadraticBezierTo(-3.6, -39.5, 0, -39.5)
      ..quadraticBezierTo(3.6, -39.5, 3.6, -36.5)
      ..lineTo(3.6, -8)
      ..close();
    final body = Path()..addRect(const Rect.fromLTRB(-3.6, -31, 3.6, -8));
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(-3.6, -8)
        ..lineTo(3.6, -8)
        ..close(),
      Paint()..color = Doodle.honeyLight,
    );
    canvas.drawPath(body, Paint()..color = Doodle.honey);
    Doodle.hatch(canvas, body, Doodle.persimmonLight, gap: 2.4, width: 0.7);
    canvas.drawPath(Path()..addRect(const Rect.fromLTRB(-3.6, -35, 3.6, -31)), Paint()..color = Doodle.cream);
    canvas.drawPath(
      Path()
        ..addRRect(RRect.fromLTRBAndCorners(-3.6, -39.5, 3.6, -35, topLeft: const Radius.circular(3), topRight: const Radius.circular(3))),
      Paint()..color = Doodle.cheek,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(-1.4, -3.2)
        ..lineTo(1.4, -3.2)
        ..close(),
      Paint()..color = Doodle.ink,
    );
    final ink = Doodle.line(Doodle.ink, 1.3);
    Doodle.crayon(canvas, outline, ink, wobble: 0.5, step: 1.5, seed: 11);
    Doodle.crayon(
      canvas,
      Path()
        ..moveTo(-3.6, -8)
        ..lineTo(3.6, -8)
        ..moveTo(-3.6, -31)
        ..lineTo(3.6, -31)
        ..moveTo(-3.6, -35)
        ..lineTo(3.6, -35),
      ink,
      wobble: 0.4,
      step: 1.2,
      seed: 12,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SketchPainter old) => old.t != t;
}

class _PathBuilder extends PathProxy {
  final path = ui.Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
