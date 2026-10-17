import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';

/// Bottom sheet for one item: −/+ count, move, used up, edit.
Future<void> showItemSheet(BuildContext context, String itemId) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _ItemSheet(itemId));

class _ItemSheet extends ConsumerWidget {
  const _ItemSheet(this.itemId);

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final d = ref.watch(homeProvider).requireValue;
    final item = d.item(itemId);
    if (item == null) return const SizedBox(height: 120);
    final home = ref.read(homeProvider.notifier);
    final storage = d.container(item.containerId)!;
    // The page behind the sheet keeps the snackbar after the sheet closes.
    final messenger = ScaffoldMessenger.of(context);

    void undoBar(String msg) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: l.undo, onPressed: home.undo),
          ),
        );
    }

    Future<void> move() async {
      var qty = item.qty;
      if (item.qty > 1) {
        final q = await pickQuantity(context, name: item.name, max: item.qty);
        if (q == null || q == 0 || !context.mounted) return;
        qty = q;
      }
      final to = await pickStorage(context, title: l.moveToWhere, exclude: item.containerId);
      if (to == null || !context.mounted) return;
      final name = home.data.container(to)!.name;
      Navigator.pop(context);
      await home.apply((d, ctx) => moveItems(d, ctx, {item.id: qty}, to));
      undoBar(l.movedTo(qty, name));
    }

    Future<void> usedUp() async {
      Navigator.pop(context);
      await home.apply((d, ctx) => useUpItems(d, ctx, [item.id]));
      undoBar(l.usedUpName(item.name));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHeader(''),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ItemThumb(category: item.category, photoPath: item.photoPath, iconKey: item.icon, size: 72),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: t.titleLarge),
                      const SizedBox(height: 2),
                      Text('${pathText(d.pathOf(item.containerId))} · ${storage.code}', style: t.bodySmall),
                      if (item.expiresOn != null) ...[
                        const SizedBox(height: AppSpace.sm),
                        DdayBadge(expiryStatus(today: DateTime.now(), expiresOn: item.expiresOn!)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: AppSpace.md),
              Text(item.note, style: t.bodyMedium?.copyWith(color: c.mutedFg)),
            ],
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(child: Text(l.quantity, style: t.titleSmall)),
                QtyStepper(value: item.qty, onChanged: (v) => home.apply((d, ctx) => adjustQty(d, ctx, item.id, v - item.qty))),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(onPressed: move, icon: const Icon(Icons.swap_horiz_rounded), label: Text(l.actionMove)),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: OutlinedButton(onPressed: usedUp, child: Text(l.usedUp)),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/item/${item.id}/edit');
                    },
                    child: Text(l.edit),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
