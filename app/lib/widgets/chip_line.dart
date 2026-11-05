import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

/// Chips (or small buttons) on one line that scrolls sideways: a row of
/// capsules never breaks onto a second line (user request, 2026-11-04).
/// When more is hidden past the edge, that edge fades out so it reads as
/// "slide for more". [reverse] starts at the end, for paths whose last part
/// matters most. Rows with a fixed number of things use fixed cells instead.
class ChipLine extends StatefulWidget {
  const ChipLine({super.key, required this.children, this.spacing = AppSpace.sm, this.reverse = false});

  final List<Widget> children;
  final double spacing;
  final bool reverse;

  @override
  State<ChipLine> createState() => _ChipLineState();
}

class _ChipLineState extends State<ChipLine> {
  bool _moreStart = false, _moreEnd = false;

  bool _measure(ScrollMetrics m) {
    final start = m.extentBefore > 0.5, end = m.extentAfter > 0.5;
    if (start != _moreStart || end != _moreEnd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _moreStart = start;
            _moreEnd = end;
          });
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // In a reversed line the scroll "start" is the right edge.
    final (left, right) = widget.reverse ? (_moreEnd, _moreStart) : (_moreStart, _moreEnd);
    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: widget.reverse,
      // Clipped only while faded, so the fade is what shows at the edge.
      clipBehavior: left || right ? Clip.hardEdge : Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final (i, w) in widget.children.indexed) ...[if (i > 0) SizedBox(width: widget.spacing), w],
        ],
      ),
    );
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _measure(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => _measure(n.metrics),
        child: !left && !right
            ? row
            : ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) => LinearGradient(
                  colors: [left ? Colors.transparent : Colors.black, Colors.black, Colors.black, right ? Colors.transparent : Colors.black],
                  stops: [0, 32 / r.width, 1 - 32 / r.width, 1],
                ).createShader(r),
                child: row,
              ),
      ),
    );
  }
}
