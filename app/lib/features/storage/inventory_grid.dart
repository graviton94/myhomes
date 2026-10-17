import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/inventory_slot.dart';
import 'item_sheet.dart';

/// One storage spot's squares, wrapped to the available width.
///
/// Empty square: add there. Item: its sheet, or pick it while [selecting].
/// Long-press an item to start picking.
class InventoryGrid extends ConsumerWidget {
  const InventoryGrid({
    super.key,
    required this.storageId,
    required this.picks,
    required this.selecting,
    required this.onTogglePick,
    this.targetSlot = 72,
  });

  final String storageId;

  /// item id -> chosen quantity.
  final Map<String, int> picks;
  final bool selecting;
  final ValueChanged<Item> onTogglePick;

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

  Widget _cell(BuildContext context, AppLocalizations l, int slot, Item? item, double size, DateTime today) {
    final expiring = item?.expiresOn != null && expiryStatus(today: today, expiresOn: item!.expiresOn!).isUrgent;
    return InkWell(
      key: ValueKey('slot-$storageId-$slot'),
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
      onLongPress: item == null ? null : () => onTogglePick(item),
      child: InventorySlot(
        size: size,
        icon: item == null ? null : (iconFor(item.icon) ?? categoryIcon(item.category)),
        photoPath: item?.photoPath,
        category: item?.category ?? ItemCategory.other,
        quantity: item?.qty,
        expiring: expiring,
        chosen: item == null ? null : picks[item.id],
        label: item?.name,
        semanticLabel: item == null ? l.emptySlot : l.slotLabel(item.name, item.qty),
      ),
    );
  }
}
