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
import '../../settings/settings.dart';
import '../../widgets/doodle.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/sheets.dart';
import '../spaces/space_actions.dart';
import '../../widgets/fit_text.dart';
import 'plan_editor.dart';
import 'room_edit_screen.dart' show FurniturePainter;
import '../../widgets/chip_line.dart';
import '../../widgets/name_ideas.dart';

/// HOU-02: rooms as blocks on 0.5 m squares, edited as a draft
/// (plan_editor.dart): drag any room to move it, stretch the picked one from
/// near its walls or corners, 저장 keeps it, 취소 puts it back. Not a floor
/// plan editor: no walls, doors or windows.
///
/// The map is the home's hub (user decision, docs/mockups/map-hub.html):
/// rooms and storage are added, renamed, deleted and opened from here, and a
/// new home starts here in steps ([start]): ① rooms, ② storage, ③ things.
class HouseEditScreen extends ConsumerStatefulWidget {
  const HouseEditScreen({super.key, this.start = false});

  /// First start: 다음 goes from rooms to storage, then on to the things.
  final bool start;

  @override
  ConsumerState<HouseEditScreen> createState() => _HouseEditScreenState();
}

class _HouseEditScreenState extends ConsumerState<HouseEditScreen> {
  String? _selected;
  final _editor = GlobalKey<PlanEditorState>();
  late final _draft = PlanDraft({for (final s in plannedRooms(ref.read(homeProvider).requireValue)) s.id: s.plan!})..addListener(_redraw);

  /// The 가구 tab (user request, docs/mockups/map-furniture.html): the rooms
  /// stand still and the furniture of every room is placed on the one map.
  bool _furnitureTab = false;
  late final _fur = Draft<FloorSpot>(_floorSpots(ref.read(homeProvider).requireValue))..addListener(_redraw);

  static Map<String, FloorSpot> _floorSpots(HomeData d) => {
    for (final room in plannedRooms(d))
      for (final s in floorStorages(d, room.id))
        if (s.plan != null) s.id: (room: room.id, r: s.plan!),
  };

  /// Each placed piece on the map's squares: its room's place plus its own.
  Map<String, PlanRect> get _furOnMap => {
    for (final e in _fur.plans.entries)
      if (_draft.plans[e.value.room] case final room?) e.key: PlanRect(room.x + e.value.r.x, room.y + e.value.r.y, e.value.r.w, e.value.r.h),
  };

  /// A piece let go on the map: it goes to the room under its middle (or
  /// stays in its own), kept inside that room's walls.
  void _furMoved(String id, PlanRect at) {
    final rooms = _draft.plans;
    final cx = at.x + at.w / 2, cy = at.y + at.h / 2;
    final under = rooms.entries.where((e) => cx >= e.value.x && cx <= e.value.right && cy >= e.value.y && cy <= e.value.bottom).map((e) => e.key).firstOrNull;
    final roomId = under ?? _fur.plans[id]!.room;
    final room = rooms[roomId]!;
    final w = at.w.clamp(1, room.w), h = at.h.clamp(1, room.h);
    final x = (at.x - room.x).clamp(0, room.w - w), y = (at.y - room.y).clamp(0, room.h - h);
    _fur.set(id, (room: roomId, r: PlanRect(x, y, w, h)));
  }

  /// Picks a piece (the editor brings a small one up close by itself); its
  /// room is where new storage goes next.
  void _pickFurniture(String? id) => setState(() {
    _selected = id;
    if (id != null && _fur.plans[id] != null) _target = _fur.plans[id]!.room;
  });

  /// The room new storage goes into: tapped on the furniture tab, or the
  /// picked piece's room; else the first room.
  String? _target;

  String? _targetRoom() => _draft.plans.containsKey(_target) ? _target : _draft.plans.keys.firstOrNull;

  /// Empty floor tapped on the furniture tab: that room takes the new storage.
  void _tapFloor(int x, int y) {
    final room = _draft.plans.entries.where((e) => x >= e.value.x && x < e.value.right && y >= e.value.y && y < e.value.bottom).firstOrNull;
    if (room != null) setState(() => _target = room.key);
  }

  /// Storage made while editing: gone again if the edit is dropped.
  final _madeSpots = <String>{};

  /// A suggested room tapped below the map: made, put in a free spot near the
  /// middle of the view, and picked.
  Future<void> _addRoomNamed(String name) async {
    final s = await ref.read(homeProvider.notifier).apply<Space>((d, ctx) => addSpace(d, ctx, name));
    if (s == null || !mounted) return;
    _made.add(s.id);
    final (cx, cy) = _editor.currentState?.centreSquare() ?? (0, 0);
    var at = PlanRect(cx - 2, cy - 2, 4, 4);
    search:
    for (var r = 0; r < 20; r++) {
      for (var dy = -r; dy <= r; dy++) {
        for (var dx = -r; dx <= r; dx++) {
          final t = PlanRect(cx - 2 + dx, cy - 2 + dy, 4, 4);
          if (!_draft.plans.values.any(t.overlaps)) {
            at = t;
            break search;
          }
        }
      }
    }
    _draft.set(s.id, at);
    setState(() => _selected = s.id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _editor.currentState?.focusPicked());
  }

  /// A suggested storage spot tapped below the map: made in [roomId] and put
  /// in a free spot of it, picked.
  Future<void> _addSpotNamed(String roomId, String name) async {
    final s = await ref.read(homeProvider.notifier).apply<Storage>((d, ctx) {
      final taken = d.containers.where((c) => c.spaceId == roomId).map((c) => c.name);
      return addContainer(d, ctx, spaceId: roomId, name: numberedName(name, taken));
    });
    if (s == null || !mounted) return;
    _madeSpots.add(s.id);
    _furPlace(s);
    _pickPlaced(s.id);
  }

  /// "방마다 흔한 보관함 놓기": the two most usual spots of every room on the map.
  Future<void> _placeUsual() async {
    final ko = ideasInKorean(context);
    final d0 = ref.read(homeProvider).requireValue;
    final picks = {
      for (final (room, ideas) in spotIdeasByRoom(d0, ko: ko))
        if (_draft.plans.containsKey(room.id) && ideas.isNotEmpty) room.id: ideas.take(2).toList(),
    };
    if (picks.isEmpty) return;
    final before = d0.containers.map((c) => c.id).toSet();
    await ref.read(homeProvider.notifier).apply((d, ctx) => addSpots(d, ctx, picks));
    if (!mounted) return;
    final d = ref.read(homeProvider).requireValue;
    for (final s in d.containers.where((c) => !before.contains(c.id))) {
      _madeSpots.add(s.id);
      _furPlace(s);
    }
    setState(() => _selected = null);
  }

  /// 자세히: the room's own screen (its icon, storage and things).
  void _openRoom(Space s) => context.push('/space/${s.id}');

  /// Picks a piece placed from below the map and brings it into view.
  void _pickPlaced(String id) {
    _pickFurniture(id);
    WidgetsBinding.instance.addPostFrameCallback((_) => _editor.currentState?.focusPicked());
  }

  /// A chip dragged onto the map: the piece stands where it was let go, in
  /// the room there (or a free spot of its own room when let go outside).
  void _furDropped(Storage s, Offset global) {
    final sq = _editor.currentState?.squareAt(global);
    final rooms = _draft.plans;
    final (w, h) = floorSize(s.kind);
    final at = sq == null ? null : PlanRect(sq.$1 - w ~/ 2, sq.$2 - h ~/ 2, w, h);
    final inRoom = at != null && rooms.values.any((r) => sq!.$1 >= r.x && sq.$1 < r.right && sq.$2 >= r.y && sq.$2 < r.bottom);
    inRoom ? _furMoved(s.id, at) : _furPlace(s);
    _pickPlaced(s.id);
  }

  /// "붙은 벽 같이 밀기": a side knob on a shared wall moves the neighbour's wall too.
  bool _shareWalls = true;

  /// A piece not on the map yet goes into a free spot of its room.
  void _furPlace(Storage s) {
    final room = _draft.plans[s.spaceId];
    if (room == null) return;
    final (w, h) = floorSize(s.kind);
    final taken = [
      for (final f in _fur.plans.values)
        if (f.room == s.spaceId) f.r,
    ];
    var spot = PlanRect(0, 0, w.clamp(1, room.w), h.clamp(1, room.h));
    search:
    for (var y = 0; y + h <= room.h; y++) {
      for (var x = 0; x + w <= room.w; x++) {
        final r = PlanRect(x, y, w, h);
        if (!taken.any(r.overlaps)) {
          spot = r;
          break search;
        }
      }
    }
    _fur.set(s.id, (room: s.spaceId, r: spot));
  }

  /// Floor pieces of rooms on the map that are not placed yet.
  List<Storage> _waiting(HomeData d) => [
    for (final id in _draft.plans.keys)
      for (final s in floorStorages(d, id))
        if (!_fur.plans.containsKey(s.id)) s,
  ];

  /// Rooms made while editing: gone again if the edit is dropped.
  final _made = <String>{};

  /// The floor-plan photo under the squares (this phone only).
  late String? _photo = ref.read(settingsProvider.notifier).planPhoto;
  late bool _photoShown = ref.read(settingsProvider.notifier).planPhotoShown;
  late double _photoScale = ref.read(settingsProvider.notifier).planPhotoScale;

  void _redraw() => setState(() {});

  @override
  void dispose() {
    _draft.dispose();
    _fur.dispose();
    super.dispose();
  }

  /// The tab's own colour (user request): green for rooms, honey for furniture.
  Color _tabColor(AppColors c) => _furnitureTab ? c.accentInk : c.secondaryInk;

  bool get _dirty => _draft.changed || _fur.changed || _made.isNotEmpty || _madeSpots.isNotEmpty;

  /// A new room in the middle of what is in view, picked.
  Future<void> _addRoom() async {
    final s = await addSpaceFlow(context, ref, open: false);
    if (s == null || !mounted) return;
    final (x, y) = _editor.currentState?.centreSquare() ?? (0, 0);
    _made.add(s.id);
    _draft.set(s.id, PlanRect(x - 3, y - 3, 6, 6));
    setState(() => _selected = s.id);
  }

  /// 저장: overlaps are asked about once; the plan is kept starting at 0, 0.
  /// True when it was saved.
  Future<bool> _save({bool ask = true}) async {
    final d = ref.read(homeProvider).requireValue;
    final laps = overlappingPlans(_draft.plans);
    if (ask && laps.isNotEmpty) {
      final keep = await askKeepOverlaps(context, [for (final id in laps) d.space(id)?.name ?? '']);
      if (keep != true) {
        if (keep == false) setState(() => _selected = laps.first);
        return false;
      }
    }
    final plans = normalizePlans(_draft.plans);
    // Empty rooms left twice under one name go (user report: two 다용도실).
    final fur = _fur.plans;
    await ref.read(homeProvider.notifier).apply((d, _) {
      var out = saveRoomPlans(d, plans);
      // Furniture: where it was put, in the room it was put in; the rest off the floor.
      for (final room in plannedRooms(d)) {
        for (final s in floorStorages(d, room.id)) {
          final f = fur[s.id];
          out = f == null ? setStoragePlan(out, s.id, null) : moveToRoomFloor(out, s.id, f.room, f.r);
        }
      }
      // Empty rooms left twice under one name go (user report: two 다용도실).
      return dropEmptyTwins(out);
    });
    _made.clear();
    _madeSpots.clear();
    final now = ref.read(homeProvider).requireValue;
    _draft.saved({for (final s in plannedRooms(now)) s.id: s.plan!});
    _fur.saved(_floorSpots(now));
    return true;
  }

  Future<void> _done() async {
    if (!await _save() || !mounted) return;
    if (widget.start) {
      // ① rooms → ② storage on the same map → ③ things.
      if (!_furnitureTab) {
        setState(() {
          _furnitureTab = true;
          _selected = null;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _editor.currentState?.fit());
        return;
      }
      context.pushReplacement('/fill?things=1');
      return;
    }
    // A new home with rooms but no storage yet goes on to picking spots and things.
    final d = ref.read(homeProvider).requireValue;
    if (d.containers.isEmpty && d.spaces.any((s) => !s.outside && !s.moving)) {
      context.pushReplacement('/fill');
    } else {
      context.canPop() ? context.pop() : context.go('/');
    }
  }

  /// 취소: the draft goes, and rooms made while editing with it.
  Future<void> _cancel() async {
    if (_dirty && !await confirmDropDraft(context)) return;
    if (_made.isNotEmpty || _madeSpots.isNotEmpty) {
      final made = {..._made}, spots = {..._madeSpots};
      await ref.read(homeProvider.notifier).apply((d, _) {
        var out = d;
        for (final id in spots) {
          if (out.container(id) != null) out = deleteContainer(out, id);
        }
        for (final id in made) {
          out = deleteSpace(out, id);
        }
        return out;
      });
    }
    _made.clear();
    _madeSpots.clear();
    if (mounted) context.canPop() ? context.pop() : context.go('/');
  }

  Future<void> _photoMenu() async {
    final l = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider.notifier);
    if (_photo == null || !File(_photo!).existsSync()) {
      final r = await choosePhoto(context, ref, hasPhoto: false, keepLarge: true);
      if (r?.path == null) return;
      await settings.setPlanPhoto(r!.path);
      setState(() {
        _photo = r.path;
        _photoShown = true;
      });
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(l.planPhoto),
            ListTile(
              leading: Icon(_photoShown ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              title: Text(_photoShown ? l.planPhotoHide : l.planPhotoShow),
              onTap: () => Navigator.pop(context, 'toggle'),
            ),
            ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(l.planPhotoChange), onTap: () => Navigator.pop(context, 'change')),
            ListTile(leading: const Icon(Icons.hide_image_outlined), title: Text(l.planPhotoRemove), onTap: () => Navigator.pop(context, 'remove')),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'toggle':
        await settings.setPlanPhotoShown(!_photoShown);
        setState(() => _photoShown = !_photoShown);
      case 'change':
        setState(() => _photo = null);
        await _photoMenu();
      case 'remove':
        await settings.setPlanPhoto(null);
        setState(() => _photo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final plans = _draft.plans;
    final photo = _photo != null && _photoShown && File(_photo!).existsSync() ? _photo : null;
    final picked = _furnitureTab || _selected == null || !plans.containsKey(_selected) ? null : d.space(_selected!);
    final laps = overlappingPlans(plans);
    final furOnMap = _furOnMap;
    final pickedFur = !_furnitureTab || _selected == null || !furOnMap.containsKey(_selected) ? null : d.container(_selected!);
    final draft = _furnitureTab ? _fur : _draft;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(key: const ValueKey('plan-cancel'), tooltip: l.planCancel, onPressed: _cancel, icon: const Icon(Icons.close_rounded)),
          titleSpacing: 0,
          title: OneLine(widget.start ? [l.houseStartTitle, l.houseStartShort] : [l.houseEditTitle, l.houseEditShort]),
          actions: [
            IconButton(
              key: const ValueKey('plan-undo'),
              tooltip: l.planUndo,
              onPressed: draft.canUndo ? draft.undo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              key: const ValueKey('plan-redo'),
              tooltip: l.planRedo,
              onPressed: draft.canRedo ? draft.redo : null,
              icon: const Icon(Icons.redo_rounded),
            ),
            IconButton(key: const ValueKey('plan-photo'), tooltip: l.planPhoto, onPressed: _photoMenu, icon: const Icon(Icons.add_photo_alternate_outlined)),
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.sm),
              child: FilledButton(key: const ValueKey('house-done'), onPressed: _done, child: Text(widget.start ? l.planNext : l.planSave)),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.start) _Steps(step: _furnitureTab ? 1 : 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                // The tab picks what can be picked on the map, so it shows
                // plainly which one is on (user request): its colour, filled.
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? _tabColor(c) : c.card),
                  foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.card : c.fg),
                  iconColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.card : c.mutedFg),
                  side: WidgetStatePropertyAll(BorderSide(color: _tabColor(c), width: 1.5)),
                  textStyle: const WidgetStatePropertyAll(AppType.label),
                ),
                segments: [
                  ButtonSegment(value: false, label: Text(l.planTabRooms), icon: const Icon(Icons.meeting_room_rounded)),
                  ButtonSegment(value: true, label: Text(l.planTabFurniture), icon: const Icon(Icons.chair_rounded)),
                ],
                selected: {_furnitureTab},
                onSelectionChanged: (v) {
                  setState(() {
                    _furnitureTab = v.first;
                    _selected = null;
                  });
                  // The whole house in view on either tab.
                  WidgetsBinding.instance.addPostFrameCallback((_) => _editor.currentState?.fit());
                },
              ),
            ),
            _furnitureTab
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
                    child: FitText(pickedFur != null ? l.planHintFurniturePicked : l.planHintFurniture, style: AppType.caption.copyWith(color: c.mutedFg)),
                  )
                : PlanHint(picked: picked != null),
            if (photo != null && !_furnitureTab)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                child: Row(
                  children: [
                    Text(l.planPhotoSize, style: AppType.caption.copyWith(color: c.mutedFg)),
                    Expanded(
                      child: Slider(
                        key: const ValueKey('plan-photo-scale'),
                        value: _photoScale,
                        min: 0.5,
                        max: 2,
                        onChanged: (v) => setState(() => _photoScale = v),
                        onChangeEnd: ref.read(settingsProvider.notifier).setPlanPhotoScale,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(border: Border.all(color: _tabColor(c), width: 3)),
                child: _furnitureTab
                    ? DragTarget<String>(
                        onAcceptWithDetails: (det) {
                          if (d.container(det.data) case final s?) _furDropped(s, det.offset);
                        },
                        builder: (context, _, _) => PlanEditor(
                          key: _editor,
                          keyPrefix: 'house-fur',
                          plans: furOnMap,
                          selected: pickedFur?.id,
                          min: 1,
                          onSelect: _pickFurniture,
                          onChange: _furMoved,
                          onTapFloor: _tapFloor,
                          extent: plans.values.toList(),
                          where: (r) {
                            final cx = r.x + r.w / 2, cy = r.y + r.h / 2;
                            final room = plans.entries
                                .where((e) => cx >= e.value.x && cx <= e.value.right && cy >= e.value.y && cy <= e.value.bottom)
                                .firstOrNull;
                            return room == null ? null : d.space(room.key)?.name;
                          },
                          // The rooms stand still under the furniture.
                          under: [
                            for (final e in plans.entries)
                              if (d.space(e.key) case final s?)
                                Positioned(
                                  left: e.value.x * kPlanCell,
                                  top: e.value.y * kPlanCell,
                                  width: e.value.w * kPlanCell,
                                  height: e.value.h * kPlanCell,
                                  child: IgnorePointer(
                                    // Clear walls between rooms (user report: too faint to see
                                    // which room a piece goes into).
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CustomPaint(painter: _RoomPainter(fill: c.secondarySoft, seed: s.id.hashCode, bold: true)),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: c.secondaryInk, width: e.key == _targetRoom() && pickedFur == null ? 5 : 2),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.all(3),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(color: c.secondaryInk, borderRadius: BorderRadius.circular(6)),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                child: Text(s.name, style: AppType.caption.copyWith(fontSize: 10, color: c.card)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                          block: (id, r, on) {
                            final s = d.container(id);
                            return s == null ? const SizedBox.shrink() : _piece(s, on, c);
                          },
                        ),
                      )
                    : PlanEditor(
                        key: _editor,
                        keyPrefix: 'house-room',
                        plans: plans,
                        selected: picked?.id,
                        onSelect: (id) => setState(() => _selected = id),
                        onChange: _draft.set,
                        onChangeMany: _draft.setAll,
                        grow: true,
                        shareWalls: _shareWalls,
                        under: [
                          if (photo != null)
                            Positioned(
                              left: 0,
                              top: 0,
                              width: 20 * kPlanCell * _photoScale,
                              child: IgnorePointer(
                                child: Opacity(opacity: 0.4, child: Image.file(File(photo), fit: BoxFit.fitWidth)),
                              ),
                            ),
                        ],
                        block: (id, r, on) {
                          final s = d.space(id);
                          return s == null ? const SizedBox.shrink() : _room(s, r, on, c);
                        },
                      ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
            child: _furnitureTab
                ? _furPanel(context, d, pickedFur)
                : picked == null
                ? _roomAdder(context, d)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: OneLine([picked.name], style: AppType.title)),
                          IconButton(
                            key: const ValueKey('house-rename'),
                            visualDensity: VisualDensity.compact,
                            tooltip: l.houseRename,
                            onPressed: () => editSpaceFlow(context, ref, picked),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            key: const ValueKey('plan-share-walls'),
                            visualDensity: VisualDensity.compact,
                            tooltip: _shareWalls ? l.planShareWalls : l.planShareWallsOff,
                            isSelected: _shareWalls,
                            style: IconButton.styleFrom(backgroundColor: _shareWalls ? c.secondarySoft : null),
                            onPressed: () => setState(() => _shareWalls = !_shareWalls),
                            icon: Icon(Icons.link_off_rounded, color: c.mutedFg),
                            selectedIcon: Icon(Icons.link_rounded, color: c.secondaryInk),
                          ),
                          IconButton(
                            key: const ValueKey('house-delete'),
                            visualDensity: VisualDensity.compact,
                            tooltip: l.planDelete,
                            onPressed: () async {
                              if (!await deleteSpaceFlow(context, ref, picked)) return;
                              _made.remove(picked.id);
                              _draft.set(picked.id, null);
                              setState(() => _selected = null);
                            },
                            icon: Icon(Icons.delete_outline_rounded, color: c.danger),
                          ),
                          IconButton(
                            key: const ValueKey('house-info'),
                            visualDensity: VisualDensity.compact,
                            tooltip: l.planInfo,
                            onPressed: () => _openRoom(picked),
                            icon: const Icon(Icons.open_in_new_rounded),
                          ),
                          IconButton(
                            key: const ValueKey('plan-close-pick'),
                            tooltip: l.planUnpick,
                            onPressed: () => setState(() => _selected = null),
                            icon: const Icon(Icons.expand_more_rounded),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: PlanSizeSteppers(
                              rect: plans[picked.id]!,
                              onChange: (r) {
                                final ed = _editor.currentState, ok = ed == null ? r : ed.admit(r);
                                if (ok != null) _draft.set(picked.id, ok);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          PlanNudgePad(editor: _editor),
                        ],
                      ),
                      if (laps.contains(picked.id))
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.xs),
                          child: OneLine([l.planOverlapsHere], style: AppType.caption.copyWith(color: c.danger)),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Under the map in the 가구 tab: the picked piece, or what is not placed yet.
  Widget _furPanel(BuildContext context, HomeData d, Storage? picked) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    if (picked != null) {
      final spot = _fur.plans[picked.id]!;
      final room = _draft.plans[spot.room]!;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: OneLine(['${picked.name} · ${d.space(spot.room)?.name ?? ''}', picked.name], style: AppType.title)),
              IconButton(
                key: const ValueKey('fur-rename'),
                visualDensity: VisualDensity.compact,
                tooltip: l.houseRename,
                onPressed: () => editStorageFlow(context, ref, picked),
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                key: const ValueKey('fur-turn'),
                visualDensity: VisualDensity.compact,
                tooltip: l.planRotate,
                onPressed: () => _fur.set(picked.id, (room: spot.room, r: turnPlan(spot.r, within: PlanRect(0, 0, room.w, room.h)))),
                icon: const Icon(Icons.rotate_90_degrees_cw_rounded),
              ),
              IconButton(
                key: const ValueKey('fur-take-off'),
                visualDensity: VisualDensity.compact,
                tooltip: l.houseTakeOff,
                onPressed: () {
                  _fur.set(picked.id, null);
                  setState(() => _selected = null);
                },
                icon: const Icon(Icons.layers_clear_rounded),
              ),
              IconButton(
                key: const ValueKey('fur-delete'),
                visualDensity: VisualDensity.compact,
                tooltip: l.planDelete,
                onPressed: () async {
                  if (!await deleteStorageFlow(context, ref, picked)) return;
                  _madeSpots.remove(picked.id);
                  _fur.set(picked.id, null);
                  setState(() => _selected = null);
                },
                icon: Icon(Icons.delete_outline_rounded, color: c.danger),
              ),
              IconButton(
                key: const ValueKey('fur-info'),
                visualDensity: VisualDensity.compact,
                tooltip: l.planInfo,
                onPressed: () => context.push('/storage/${picked.id}'),
                icon: const Icon(Icons.open_in_new_rounded),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: PlanSizeSteppers(
                  rect: spot.r,
                  min: 1,
                  within: PlanRect(0, 0, room.w, room.h),
                  onChange: (r) => _fur.set(picked.id, (room: spot.room, r: r)),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              PlanNudgePad(editor: _editor),
            ],
          ),
        ],
      );
    }
    final waiting = _waiting(d);
    final target = _targetRoom();
    final room = target == null ? null : d.space(target);
    final ideas = room == null
        ? const <String>[]
        : spotIdeasByRoom(d, ko: ideasInKorean(context)).where((e) => e.$1.id == room.id).map((e) => e.$2).firstOrNull ?? const <String>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (room != null) ...[
          OneLine(['${l.planFurAddTo(room.name)} · ${l.planFurAddHint}', l.planFurAddTo(room.name)], style: AppType.label),
          const SizedBox(height: AppSpace.xs),
          ChipLine(
            children: [
              for (final n in ideas)
                ActionChip(
                  key: ValueKey('fur-add-$n'),
                  avatar: Icon(Icons.add_rounded, size: 18, color: c.accentInk),
                  label: Text(n),
                  onPressed: () => _addSpotNamed(room.id, n),
                ),
              ActionChip(
                key: const ValueKey('fur-add-own'),
                avatar: Icon(Icons.edit_rounded, size: 18, color: c.accentInk),
                label: Text(l.planAddOwn),
                onPressed: () async {
                  final s = await addStorageFlow(context, ref, room.id);
                  if (s == null || !mounted) return;
                  _madeSpots.add(s.id);
                  _furPlace(s);
                  _pickPlaced(s.id);
                },
              ),
            ],
          ),
          // One big button at a time: the usual storage, or the ones waiting.
          if (widget.start && waiting.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: FilledButton.tonalIcon(
                key: const ValueKey('fur-place-usual'),
                onPressed: _placeUsual,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: OneLine([l.planFurUsual]),
              ),
            ),
          const SizedBox(height: AppSpace.sm),
        ],
        Row(
          children: [
            Expanded(
              child: OneLine([waiting.isEmpty ? l.planFurAllPlaced : l.planFurWaiting(waiting.length)], style: AppType.caption.copyWith(color: c.mutedFg)),
            ),
            IconButton(
              key: const ValueKey('fur-fit'),
              tooltip: l.planFit,
              onPressed: () => _editor.currentState?.fit(),
              icon: const Icon(Icons.fit_screen_rounded),
            ),
          ],
        ),
        if (waiting.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          ChipLine(
            children: [
              for (final s in waiting)
                // Dragged up onto the map it stands where it is let go
                // (sideways the line scrolls); tapped, it takes a free spot.
                Draggable<String>(
                  data: s.id,
                  affinity: Axis.vertical,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Transform.translate(
                      offset: const Offset(-24, -24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          border: Border.all(color: c.accentInk, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(child: storageGlyph(s, size: 24, color: c.accentInk)),
                      ),
                    ),
                  ),
                  child: ActionChip(
                    key: ValueKey('fur-place-${s.id}'),
                    avatar: storageGlyph(s, size: 18, color: c.accentInk),
                    label: Text('${s.name} · ${d.space(s.spaceId)?.name ?? ''}'),
                    onPressed: () {
                      _furPlace(s);
                      _pickPlaced(s.id);
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          FilledButton.tonalIcon(
            key: const ValueKey('fur-place-all'),
            onPressed: () {
              for (final s in waiting) {
                _furPlace(s);
              }
            },
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: OneLine([l.planFurPlaceAll]),
          ),
        ],
      ],
    );
  }

  /// Under the map on the 방 tab with nothing picked: rooms to add, one tap each.
  Widget _roomAdder(BuildContext context, HomeData d) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final ko = ideasInKorean(context);
    final taken = d.spaces.map((s) => s.name).toSet();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: OneLine([l.planAddRoomTitle], style: AppType.label)),
            IconButton(
              key: const ValueKey('plan-fit'),
              tooltip: l.planFit,
              onPressed: () => _editor.currentState?.fit(),
              icon: const Icon(Icons.fit_screen_rounded),
            ),
          ],
        ),
        ChipLine(
          children: [
            for (final n in (ko ? roomIdeas.$1 : roomIdeas.$2).where((n) => !taken.contains(n)))
              ActionChip(
                key: ValueKey('house-add-$n'),
                avatar: Icon(Icons.add_rounded, size: 18, color: c.secondaryInk),
                label: Text(n),
                onPressed: () => _addRoomNamed(n),
              ),
            ActionChip(
              key: const ValueKey('house-add-room'),
              avatar: Icon(Icons.edit_rounded, size: 18, color: c.secondaryInk),
              label: Text(l.planAddOwn),
              onPressed: _addRoom,
            ),
          ],
        ),
      ],
    );
  }

  Widget _piece(Storage s, bool picked, AppColors c) => Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(
        painter: FurniturePainter(fill: picked ? c.primarySoft : c.accentSoft, seed: s.id.hashCode, bold: picked),
      ),
      Padding(
        padding: const EdgeInsets.all(2),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(s.name, style: AppType.label.copyWith(fontSize: 12, color: picked ? c.primaryInk : c.accentInk)),
          ),
        ),
      ),
    ],
  );

  Widget _room(Space s, PlanRect r, bool picked, AppColors c) => Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(
        painter: _RoomPainter(fill: picked ? c.primarySoft : (s.icon == 'balcony' ? c.accentSoft : c.secondarySoft), seed: s.id.hashCode, bold: picked),
      ),
      Padding(
        padding: const EdgeInsets.all(4),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                spaceGlyph(s, size: 16, color: picked ? c.primaryInk : c.secondaryInk),
                Text(s.name, style: AppType.label.copyWith(fontSize: 12, color: picked ? c.primaryInk : c.secondaryInk)),
                Text('${planMeters(r.w)} × ${planMeters(r.h)}', style: AppType.caption.copyWith(fontSize: 10, color: c.mutedFg)),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// A room block drawn like the rest of our pictures: flat fill, crayon edge.
class _RoomPainter extends CustomPainter {
  _RoomPainter({required this.fill, required this.seed, required this.bold});

  final Color fill;
  final int seed;
  final bool bold;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect((Offset.zero & size).deflate(1.5));
    canvas.drawPath(path, Paint()..color = fill);
    Doodle.crayon(canvas, path, Doodle.line(Doodle.ink, bold ? 2.6 : 1.8), wobble: 0.9, step: 3, seed: seed);
  }

  @override
  bool shouldRepaint(_RoomPainter old) => old.fill != fill || old.bold != bold;
}

/// ① 방 · ② 보관함 · ③ 물건 on a new home's first start.
class _Steps extends StatelessWidget {
  const _Steps({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final names = [l.planStepRooms, l.planStepSpots, l.planStepThings];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
      child: Row(
        children: [
          for (final (i, n) in names.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Container(
                key: ValueKey('plan-step-$i'),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: i == step ? c.primary : (i < step ? c.primarySoft : c.muted),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: OneLine([n], textAlign: TextAlign.center, style: AppType.label.copyWith(fontSize: 13, color: i == step ? c.onPrimary : (i < step ? c.primaryInk : c.mutedFg))),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
