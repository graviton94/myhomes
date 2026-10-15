import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../design/theme.dart';
import '../design/tokens.g.dart';

/// Item category; decides the slot's soft colour when there is no photo.
enum ItemCategory { food, household, tools, medicine, other }

/// One square in a container's inventory grid.
class InventorySlot extends StatelessWidget {
  const InventorySlot({
    super.key,
    this.icon,
    this.category = ItemCategory.other,
    this.quantity,
    this.expiring = false,
    this.selected = false,
    this.chosen,
    this.semanticLabel,
    this.size = AppSize.slot,
  });

  /// Null means an empty slot.
  final IconData? icon;
  final ItemCategory category;
  final int? quantity;
  final bool expiring;

  /// Currently open in the item sheet.
  final bool selected;

  /// Quantity picked in multi-select mode (shown as "4/8" with a check).
  final int? chosen;
  final String? semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final empty = icon == null;
    final (Color bg, Color ink) = switch (category) {
      ItemCategory.food => (c.secondarySoft, c.secondaryInk),
      ItemCategory.household => (c.primarySoft, c.primaryInk),
      ItemCategory.tools => (c.accentSoft, c.accentInk),
      ItemCategory.medicine => (c.dangerSoft, c.dangerInk),
      ItemCategory.other => (c.muted, c.mutedFg),
    };
    final radius = BorderRadius.circular(AppRadius.md);
    final picked = chosen != null;

    Widget box = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: empty ? c.muted : (picked ? c.primarySoft : bg),
        borderRadius: radius,
        border: empty ? null : Border.all(color: picked || selected ? c.primary : c.border, width: picked || selected ? 2 : 1),
      ),
      child: Stack(
        children: [
          if (!empty) Center(child: Icon(icon, color: ink, size: size * 0.42)),
          if (!empty && quantity != null && !picked)
            Positioned(right: 6, bottom: 3, child: Text('$quantity', style: AppType.code.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: c.fg))),
          if (picked)
            Positioned(right: 5, bottom: 3, child: Text('$chosen/${quantity ?? chosen}', style: AppType.code.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: c.primaryInk))),
          if (picked)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, size: 13, color: c.onPrimary),
              ),
            ),
          if (expiring && !picked)
            Positioned(right: 6, top: 6, child: Container(width: 9, height: 9, decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle))),
        ],
      ),
    );
    if (empty) box = CustomPaint(foregroundPainter: _DashedBorder(c.border, AppRadius.md), child: box);
    if (selected && !picked) {
      box = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: c.primary, width: 2.5)),
        child: box,
      );
    }
    return Semantics(label: semanticLabel, selected: selected || picked, child: box);
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)).deflate(0.75);
    final path = Path()..addRRect(rrect);
    for (final ui.PathMetric m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color || old.radius != radius;
}
