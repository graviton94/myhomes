import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../widgets/doodle.dart';

/// A small drawing of a template: rooms as green blocks with crayon edges,
/// the balcony honey and dashed-looking (hatched).
class PlanPreview extends StatelessWidget {
  const PlanPreview({super.key, required this.template});

  final HouseTemplate template;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: template.cols / template.rows,
    child: CustomPaint(painter: _PreviewPainter(template)),
  );
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter(this.t);

  final HouseTemplate t;

  static const _room = Color(0xFFE3EEDC);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / t.cols;
    final ink = Doodle.line(Doodle.ink, 1.2);
    for (final (i, r) in t.rooms.indexed) {
      final rect = Rect.fromLTWH(r.rect.x * cell, r.rect.y * cell, r.rect.w * cell, r.rect.h * cell).deflate(1);
      final path = Path()..addRect(rect);
      final balcony = r.key == 'balcony';
      canvas.drawPath(path, Paint()..color = balcony ? Doodle.honeyLight : _room);
      if (balcony) Doodle.hatch(canvas, path, Doodle.honey, gap: 4, width: 0.8);
      Doodle.crayon(canvas, path, ink, wobble: 0.6, step: 2, seed: i + 1);
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) => old.t != t;
}
