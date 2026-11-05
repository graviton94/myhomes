import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart' show keepWords;

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

/// One line that never wraps and is rarely cut: the first of [texts] that
/// fits (scaling down to [minScale]) is drawn; later ones are shorter forms
/// ("캠핑 랜턴 넣음 · 차 › 지우에게 빌려줌 · 3일 전" → "캠핑 랜턴 넣음 · 3일 전").
/// Only when even the last does not fit is it cut with an ellipsis.
class OneLine extends StatelessWidget {
  const OneLine(this.texts, {super.key, this.style, this.textAlign, this.minScale = 0.85});

  final List<String> texts;
  final TextStyle? style;
  final TextAlign? textAlign;
  final double minScale;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final dir = Directionality.of(context);
        var pick = texts.last;
        var scale = minScale;
        if (box.hasBoundedWidth && base.fontSize != null) {
          for (final t in texts) {
            final s = FitText.scaleFor(t, base, box.maxWidth, scaler, dir, minScale: minScale);
            final tp = TextPainter(
              text: TextSpan(
                text: t,
                style: base.copyWith(fontSize: base.fontSize! * s),
              ),
              textDirection: dir,
              textScaler: scaler,
              maxLines: 1,
            )..layout(maxWidth: box.maxWidth);
            final fits = !tp.didExceedMaxLines;
            tp.dispose();
            if (fits) {
              pick = t;
              scale = s;
              break;
            }
          }
        } else {
          pick = texts.first;
          scale = 1;
        }
        return Text(
          pick,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: base.fontSize == null ? base : base.copyWith(fontSize: base.fontSize! * scale),
        );
      },
    );
  }
}

/// Running text from data (a recipe's step, its tip): it wraps as long as it
/// needs, but only between words (keepWords). The line-break audit lets it
/// take several lines and checks that every break falls on a space.
class Prose extends StatelessWidget {
  const Prose(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(keepWords(text), style: style);
}
