import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/location_bar.dart';
import '../storage/inventory_grid.dart';
import '../storage/selection.dart';
import 'space_actions.dart';

/// Rooms as tabs; each room's storage spots as open "bags" with their
/// squares, so room → storage → item is one screen. Pick items in any bag
/// and tap "Move here" on another bag to move them.
class SpaceBoard extends ConsumerStatefulWidget {
  const SpaceBoard({super.key, this.initialSpaceId});

  /// Opened from a link to one room (has a back button); null = Spaces tab.
  final String? initialSpaceId;

  @override
  ConsumerState<SpaceBoard> createState() => _SpaceBoardState();
}

class _SpaceBoardState extends ConsumerState<SpaceBoard> with PickSelection {
  late String? _spaceId = widget.initialSpaceId;
  final _collapsed = <String>{};

  Future<void> _addSpace() async {
    final s = await addSpaceFlow(context, ref, open: false);
    if (s != null && mounted) setState(() => _spaceId = s.id);
  }

  Future<void> _menu(String action, Space space) async {
    if (action == 'edit') {
      await editSpaceFlow(context, ref, space);
    } else if (action == 'delete') {
      final deleted = await deleteSpaceFlow(context, ref, space);
      if (deleted && mounted) {
        if (widget.initialSpaceId != null) {
          context.pop();
        } else {
          setState(() => _spaceId = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    prunePicks(d);
    final space = d.space(_spaceId ?? '') ?? d.spaces.firstOrNull;
    final storages = space == null ? const <Storage>[] : d.containers.where((s) => s.spaceId == space.id).toList();

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) endSelect();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(selecting ? (picks.isEmpty ? l.pickItems : l.pickedSummary(picks.length, pickedTotal)) : l.navSpaces),
          leading: selecting ? IconButton(tooltip: l.cancel, onPressed: endSelect, icon: const Icon(Icons.close_rounded)) : null,
          actions: [
            if (space != null && !selecting)
              PopupMenuButton<String>(
                tooltip: l.more,
                onSelected: (a) => _menu(a, space),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(l.editSpaceNamed(space.name))),
                  PopupMenuItem(value: 'delete', child: Text(l.deleteSpaceNamed(space.name))),
                ],
              ),
          ],
        ),
        body: space == null
            ? Center(
                child: SingleChildScrollView(
                  child: EmptyState(
                    pose: FairyPose.sleep,
                    title: l.spacesEmptyTitle,
                    body: l.spacesEmptyBody,
                    action: FilledButton.icon(onPressed: _addSpace, icon: const Icon(Icons.add_rounded), label: Text(l.addSpace)),
                  ),
                ),
              )
            : Column(
                children: [
                  _RoomTabs(spaces: d.spaces, current: space.id, onSelect: (id) => setState(() => _spaceId = id), onAdd: _addSpace),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
                    child: LocationBar(
                      spaceId: space.id,
                      trailing: Text(
                        l.spaceSummary(storages.length, d.itemCountInSpace(space.id)),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
                      children: [
                        if (space.photoPath != null && File(space.photoPath!).existsSync()) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            child: Image.file(
                              File(space.photoPath!),
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              cacheWidth: 900,
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                        ],
                        for (final s in storages) ...[
                          _Bag(
                            storage: s,
                            collapsed: _collapsed.contains(s.id),
                            onToggle: () => setState(() => _collapsed.contains(s.id) ? _collapsed.remove(s.id) : _collapsed.add(s.id)),
                            canMoveHere: picks.isNotEmpty && picks.keys.any((id) => d.item(id)?.containerId != s.id),
                            onMoveHere: () => moveSelectedTo(s.id),
                            grid: InventoryGrid(
                              storageId: s.id,
                              picks: picks,
                              selecting: selecting,
                              onTogglePick: togglePick,
                              targetSlot: 66,
                            ),
                          ),
                          const SizedBox(height: AppSpace.md),
                        ],
                        _AddBag(onTap: () => addStorageFlow(context, ref, space.id)),
                        if (storages.isEmpty) ...[
                          const SizedBox(height: AppSpace.md),
                          Text(l.boardFirstStorageHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.mutedFg)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: selecting
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.boardMoveHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.mutedFg)),
                      const SizedBox(height: AppSpace.sm),
                      selectionButtons(context),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _RoomTabs extends StatelessWidget {
  const _RoomTabs({required this.spaces, required this.current, required this.onSelect, required this.onAdd});

  final List<Space> spaces;
  final String current;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Row(
        children: [
          for (final s in spaces) ...[
            ChoiceChip(
              avatar: Icon(spaceIcon(s), size: 18, color: s.id == current ? c.onPrimary : c.secondaryInk),
              label: Text(s.name),
              selected: s.id == current,
              showCheckmark: false,
              selectedColor: c.secondary,
              labelStyle: TextStyle(color: s.id == current ? c.onPrimary : c.fg, fontWeight: FontWeight.w700),
              onSelected: (_) => onSelect(s.id),
            ),
            const SizedBox(width: AppSpace.sm),
          ],
          ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(l.addSpaceShort), onPressed: onAdd),
        ],
      ),
    );
  }
}

/// One storage spot: honey header with icon, name, code and count, then its squares.
class _Bag extends ConsumerWidget {
  const _Bag({
    required this.storage,
    required this.collapsed,
    required this.onToggle,
    required this.canMoveHere,
    required this.onMoveHere,
    required this.grid,
  });

  final Storage storage;
  final bool collapsed;
  final VoidCallback onToggle;
  final bool canMoveHere;
  final VoidCallback onMoveHere;
  final Widget grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final count = ref.watch(homeProvider).requireValue.itemsIn(storage.id).length;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: canMoveHere ? c.accent : c.border, width: canMoveHere ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.xs, AppSpace.sm),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
                    child: Icon(storageIcon(storage), size: 20, color: c.accentInk),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storage.name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${storage.code} · ${l.itemsCount(count)}', style: AppType.code.copyWith(fontSize: 11, color: c.mutedFg)),
                      ],
                    ),
                  ),
                  if (canMoveHere)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.xs),
                      child: FilledButton.tonalIcon(
                        onPressed: onMoveHere,
                        icon: const Icon(Icons.south_rounded, size: 18),
                        label: Text(l.moveHere),
                      ),
                    )
                  else ...[
                    IconButton(
                      tooltip: l.openStorage,
                      onPressed: () => context.push('/storage/${storage.id}'),
                      icon: const Icon(Icons.open_in_full_rounded, size: 20),
                    ),
                    Icon(collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded, color: c.mutedFg),
                    const SizedBox(width: AppSpace.sm),
                  ],
                ],
              ),
            ),
          ),
          if (!collapsed) Padding(padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.md), child: grid),
        ],
      ),
    );
  }
}

class _AddBag extends StatelessWidget {
  const _AddBag({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: c.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: c.mutedFg),
              const SizedBox(width: 6),
              Text(l.addStorage, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.mutedFg)),
            ],
          ),
        ),
      ),
    );
  }
}
