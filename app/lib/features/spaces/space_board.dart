import 'dart:async';
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
import '../../widgets/dday_badge.dart';
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
  const SpaceBoard({super.key, this.initialSpaceId, this.highlightItemId});

  /// Opened from a link to one room (has a back button); null = Spaces tab.
  final String? initialSpaceId;

  /// Item to scroll to and flash (from search, the fairy, the use-by list).
  final String? highlightItemId;

  @override
  ConsumerState<SpaceBoard> createState() => _SpaceBoardState();
}

class _SpaceBoardState extends ConsumerState<SpaceBoard> with PickSelection {
  late String? _spaceId = widget.initialSpaceId;
  final _collapsed = <String>{};
  final _scroll = ScrollController();
  final _listKey = GlobalKey();
  final _bagKeys = <String, GlobalKey>{};

  /// Pointer while dragging near the top or bottom edge, for auto-scroll.
  Offset? _dragAt;
  Timer? _autoScroll;

  @override
  void initState() {
    super.initState();
    final itemId = widget.highlightItemId;
    if (itemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final storageId = ref.read(homeProvider).requireValue.item(itemId)?.containerId;
        final ctx = _bagKeys[storageId]?.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1);
      });
    }
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _onDragMove(Offset at) {
    _dragAt = at;
    _autoScroll ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final box = _listKey.currentContext?.findRenderObject() as RenderBox?;
      final p = _dragAt;
      if (box == null || p == null || !_scroll.hasClients) return;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      const edge = 72.0;
      double dy = 0;
      if (p.dy < top + edge) dy = -(top + edge - p.dy) / 4;
      if (p.dy > bottom - edge) dy = (p.dy - (bottom - edge)) / 4;
      if (dy == 0) return;
      final pos = _scroll.position;
      _scroll.jumpTo((pos.pixels + dy).clamp(pos.minScrollExtent, pos.maxScrollExtent));
    });
  }

  void _onDragEnd() {
    _autoScroll?.cancel();
    _autoScroll = null;
    _dragAt = null;
  }

  Future<void> _addSpace({bool outside = false}) async {
    final s = await addSpaceFlow(context, ref, open: false, outside: outside);
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
    final ordered = spacesInOrder(d);
    final space = d.space(_spaceId ?? '') ?? ordered.firstOrNull;
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
                  _RoomTabs(
                    spaces: ordered,
                    current: space.id,
                    onSelect: (id) => setState(() => _spaceId = id),
                    onAdd: () => _addSpace(),
                    onAddOutside: () => _addSpace(outside: true),
                  ),
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
                      key: _listKey,
                      controller: _scroll,
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
                            key: _bagKeys.putIfAbsent(s.id, GlobalKey.new),
                            storage: s,
                            onDrop: (item) => dropItem(item, s.id, null),
                            collapsed: _collapsed.contains(s.id) && d.item(widget.highlightItemId ?? '')?.containerId != s.id,
                            onToggle: () => setState(() => _collapsed.contains(s.id) ? _collapsed.remove(s.id) : _collapsed.add(s.id)),
                            canMoveHere: picks.isNotEmpty && picks.keys.any((id) => d.item(id)?.containerId != s.id),
                            onMoveHere: () => moveSelectedTo(s.id),
                            grid: InventoryGrid(
                              storageId: s.id,
                              picks: picks,
                              selecting: selecting,
                              onTogglePick: togglePick,
                              onDrop: dropItem,
                              onDragMove: _onDragMove,
                              onDragEnd: _onDragEnd,
                              highlightItemId: widget.highlightItemId,
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

class _RoomTabs extends StatefulWidget {
  const _RoomTabs({required this.spaces, required this.current, required this.onSelect, required this.onAdd, required this.onAddOutside});

  final List<Space> spaces;
  final String current;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;
  final VoidCallback onAddOutside;

  @override
  State<_RoomTabs> createState() => _RoomTabsState();
}

class _RoomTabsState extends State<_RoomTabs> {
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(_RoomTabs old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) _reveal();
  }

  /// Scrolls the selected room's tab into view.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[widget.current]?.currentContext;
      if (ctx != null) Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 200));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    Widget chip(Space s) {
      final on = s.id == widget.current;
      final (Color strong, Color ink) = s.outside ? (c.primary, c.primaryInk) : (c.secondary, c.secondaryInk);
      return Padding(
        key: _keys.putIfAbsent(s.id, GlobalKey.new),
        padding: const EdgeInsets.only(right: AppSpace.sm),
        child: ChoiceChip(
          avatar: Icon(spaceIcon(s), size: 18, color: on ? c.onPrimary : ink),
          label: Text(s.name),
          selected: on,
          showCheckmark: false,
          selectedColor: strong,
          labelStyle: TextStyle(color: on ? c.onPrimary : c.fg, fontWeight: FontWeight.w700),
          onSelected: (_) => widget.onSelect(s.id),
        ),
      );
    }

    final rooms = widget.spaces.where((s) => !s.outside);
    final outside = widget.spaces.where((s) => s.outside);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      child: Row(
        children: [
          for (final s in rooms) chip(s),
          ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: Text(l.addSpaceShort), onPressed: widget.onAdd),
          Container(
            width: 1,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: AppSpace.md),
            color: c.border,
          ),
          for (final s in outside) chip(s),
          ActionChip(
            avatar: Icon(Icons.explore_rounded, size: 18, color: c.primaryInk),
            label: Text(l.addOutsideShort),
            onPressed: widget.onAddOutside,
          ),
        ],
      ),
    );
  }
}

/// One storage spot: honey header with icon, name, code and count, then its squares.
class _Bag extends ConsumerWidget {
  const _Bag({
    super.key,
    required this.storage,
    required this.onDrop,
    required this.collapsed,
    required this.onToggle,
    required this.canMoveHere,
    required this.onMoveHere,
    required this.grid,
  });

  final Storage storage;
  final ValueChanged<Item> onDrop;
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
    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) => details.data.containerId != storage.id,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) => _box(context, l, c, t, count, hovering: candidates.isNotEmpty),
    );
  }

  Widget _box(BuildContext context, AppLocalizations l, AppColors c, TextTheme t, int count, {required bool hovering}) {
    final highlight = canMoveHere || hovering;
    return Container(
      decoration: BoxDecoration(
        color: hovering ? c.accentSoft : c.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: highlight ? c.accent : c.border, width: highlight ? 2 : 1),
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
                        if (storage.returnBy != null) ...[
                          const SizedBox(height: 4),
                          ReturnBadge(expiryStatus(today: DateTime.now(), expiresOn: storage.returnBy!)),
                        ],
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
