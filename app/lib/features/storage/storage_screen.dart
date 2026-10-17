import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/sheets.dart';
import 'item_sheet.dart';

/// One storage spot as a game-style inventory grid.
///
/// Tap an empty square to add, tap an item for its sheet (−/+, move, used up,
/// edit), long-press to pick several with quantities and act on them at once.
class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key, required this.storageId, this.startInSelectMode = false});

  final String storageId;
  final bool startInSelectMode;

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

/// Preferred square size; the real size stretches so each row fills the width.
const double _targetSlot = 72;

class _StorageScreenState extends ConsumerState<StorageScreen> {
  late bool _selecting = widget.startInSelectMode;

  /// item id -> chosen quantity.
  final _picks = <String, int>{};

  HomeController get _home => ref.read(homeProvider.notifier);

  void _endSelect() => setState(() {
    _selecting = false;
    _picks.clear();
  });

  Future<void> _togglePick(Item item) async {
    if (!_selecting) setState(() => _selecting = true);
    if (item.qty == 1) {
      setState(() => _picks.containsKey(item.id) ? _picks.remove(item.id) : _picks[item.id] = 1);
      return;
    }
    final q = await pickQuantity(context, name: item.name, max: item.qty, initial: _picks[item.id]);
    if (q == null || !mounted) return;
    setState(() => q == 0 ? _picks.remove(item.id) : _picks[item.id] = q);
  }

  Future<void> _moveSelected() async {
    final l = AppLocalizations.of(context);
    final to = await pickStorage(context, title: l.moveToWhere, exclude: widget.storageId);
    if (to == null || !mounted) return;
    final picks = Map.of(_picks);
    final total = picks.values.fold(0, (a, b) => a + b);
    final name = _home.data.container(to)!.name;
    await _home.apply((d, ctx) => moveItems(d, ctx, picks, to));
    if (!mounted) return;
    _endSelect();
    showUndo(context, ref, l.movedTo(total, name));
  }

  Future<void> _takeOutSelected() async {
    final l = AppLocalizations.of(context);
    final picks = Map.of(_picks);
    final total = picks.values.fold(0, (a, b) => a + b);
    await _home.apply((d, ctx) => useItems(d, ctx, picks));
    if (!mounted) return;
    _endSelect();
    showUndo(context, ref, l.tookOut(total));
  }

  Future<void> _useUpSelected() async {
    final l = AppLocalizations.of(context);
    final ids = _picks.keys.toList();
    await _home.apply((d, ctx) => useUpItems(d, ctx, ids));
    if (!mounted) return;
    _endSelect();
    showUndo(context, ref, l.usedUpKinds(ids.length));
  }

  Future<void> _menu(String action, Storage s) async {
    final l = AppLocalizations.of(context);
    if (action == 'edit') {
      final r = await askNameAndPhoto(context, title: l.editStorage, label: l.storageNameHint, name: s.name, photoPath: s.photoPath);
      if (r == null) return;
      await _home.apply((d, _) => updateContainer(d, s.id, name: r.name, photoPath: r.photoPath, clearPhoto: r.photoPath == null));
    } else if (action == 'delete') {
      final count = _home.data.itemsIn(s.id).length;
      final ok = await confirm(context, title: l.deleteStorageTitle(s.name), body: l.deleteStorageBody(count), action: l.delete);
      if (!ok || !mounted) return;
      context.pop();
      await _home.apply((d, _) => deleteContainer(d, s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final storage = d.container(widget.storageId);
    if (storage == null) return const Scaffold();
    final items = d.itemsIn(storage.id);
    final bySlot = {for (final i in items) i.slot: i};
    _picks.removeWhere((id, _) => d.item(id) == null);
    final today = DateTime.now();
    final kinds = _picks.length;
    final total = _picks.values.fold(0, (a, b) => a + b);

    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endSelect();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selecting ? (kinds == 0 ? l.pickItems : l.pickedSummary(kinds, total)) : storage.name),
          leading: _selecting ? IconButton(tooltip: l.cancel, onPressed: _endSelect, icon: const Icon(Icons.close_rounded)) : null,
          actions: [
            if (!_selecting)
              PopupMenuButton<String>(
                tooltip: l.more,
                onSelected: (a) => _menu(a, storage),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(l.editStorage)),
                  PopupMenuItem(value: 'delete', child: Text(l.delete)),
                ],
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pathText(d.pathOf(storage.id)),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(storage.code, style: AppType.code.copyWith(color: c.mutedFg)),
              ],
            ),
            if (storage.photoPath != null) ...[
              const SizedBox(height: AppSpace.md),
              PhotoBox(photoPath: storage.photoPath, height: 132, onTap: () => _menu('edit', storage)),
            ],
            const SizedBox(height: AppSpace.md),
            LayoutBuilder(
              builder: (context, box) {
                // As many squares per row as fit the screen; rows grow with the items.
                const gap = AppSpace.sm;
                final cols = math.max(4, ((box.maxWidth + gap) / (_targetSlot + gap)).floor());
                final size = ((box.maxWidth - gap * (cols - 1)) / cols).floorToDouble();
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [for (var s = 0; s < gridLength(d, storage.id, cols); s++) _cell(context, s, bySlot[s], size, today)],
                );
              },
            ),
            const SizedBox(height: AppSpace.md),
            Text(_selecting ? l.selectHint : l.storageHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.mutedFg)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
            child: _selecting
                ? Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: kinds == 0 ? null : _moveSelected,
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: Text(l.actionMove),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: OutlinedButton(onPressed: kinds == 0 ? null : _takeOutSelected, child: Text(l.actionTakeOut)),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: OutlinedButton(onPressed: kinds == 0 ? null : _useUpSelected, child: Text(l.usedUp)),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/item/new?storage=${storage.id}'),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l.actionAdd),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: items.isEmpty ? null : () => setState(() => _selecting = true),
                          icon: const Icon(Icons.checklist_rounded),
                          label: Text(l.pickSeveral),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, int slot, Item? item, double size, DateTime today) {
    final l = AppLocalizations.of(context);
    final expiring = item?.expiresOn != null && expiryStatus(today: today, expiresOn: item!.expiresOn!).isUrgent;
    final slotWidget = InventorySlot(
      size: size,
      icon: item == null ? null : categoryIcon(item.category),
      photoPath: item?.photoPath,
      category: item?.category ?? ItemCategory.other,
      quantity: item?.qty,
      expiring: expiring,
      chosen: item == null ? null : _picks[item.id],
      label: item?.name,
      semanticLabel: item == null ? l.emptySlot : l.slotLabel(item.name, item.qty),
    );
    return Tooltip(
      message: item?.name ?? '',
      triggerMode: TooltipTriggerMode.manual,
      child: InkWell(
        key: ValueKey('slot-$slot'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          if (item == null) {
            if (!_selecting) context.push('/item/new?storage=${widget.storageId}&slot=$slot');
          } else if (_selecting) {
            _togglePick(item);
          } else {
            showItemSheet(context, item.id);
          }
        },
        onLongPress: item == null ? null : () => _togglePick(item),
        child: slotWidget,
      ),
    );
  }
}
