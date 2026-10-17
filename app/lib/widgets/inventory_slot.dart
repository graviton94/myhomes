import 'dart:ui' as ui;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../design/theme.dart';
import '../design/tokens.g.dart';

/// Soft background and readable ink for a category (used when there is no photo).
(Color bg, Color ink) categoryColors(BuildContext context, ItemCategory category) {
  final c = HfColors.of(context);
  return switch (category) {
    ItemCategory.food => (c.secondarySoft, c.secondaryInk),
    ItemCategory.household => (c.primarySoft, c.primaryInk),
    ItemCategory.tools => (c.accentSoft, c.accentInk),
    ItemCategory.medicine => (c.dangerSoft, c.dangerInk),
    ItemCategory.other => (c.muted, c.mutedFg),
  };
}

IconData categoryIcon(ItemCategory category) => switch (category) {
  ItemCategory.food => Icons.local_grocery_store_outlined,
  ItemCategory.household => Icons.cleaning_services_outlined,
  ItemCategory.tools => Icons.handyman_outlined,
  ItemCategory.medicine => Icons.medication_outlined,
  ItemCategory.other => Icons.category_outlined,
};

/// Square thumbnail: the item's photo, else its category icon on soft colour.
class ItemThumb extends StatelessWidget {
  const ItemThumb({super.key, required this.category, this.photoPath, this.size = 40, this.icon});

  final ItemCategory category;
  final String? photoPath;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, ink) = categoryColors(context, category);
    final radius = BorderRadius.circular(size * 0.3);
    if (photoPath != null && File(photoPath!).existsSync()) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.file(File(photoPath!), width: size, height: size, fit: BoxFit.cover, cacheWidth: (size * 3).round()),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: Icon(icon ?? categoryIcon(category), color: ink, size: size * 0.52),
    );
  }
}

/// One square in a container's inventory grid.
class InventorySlot extends StatelessWidget {
  const InventorySlot({
    super.key,
    this.icon,
    this.photoPath,
    this.category = ItemCategory.other,
    this.quantity,
    this.expiring = false,
    this.selected = false,
    this.chosen,
    this.semanticLabel,
    this.label,
    this.size = AppSize.slot,
  });

  /// Item name written inside the square, so it reads without tapping.
  final String? label;

  /// Null (and no photo) means an empty slot.
  final IconData? icon;
  final String? photoPath;
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
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    final empty = icon == null && !hasPhoto;
    final (bg, ink) = categoryColors(context, category);
    final radius = BorderRadius.circular(AppRadius.md);
    final picked = chosen != null;
    final named = label != null && label!.isNotEmpty && !empty;

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
          if (hasPhoto)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md - 1),
                child: Image.file(File(photoPath!), fit: BoxFit.cover, cacheWidth: (size * 3).round()),
              ),
            )
          else if (!empty)
            Align(
              alignment: named ? const Alignment(0, -0.45) : Alignment.center,
              child: Icon(icon, color: ink, size: size * (named ? 0.32 : 0.42)),
            ),
          if (named && hasPhoto)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.md - 1)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0), Colors.black.withValues(alpha: 0.62)],
                  ),
                ),
                child: _name(Colors.white),
              ),
            )
          else if (named && !empty)
            Positioned(left: 4, right: 4, bottom: 5, child: _name(c.fg)),
          if (!empty && quantity != null && !picked)
            named || hasPhoto
                ? Positioned(right: 3, top: 3, child: _Pill('×$quantity', c.card, c.fg))
                : Positioned(
                    right: 6,
                    bottom: 3,
                    child: Text(
                      '$quantity',
                      style: AppType.code.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: c.fg),
                    ),
                  ),
          if (picked) Positioned(right: 3, top: 3, child: _Pill('$chosen/${quantity ?? chosen}', c.primary, c.onPrimary)),
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
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.card, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
    if (empty) box = CustomPaint(foregroundPainter: _DashedBorder(c.border, AppRadius.md), child: box);
    if (selected && !picked) {
      box = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: c.primary, width: 2.5),
        ),
        child: box,
      );
    }
    return Semantics(label: semanticLabel, selected: selected || picked, child: box);
  }
}

extension on InventorySlot {
  Widget _name(Color color) => Text(
    label!,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    style: AppType.label.copyWith(fontSize: 11, height: 1.15, fontWeight: FontWeight.w700, color: color),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.bg, this.fg);

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
    child: Text(
      text,
      style: AppType.code.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
    ),
  );
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
