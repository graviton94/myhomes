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

/// HOU-02: rooms as blocks on 0.5 m squares, edited as a draft
/// (plan_editor.dart): drag any room to move it, stretch the picked one from
/// near its walls or corners, 저장 keeps it, 취소 puts it back. Not a floor
/// plan editor: no walls, doors or windows.
class HouseEditScreen extends ConsumerStatefulWidget {
  const HouseEditScreen({super.key});

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

  /// A piece not on the map yet goes into a free spot of its room.
  void _furPlace(Storage s) {
    final room = _draft.plans[s.spaceId];
    if (room == null) return;
    final (w, h) = floorSize(s.kind);
    final taken = [for (final f in _fur.plans.values) if (f.room == s.spaceId) f.r];
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

  bool get _dirty => _draft.changed || _fur.changed || _made.isNotEmpty;

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
    final now = ref.read(homeProvider).requireValue;
    _draft.saved({for (final s in plannedRooms(now)) s.id: s.plan!});
    _fur.saved(_floorSpots(now));
    return true;
  }

  Future<void> _done() async {
    if (!await _save() || !mounted) return;
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
    if (_made.isNotEmpty) {
      final made = {..._made};
      await ref.read(homeProvider.notifier).apply((d, _) {
        var out = d;
        for (final id in made) {
          out = deleteSpace(out, id);
        }
        return out;
      });
    }
    _made.clear();
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
          title: OneLine([l.houseEditTitle, l.houseEditShort]),
          actions: [
            IconButton(key: const ValueKey('plan-undo'), tooltip: l.planUndo, onPressed: draft.canUndo ? draft.undo : null, icon: const Icon(Icons.undo_rounded)),
            IconButton(key: const ValueKey('plan-redo'), tooltip: l.planRedo, onPressed: draft.canRedo ? draft.redo : null, icon: const Icon(Icons.redo_rounded)),
            IconButton(key: const ValueKey('plan-photo'), tooltip: l.planPhoto, onPressed: _photoMenu, icon: const Icon(Icons.add_photo_alternate_outlined)),
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.sm),
              child: FilledButton(key: const ValueKey('house-done'), onPressed: _done, child: Text(l.planSave)),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
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
              child: _furnitureTab
                  ? PlanEditor(
                      key: _editor,
                      keyPrefix: 'house-fur',
                      plans: furOnMap,
                      selected: pickedFur?.id,
                      min: 1,
                      onSelect: (id) => setState(() => _selected = id),
                      onChange: _furMoved,
                      extent: plans.values.toList(),
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
                                child: Opacity(
                                  opacity: 0.8,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CustomPaint(painter: _RoomPainter(fill: c.secondarySoft, seed: s.id.hashCode, bold: false)),
                                      Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Text(s.name, style: AppType.caption.copyWith(fontSize: 11, color: c.secondaryInk)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],
                      block: (id, r, on) {
                        final s = d.container(id);
                        return s == null ? const SizedBox.shrink() : _piece(s, on, c);
                      },
                    )
                  : PlanEditor(
                key: _editor,
                keyPrefix: 'house-room',
                plans: plans,
                selected: picked?.id,
                onSelect: (id) => setState(() => _selected = id),
                onChange: _draft.set,
                under: [
                  if (photo != null)
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 20 * kPlanCell * _photoScale,
                      child: IgnorePointer(child: Opacity(opacity: 0.4, child: Image.file(File(photo), fit: BoxFit.fitWidth))),
                    ),
                ],
                block: (id, r, on) {
                  final s = d.space(id);
                  return s == null ? const SizedBox.shrink() : _room(s, r, on, c);
                },
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
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey('plan-fit'),
                          onPressed: () => _editor.currentState?.fit(),
                          icon: const Icon(Icons.fit_screen_rounded),
                          label: OneLine([l.planFit]),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          key: const ValueKey('house-add-room'),
                          onPressed: _addRoom,
                          icon: const Icon(Icons.add_rounded),
                          label: OneLine([l.houseAddRoom]),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: OneLine([picked.name], style: AppType.title)),
                          IconButton(
                            key: const ValueKey('house-furniture'),
                            tooltip: l.roomPlaceFurniture,
                            onPressed: () async {
                              // The room's own editor works on the saved plan.
                              if (_draft.changed && !await _save(ask: false)) return;
                              if (context.mounted) context.push('/house/room/${picked.id}');
                            },
                            icon: const Icon(Icons.chair_outlined),
                          ),
                          IconButton(tooltip: l.houseRename, onPressed: () => editSpaceFlow(context, ref, picked), icon: const Icon(Icons.edit_rounded)),
                          IconButton(
                            key: const ValueKey('house-take-off'),
                            tooltip: l.houseTakeOff,
                            onPressed: () {
                              _draft.set(picked.id, null);
                              setState(() => _selected = null);
                            },
                            icon: const Icon(Icons.layers_clear_rounded),
                          ),
                          IconButton(
                            key: const ValueKey('plan-close-pick'),
                            tooltip: l.planUnpick,
                            onPressed: () => setState(() => _selected = null),
                            icon: const Icon(Icons.expand_more_rounded),
                          ),
                        ],
                      ),
                      PlanSizeSteppers(rect: plans[picked.id]!, onChange: (r) => _draft.set(picked.id, r)),
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
                key: const ValueKey('fur-take-off'),
                tooltip: l.houseTakeOff,
                onPressed: () {
                  _fur.set(picked.id, null);
                  setState(() => _selected = null);
                },
                icon: const Icon(Icons.layers_clear_rounded),
              ),
              IconButton(
                key: const ValueKey('plan-close-pick'),
                tooltip: l.planUnpick,
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.expand_more_rounded),
              ),
            ],
          ),
          PlanSizeSteppers(
            rect: spot.r,
            min: 1,
            within: PlanRect(0, 0, room.w, room.h),
            onChange: (r) => _fur.set(picked.id, (room: spot.room, r: r)),
          ),
        ],
      );
    }
    final waiting = _waiting(d);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OneLine([waiting.isEmpty ? l.planFurAllPlaced : l.planFurWaiting(waiting.length)], style: AppType.caption.copyWith(color: c.mutedFg)),
        if (waiting.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          ChipLine(
            children: [
              for (final s in waiting)
                ActionChip(
                  key: ValueKey('fur-place-${s.id}'),
                  avatar: storageGlyph(s, size: 18, color: c.accentInk),
                  label: Text('${s.name} · ${d.space(s.spaceId)?.name ?? ''}'),
                  onPressed: () {
                    _furPlace(s);
                    setState(() => _selected = s.id);
                  },
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

  Widget _piece(Storage s, bool picked, AppColors c) => Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(painter: FurniturePainter(fill: picked ? c.primarySoft : c.accentSoft, seed: s.id.hashCode, bold: picked)),
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
        painter: _RoomPainter(
          fill: picked ? c.primarySoft : (s.icon == 'balcony' ? c.accentSoft : c.secondarySoft),
          seed: s.id.hashCode,
          bold: picked,
        ),
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
