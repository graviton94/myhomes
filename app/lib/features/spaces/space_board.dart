import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/settings.dart';
import '../../widgets/header_line.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/local_photo.dart';
import '../../widgets/location_bar.dart';
import '../../widgets/sheets.dart';
import '../storage/inventory_grid.dart';
import '../storage/selection.dart';
import 'space_actions.dart';
import '../../widgets/chip_line.dart';

part 'space_board_parts.dart';

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

  /// An item is being dragged: show the dock of other rooms.
  bool _dragging = false;
  static const double _dockHeight = 112;

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
      final bottom = top + box.size.height - (_dragging ? _dockHeight : 0);
      const edge = 72.0;
      double dy = 0;
      if (p.dy < top + edge) dy = -(top + edge - p.dy) / 4;
      if (p.dy > bottom - edge && p.dy < bottom) dy = (p.dy - (bottom - edge)) / 4;
      if (dy == 0) return;
      final pos = _scroll.position;
      _scroll.jumpTo((pos.pixels + dy).clamp(pos.minScrollExtent, pos.maxScrollExtent));
    });
  }

  void _onDragStart() => setState(() => _dragging = true);

  void _onDragEnd() {
    _autoScroll?.cancel();
    _autoScroll = null;
    _dragAt = null;
    if (mounted && _dragging) setState(() => _dragging = false);
  }

  /// Dropped on a room in the dock: straight in if it has one spot, else choose.
  Future<void> _dropOnRoom(Item item, String spaceId) async {
    _onDragEnd();
    final l = AppLocalizations.of(context);
    final spots = ref.read(homeProvider).requireValue.containers.where((c) => c.spaceId == spaceId).toList();
    final to = spots.length == 1 ? spots.single.id : await pickStorage(context, title: l.moveToWhere, onlySpaceId: spaceId);
    if (to != null && mounted) await dropItem(item, to, null);
  }

  Future<void> _addSpace({bool outside = false}) async {
    final s = await addSpaceFlow(context, ref, open: false, outside: outside);
    if (s != null && mounted) setState(() => _spaceId = s.id);
  }

  void _afterSpaceDeleted() {
    if (!mounted) return;
    if (widget.initialSpaceId != null) {
      context.pop();
    } else {
      setState(() => _spaceId = null);
    }
  }

  Future<void> _menu(String action, Space space) async {
    if (action == 'edit') {
      await editSpaceFlow(context, ref, space, onDeleted: _afterSpaceDeleted);
    } else if (action == 'delete') {
      if (await deleteSpaceFlow(context, ref, space)) _afterSpaceDeleted();
    }
  }

  /// Whether the highlighted item is in [storageId] or anything inside it.
  bool _holdsHighlight(HomeData d, String storageId) {
    final at = d.item(widget.highlightItemId ?? '')?.containerId;
    for (var id = at; id != null; id = d.container(id)?.parentId) {
      if (id == storageId) return true;
    }
    return false;
  }

  Widget _grid(String storageId) => InventoryGrid(
    storageId: storageId,
    picks: picks,
    selecting: selecting,
    onTogglePick: togglePick,
    onDrop: dropItem,
    onDragStart: _onDragStart,
    onDragMove: _onDragMove,
    onDragEnd: _onDragEnd,
    highlightItemId: widget.highlightItemId,
    targetSlot: 66,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    prunePicks(d);
    final ordered = spacesInOrder(d);
    final space = d.space(_spaceId ?? '') ?? ordered.firstOrNull;
    final storages = space == null ? const <Storage>[] : d.containersIn(space.id);

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
            const SettingsButton(),
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
                    onEdit: (s) => editSpaceFlow(context, ref, s, onDeleted: _afterSpaceDeleted),
                    onAdd: () => _addSpace(),
                    onAddOutside: () => _addSpace(outside: true),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
                    child: LocationBar(
                      spaceId: space.id,
                      trailing: Text(l.spaceSummary(storages.length, d.itemCountInSpace(space.id)), style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ListView(
                            key: _listKey,
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
                            children: [
                              if (photoAvailable(space.photoPath)) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  child: LocalPhoto(space.photoPath!, height: 140, width: double.infinity, cacheWidth: 900),
                                ),
                                const SizedBox(height: AppSpace.md),
                              ],
                              for (final s in storages) ...[
                                _Bag(
                                  key: _bagKeys.putIfAbsent(s.id, GlobalKey.new),
                                  storage: s,
                                  acceptsDrop: holdsItems(d, s),
                                  onDrop: (item) => dropItem(item, s.id, null),
                                  collapsed: _collapsed.contains(s.id) && !_holdsHighlight(d, s.id),
                                  onToggle: () => setState(() => _collapsed.contains(s.id) ? _collapsed.remove(s.id) : _collapsed.add(s.id)),
                                  canMoveHere: holdsItems(d, s) && picks.isNotEmpty && picks.keys.any((id) => d.item(id)?.containerId != s.id),
                                  onMoveHere: () => moveSelectedTo(s.id),
                                  grid: holdsItems(d, s)
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _grid(s.id),
                                            _BoxChips(parentId: s.id),
                                          ],
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            for (final section in sectionsOf(d, s.id))
                                              _Section(
                                                key: _bagKeys.putIfAbsent(section.id, GlobalKey.new),
                                                section: section,
                                                canMoveHere: picks.isNotEmpty && picks.keys.any((id) => d.item(id)?.containerId != section.id),
                                                onMoveHere: () => moveSelectedTo(section.id),
                                                grid: _grid(section.id),
                                              ),
                                          ],
                                        ),
                                ),
                                const SizedBox(height: AppSpace.md),
                              ],
                              _AddBag(onTap: () => addStorageFlow(context, ref, space.id)),
                              if (storages.isEmpty) ...[
                                const SizedBox(height: AppSpace.md),
                                Text(l.boardFirstStorageHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.mutedFg)),
                              ],
                              if (_dragging) const SizedBox(height: _dockHeight),
                            ],
                          ),
                        ),
                        if (_dragging)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: _dockHeight,
                            child: _RoomDock(
                              spaces: ordered.where((x) => x.id != space.id).toList(),
                              onOpen: (id) {
                                HapticFeedback.selectionClick();
                                setState(() => _spaceId = id);
                              },
                              onDrop: _dropOnRoom,
                            ),
                          ),
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
