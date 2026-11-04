import 'package:flutter/material.dart';

import '../design/tokens.g.dart';

/// Chips (or small buttons) on one line that scrolls sideways: a row of
/// capsules never breaks onto a second line (user request, 2026-11-04).
/// [reverse] starts at the end, for paths whose last part matters most.
class ChipLine extends StatelessWidget {
  const ChipLine({super.key, required this.children, this.spacing = AppSpace.sm, this.reverse = false});

  final List<Widget> children;
  final double spacing;
  final bool reverse;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    reverse: reverse,
    clipBehavior: Clip.none,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final (i, w) in children.indexed) ...[if (i > 0) SizedBox(width: spacing), w],
      ],
    ),
  );
}
