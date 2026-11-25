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
    super.dispose();
  }

  bool get _dirty => _draft.changed || _made.isNotEmpty;

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
    await ref.read(homeProvider.notifier).apply((d, _) => dropEmptyTwins(saveRoomPlans(d, plans)));
    _made.clear();
    final now = ref.read(homeProvider).requireValue;
    _draft.saved({for (final s in plannedRooms(now)) s.id: s.plan!});
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
    final picked = _selected == null || !plans.containsKey(_selected) ? null : d.space(_selected!);
    final laps = overlappingPlans(plans);

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
            IconButton(key: const ValueKey('plan-undo'), tooltip: l.planUndo, onPressed: _draft.canUndo ? _draft.undo : null, icon: const Icon(Icons.undo_rounded)),
            IconButton(key: const ValueKey('plan-redo'), tooltip: l.planRedo, onPressed: _draft.canRedo ? _draft.redo : null, icon: const Icon(Icons.redo_rounded)),
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
            PlanHint(picked: picked != null),
            if (photo != null)
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
              child: PlanEditor(
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
            child: picked == null
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
