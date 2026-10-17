import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/inventory_slot.dart';
import 'item_sheet.dart';

/// Called when an item is dropped on a square ([slot]) or on a whole storage
/// spot ([slot] null).
typedef ItemDrop = void Function(Item item, String storageId, int? slot);

/// One storage spot's squares, wrapped to the available width.
///
/// Empty square: add there. Item: its sheet, or pick it while [selecting].
/// Press and hold an item, then drag it onto another square or storage spot
/// to move it; let go without moving to pick it instead.
class InventoryGrid extends ConsumerWidget {
  const InventoryGrid({
    super.key,
    required this.storageId,
    required this.picks,
    required this.selecting,
    required this.onTogglePick,
    required this.onDrop,
    this.onDragMove,
    this.onDragEnd,
    this.highlightItemId,
    this.targetSlot = 72,
  });

  final String storageId;

  /// item id -> chosen quantity.
  final Map<String, int> picks;
  final bool selecting;
  final ValueChanged<Item> onTogglePick;
  final ItemDrop onDrop;

  /// Pointer position while dragging (for scrolling near the edges).
  final ValueChanged<Offset>? onDragMove;
  final VoidCallback? onDragEnd;

  /// Item to flash (opened from search or the fairy).
  final String? highlightItemId;

  /// Preferred square size; the real size stretches so each row fills the width.
  final double targetSlot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final bySlot = {for (final i in d.itemsIn(storageId)) i.slot: i};
    final today = DateTime.now();
    return LayoutBuilder(
      builder: (context, box) {
        const gap = AppSpace.sm - 2;
        final cols = math.max(4, ((box.maxWidth + gap) / (targetSlot + gap)).floor());
        final size = ((box.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (var s = 0; s < gridLength(d, storageId, cols); s++) _cell(context, l, s, bySlot[s], size, today)],
        );
      },
    );
  }

  Widget _slot(AppLocalizations l, Item? item, double size, DateTime today, {bool target = false}) {
    final expiring = item?.expiresOn != null && expiryStatus(today: today, expiresOn: item!.expiresOn!).isUrgent;
    return InventorySlot(
      size: size,
      icon: item == null ? null : (iconFor(item.icon) ?? categoryIcon(item.category)),
      photoPath: item?.photoPath,
      category: item?.category ?? ItemCategory.other,
      quantity: item?.qty,
      expiring: expiring,
      chosen: item == null ? null : picks[item.id],
      selected: target,
      label: item?.name,
      semanticLabel: item == null ? l.emptySlot : l.slotLabel(item.name, item.qty),
    );
  }

  Widget _cell(BuildContext context, AppLocalizations l, int slot, Item? item, double size, DateTime today) {
    return DragTarget<Item>(
      key: ValueKey('slot-$storageId-$slot'),
      onWillAcceptWithDetails: (details) => details.data.id != item?.id,
      onAcceptWithDetails: (details) => onDrop(details.data, storageId, slot),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        Widget face = _slot(l, item, size, today, target: hovering);
        if (item != null && item.id == highlightItemId) face = _Flash(child: face);
        final tappable = InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {
            if (item == null) {
              if (!selecting) context.push('/item/new?storage=$storageId&slot=$slot');
            } else if (selecting) {
              onTogglePick(item);
            } else {
              showItemSheet(context, item.id);
            }
          },
          child: face,
        );
        if (item == null) return tappable;
        return _DraggableItem(
          item: item,
          feedback: Material(
            color: Colors.transparent,
            elevation: 8,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: _slot(l, item, size * 1.08, today),
          ),
          placeholder: Opacity(opacity: 0.35, child: _slot(l, item, size, today)),
          onHoldWithoutMoving: () => onTogglePick(item),
          onDragMove: onDragMove,
          onDragEnd: onDragEnd,
          child: tappable,
        );
      },
    );
  }
}

/// Press-and-hold drag. Letting go without moving counts as a plain long
/// press (pick the item) instead of a drop.
class _DraggableItem extends StatefulWidget {
  const _DraggableItem({
    required this.item,
    required this.feedback,
    required this.placeholder,
    required this.onHoldWithoutMoving,
    required this.child,
    this.onDragMove,
    this.onDragEnd,
  });

  final Item item;
  final Widget feedback;
  final Widget placeholder;
  final VoidCallback onHoldWithoutMoving;
  final ValueChanged<Offset>? onDragMove;
  final VoidCallback? onDragEnd;
  final Widget child;

  @override
  State<_DraggableItem> createState() => _DraggableItemState();
}

class _DraggableItemState extends State<_DraggableItem> {
  double _moved = 0;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Item>(
      data: widget.item,
      hapticFeedbackOnStart: true,
      feedback: widget.feedback,
      feedbackOffset: const Offset(0, -12),
      childWhenDragging: widget.placeholder,
      onDragStarted: () => _moved = 0,
      onDragUpdate: (d) {
        _moved += d.delta.distance;
        widget.onDragMove?.call(d.globalPosition);
      },
      onDraggableCanceled: (_, _) {
        if (_moved < 12) {
          HapticFeedback.selectionClick();
          widget.onHoldWithoutMoving();
        }
      },
      onDragEnd: (_) => widget.onDragEnd?.call(),
      child: widget.child,
    );
  }
}

/// Pulses a ring around its child a few times to say "it's here".
class _Flash extends StatefulWidget {
  const _Flash({required this.child});

  final Widget child;

  @override
  State<_Flash> createState() => _FlashState();
}

class _FlashState extends State<_Flash> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  int _left = 4;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _c.reverse();
      } else if (s == AnimationStatus.dismissed && --_left > 0) {
        _c.forward();
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.accent.withValues(alpha: _c.value), width: 3),
          boxShadow: [BoxShadow(color: c.accent.withValues(alpha: 0.5 * _c.value), blurRadius: 14, spreadRadius: 2)],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
