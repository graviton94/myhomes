import 'package:flutter/material.dart';

import 'fairy.dart';

/// The fairy drawing herself in on the splash: the finished picture
/// (assets/fairy, from the ordered character sheet) appears top to bottom as
/// a faint pencil sketch, then colours in.
class FairySketch extends StatelessWidget {
  const FairySketch({super.key, required this.progress, this.height = 176});

  /// 0 = blank, 0.75 = sketch done, 1 = finished fairy.
  final Animation<double> progress;
  final double height;

  // Grey pencil: the picture without its colour, a little lighter.
  static const _pencil = ColorFilter.matrix([
    0.3, 0.55, 0.15, 0, 40, //
    0.3, 0.55, 0.15, 0, 40, //
    0.3, 0.55, 0.15, 0, 40, //
    0, 0, 0, 0.75, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final width = height * 360 / 420;
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;
        final drawn = Curves.easeInOut.transform((t / 0.75).clamp(0.0, 1.0));
        final colour = Curves.easeOut.transform(((t - 0.68) / 0.32).clamp(0.0, 1.0));
        final picture = Fairy(FairyPose.hello, height: height);
        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (drawn > 0)
                Opacity(
                  opacity: 1 - colour,
                  child: ClipRect(
                    clipper: _Drawn(drawn),
                    child: ColorFiltered(colorFilter: _pencil, child: picture),
                  ),
                ),
              if (colour > 0)
                Opacity(
                  opacity: colour,
                  child: Transform.scale(scale: 0.96 + 0.04 * Curves.easeOutBack.transform(colour), child: picture),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The part already drawn: from the top down to [part] of the height.
class _Drawn extends CustomClipper<Rect> {
  const _Drawn(this.part);

  final double part;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, size.height * part);

  @override
  bool shouldReclip(_Drawn old) => old.part != part;
}
