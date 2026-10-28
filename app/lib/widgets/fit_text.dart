import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Text whose lines are set by the words themselves: each "\n" in the ARB
/// string starts a line at a natural break ("1개 남음" / "2개는 있어야 해요"),
/// and the font shrinks just enough for the widest line to fit the column,
/// down to [minScale]. Only a line still too wide at that size wraps, and
/// then between words (widgets/keep_words.dart).
class FitText extends StatelessWidget {
  const FitText(this.text, {super.key, this.style, this.textAlign, this.minScale = 0.78});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double minScale;

  /// The size factor that fits [text]'s widest line into [width].
  static double scaleFor(String text, TextStyle style, double width, TextScaler scaler, TextDirection dir, {double minScale = 0.78}) {
    var widest = 0.0;
    for (final line in text.split('\n')) {
      final tp = TextPainter(
        text: TextSpan(text: line, style: style),
        textDirection: dir,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, tp.width);
      tp.dispose();
    }
    // A hair of room for rounding, so a line that just fits is not wrapped.
    final room = width - 1;
    return widest <= room ? 1 : math.max(minScale, room / widest);
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.hasBoundedWidth || base.fontSize == null) return Text(text, style: base, textAlign: textAlign);
        final scale = scaleFor(text, base, box.maxWidth, MediaQuery.textScalerOf(context), Directionality.of(context), minScale: minScale);
        return Text(
          text,
          style: base.copyWith(fontSize: base.fontSize! * scale, height: base.height),
          textAlign: textAlign,
        );
      },
    );
  }
}
