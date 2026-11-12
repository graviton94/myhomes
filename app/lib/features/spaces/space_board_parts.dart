part of 'space_board.dart';

class _RoomTabs extends StatefulWidget {
  const _RoomTabs({
    required this.spaces,
    required this.current,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
    required this.onAddOutside,
  });

  final List<Space> spaces;
  final String current;
  final ValueChanged<String> onSelect;
  final ValueChanged<Space> onEdit;
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
        // Hold a room tab to rename it, change its icon or photo, or delete it.
        child: GestureDetector(
          onLongPress: () => widget.onEdit(s),
          child: ChoiceChip(
            avatar: spaceGlyph(s, size: 18, color: on ? c.onPrimary : ink),
            label: Text(s.name),
            selected: on,
            showCheckmark: false,
            selectedColor: strong,
            labelStyle: TextStyle(color: on ? c.onPrimary : c.fg, fontWeight: FontWeight.w700),
            onSelected: (_) => widget.onSelect(s.id),
          ),
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

/// Shown while dragging: other rooms to drop into. Holding an item over a
/// room for a moment opens it, so it can be dropped on a particular spot.
class _RoomDock extends StatelessWidget {
  const _RoomDock({required this.spaces, required this.onOpen, required this.onDrop});

  final List<Space> spaces;
  final ValueChanged<String> onOpen;
  final void Function(Item item, String spaceId) onDrop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Material(
      color: c.card,
      elevation: 12,
      shadowColor: Colors.black26,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              spaces.isEmpty ? l.dockNoOtherRooms : l.dockHint,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.mutedFg),
            ),
            const SizedBox(height: AppSpace.sm),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final s in spaces) ...[
                    _DockRoom(space: s, onOpen: () => onOpen(s.id), onDrop: (item) => onDrop(item, s.id)),
                    const SizedBox(width: AppSpace.sm),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockRoom extends StatefulWidget {
  const _DockRoom({required this.space, required this.onOpen, required this.onDrop});

  final Space space;
  final VoidCallback onOpen;
  final ValueChanged<Item> onDrop;

  @override
  State<_DockRoom> createState() => _DockRoomState();
}

class _DockRoomState extends State<_DockRoom> {
  Timer? _hover;

  @override
  void dispose() {
    _hover?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final s = widget.space;
    final (soft, ink) = s.outside ? (c.primarySoft, c.primaryInk) : (c.secondarySoft, c.secondaryInk);
    return DragTarget<Item>(
      onWillAcceptWithDetails: (_) {
        _hover?.cancel();
        _hover = Timer(const Duration(milliseconds: 650), widget.onOpen);
        return true;
      },
      onLeave: (_) => _hover?.cancel(),
      onAcceptWithDetails: (d) {
        _hover?.cancel();
        widget.onDrop(d.data);
      },
      builder: (context, candidates, _) {
        final on = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(color: on ? ink : soft, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Row(
            children: [
              spaceGlyph(s, size: 20, color: on ? c.onPrimary : ink),
              const SizedBox(width: 6),
              Text(
                s.name,
                style: AppType.label.copyWith(fontWeight: FontWeight.w700, color: on ? c.onPrimary : ink),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One storage spot: honey header with icon, name, code and count, then its squares.
class _Bag extends ConsumerWidget {
  const _Bag({
    super.key,
    required this.storage,
    this.acceptsDrop = true,
    required this.onDrop,
    required this.collapsed,
    required this.onToggle,
    required this.canMoveHere,
    required this.onMoveHere,
    required this.grid,
  });

  final Storage storage;

  /// False for furniture split into sections: things go into a section.
  final bool acceptsDrop;
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
    final count = itemCountUnder(ref.watch(homeProvider).requireValue, storage.id);
    return DragTarget<Item>(
      onWillAcceptWithDetails: (details) => acceptsDrop && details.data.containerId != storage.id,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, _) => _box(context, ref, l, c, t, count, hovering: candidates.isNotEmpty),
    );
  }

  Widget _box(BuildContext context, WidgetRef ref, AppLocalizations l, AppColors c, TextTheme t, int count, {required bool hovering}) {
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
                    child: Center(child: storageGlyph(storage, size: 20, color: c.accentInk)),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storage.name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${storage.code} · ${l.itemsCount(count)}', style: AppType.code.copyWith(fontSize: 11, color: c.mutedFg)),
                        if (storage.returnBy != null && ref.watch(settingsProvider).returnsOn) ...[
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
                    PopupMenuButton<String>(
                      key: ValueKey('bag-menu-${storage.id}'),
                      tooltip: l.more,
                      icon: const Icon(Icons.more_vert_rounded, size: 20),
                      onSelected: (a) {
                        if (a == 'open') context.push('/storage/${storage.id}');
                        if (a == 'edit') editStorageFlow(context, ref, storage);
                        if (a == 'delete') deleteStorageFlow(context, ref, storage);
                        if (a == 'move') moveBoxFlow(context, ref, storage);
                      },
                      itemBuilder: (_) => [
                        if (acceptsDrop) PopupMenuItem(value: 'open', child: Text(l.openStorage)),
                        if (storage.kind == StorageKind.box) PopupMenuItem(value: 'move', child: Text(l.moveBox)),
                        PopupMenuItem(value: 'edit', child: Text(l.editStorage)),
                        PopupMenuItem(value: 'delete', child: Text(l.delete)),
                      ],
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

/// One shelf or drawer of a piece of furniture: its name, its squares and
/// the boxes on it.
class _Section extends ConsumerWidget {
  const _Section({super.key, required this.section, required this.canMoveHere, required this.onMoveHere, required this.grid});

  final Storage section;
  final bool canMoveHere;
  final VoidCallback onMoveHere;
  final Widget grid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final count = ref.watch(homeProvider).requireValue.itemsIn(section.id).length;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.xs, AppSpace.sm, AppSpace.sm),
      decoration: BoxDecoration(
        color: c.muted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: canMoveHere ? Border.all(color: c.accent, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: section.name, style: Theme.of(context).textTheme.labelLarge),
                      TextSpan(
                        text: '  ${l.itemsCount(count)}',
                        style: AppType.caption.copyWith(color: c.mutedFg),
                      ),
                    ],
                  ),
                ),
              ),
              if (canMoveHere)
                TextButton.icon(onPressed: onMoveHere, icon: const Icon(Icons.south_rounded, size: 16), label: Text(l.moveHere))
              else
                PopupMenuButton<String>(
                  tooltip: l.more,
                  icon: const Icon(Icons.more_horiz_rounded, size: 18),
                  onSelected: (a) {
                    if (a == 'box') addStorageFlow(context, ref, section.spaceId, parentId: section.id);
                    if (a == 'edit') editStorageFlow(context, ref, section);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'box', child: Text('+ ${l.addBoxHere}')),
                    PopupMenuItem(value: 'edit', child: Text(l.editStorage)),
                  ],
                ),
            ],
          ),
          grid,
          _BoxChips(parentId: section.id),
        ],
      ),
    );
  }
}

/// Boxes sitting in a section, a spot or another box. Tap opens the box;
/// long-press moves it.
class _BoxChips extends ConsumerWidget {
  const _BoxChips({required this.parentId});

  final String parentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(homeProvider).requireValue;
    final boxes = boxesIn(d, parentId);
    if (boxes.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: ChipLine(
        children: [
          for (final b in boxes)
            GestureDetector(
              onLongPress: () => moveBoxFlow(context, ref, b),
              child: ActionChip(
                key: ValueKey('box-${b.id}'),
                avatar: storageGlyph(b, size: 18, color: c.accentInk),
                backgroundColor: c.accentSoft,
                side: BorderSide(color: c.accent.withValues(alpha: 0.4)),
                label: Text('${b.name} · ${l.itemsCount(d.itemsIn(b.id).length)}'),
                onPressed: () => context.push('/storage/${b.id}'),
              ),
            ),
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
