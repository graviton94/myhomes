import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chip_line.dart';
import '../../widgets/fit_text.dart';
import 'plan_editor.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/doodle.dart';

/// Places a room's furniture, boxes and spots on its floor, as a draft
/// (plan_editor.dart): tap one below to put it down, drag any piece to move
/// it, stretch the picked one from near its sides or corners; 저장 keeps
/// it, 취소 puts it back. Squares are 0.5 m, like the house plan.
class RoomEditScreen extends ConsumerStatefulWidget {
  const RoomEditScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<RoomEditScreen> createState() => _RoomEditScreenState();
}

class _RoomEditScreenState extends ConsumerState<RoomEditScreen> {
  String? _selected;
  final _editor = GlobalKey<PlanEditorState>();
  late final _draft = PlanDraft({
    for (final s in floorStorages(ref.read(homeProvider).requireValue, widget.spaceId))
      if (s.plan != null) s.id: s.plan!,
  })..addListener(_redraw);

  void _redraw() => setState(() {});

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _place(Storage s, PlanRect room) {
    final (w, h) = switch (s.kind) {
      StorageKind.furniture => (3, 1),
      StorageKind.box => (1, 1),
      _ => (2, 1),
    };
    final taken = _draft.plans.values.toList();
    var spot = PlanRect(0, 0, w, h);
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
    _draft.set(s.id, spot);
    setState(() => _selected = s.id);
  }

  Future<void> _save() async {
    final d = ref.read(homeProvider).requireValue;
    final laps = overlappingPlans(_draft.plans);
    if (laps.isNotEmpty) {
      final keep = await askKeepOverlaps(context, [for (final id in laps) d.container(id)?.name ?? '']);
      if (keep != true) {
        if (keep == false) setState(() => _selected = laps.first);
        return;
      }
    }
    final plans = _draft.plans;
    await ref.read(homeProvider.notifier).apply((d, _) => saveStoragePlans(d, widget.spaceId, plans));
    _draft.saved(plans);
    if (mounted) context.canPop() ? context.pop() : context.go('/');
  }

  Future<void> _cancel() async {
    if (_draft.changed && !await confirmDropDraft(context)) return;
    if (mounted) context.canPop() ? context.pop() : context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final space = d.space(widget.spaceId);
    if (space == null) return const Scaffold();
    final room = PlanRect(0, 0, space.plan?.w ?? 8, space.plan?.h ?? 8);
    final plans = _draft.plans;
    final waiting = floorStorages(d, space.id).where((s) => !plans.containsKey(s.id)).toList();
    final picked = _selected == null || !plans.containsKey(_selected) ? null : d.container(_selected!);
    final laps = overlappingPlans(plans);

    return PopScope(
      canPop: !_draft.changed,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(key: const ValueKey('plan-cancel'), tooltip: l.planCancel, onPressed: _cancel, icon: const Icon(Icons.close_rounded)),
          titleSpacing: 0,
          title: OneLine([l.roomEditTitle(space.name), space.name]),
          actions: [
            IconButton(key: const ValueKey('plan-undo'), tooltip: l.planUndo, onPressed: _draft.canUndo ? _draft.undo : null, icon: const Icon(Icons.undo_rounded)),
            IconButton(key: const ValueKey('plan-redo'), tooltip: l.planRedo, onPressed: _draft.canRedo ? _draft.redo : null, icon: const Icon(Icons.redo_rounded)),
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.sm),
              child: FilledButton(key: const ValueKey('room-done'), onPressed: _save, child: Text(l.planSave)),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlanHint(picked: picked != null),
            Expanded(
              child: PlanEditor(
                key: _editor,
                keyPrefix: 'room-block',
                plans: plans,
                selected: picked?.id,
                min: 1,
                within: room,
                onSelect: (id) => setState(() => _selected = id),
                onChange: _draft.set,
                under: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: room.w * kPlanCell,
                    height: room.h * kPlanCell,
                    child: IgnorePointer(child: CustomPaint(painter: RoomFloorPainter(cell: kPlanCell, fill: c.secondarySoft, grid: c.border))),
                  ),
                ],
                block: (id, r, on) {
                  final s = d.container(id);
                  return s == null ? const SizedBox.shrink() : _piece(s, on, c);
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
            child: picked != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: OneLine([picked.name], style: AppType.title)),
                          IconButton(
                            key: const ValueKey('plan-close-pick'),
                            tooltip: l.planUnpick,
                            onPressed: () => setState(() => _selected = null),
                            icon: const Icon(Icons.expand_more_rounded),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(child: PlanSizeSteppers(rect: plans[picked.id]!, min: 1, within: room, onChange: (r) => _draft.set(picked.id, r))),
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
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OneLine([waiting.isEmpty ? l.roomAllPlaced : l.roomTapToPlace], style: AppType.caption.copyWith(color: c.mutedFg)),
                      if (waiting.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.xs),
                        ChipLine(
                          children: [
                            for (final s in waiting)
                              ActionChip(
                                key: ValueKey('place-${s.id}'),
                                avatar: storageGlyph(s, size: 18, color: c.accentInk),
                                label: Text(s.name),
                                onPressed: () => _place(s, room),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _piece(Storage s, bool picked, AppColors c) => Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(painter: FurniturePainter(fill: picked ? c.primarySoft : c.accentSoft, seed: s.id.hashCode, bold: picked)),
      Padding(
        padding: const EdgeInsets.all(3),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                storageGlyph(s, size: 14, color: picked ? c.primaryInk : c.accentInk),
                const SizedBox(width: 3),
                Text(s.name, style: AppType.label.copyWith(fontSize: 12, color: picked ? c.primaryInk : c.accentInk)),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// The room's floor: flat fill, 0.5 m squares, crayon walls.
class RoomFloorPainter extends CustomPainter {
  RoomFloorPainter({required this.cell, required this.fill, required this.grid});

  final double cell;
  final Color fill;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final walls = Path()..addRect((Offset.zero & size).deflate(1.5));
    canvas.drawPath(walls, Paint()..color = fill);
    final p = Paint()
      ..color = grid.withValues(alpha: 0.7)
      ..strokeWidth = 0.6;
    for (var x = cell; x < size.width - 0.1; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = cell; y < size.height - 0.1; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    Doodle.crayon(canvas, walls, Doodle.line(Doodle.ink, 2.6), wobble: 0.9, step: 3, seed: 21);
  }

  @override
  bool shouldRepaint(RoomFloorPainter old) => old.cell != cell || old.fill != fill;
}

/// A piece of furniture seen from above, in the house style, with hatching
/// along its front edge.
class FurniturePainter extends CustomPainter {
  FurniturePainter({required this.fill, required this.seed, this.bold = false, this.width = 1.6});

  final Color fill;
  final int seed;
  final bool bold;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1.2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)));
    canvas.drawPath(path, Paint()..color = fill);
    final front = Rect.fromLTRB(rect.left, rect.bottom - math.min(6, rect.height * 0.3), rect.right, rect.bottom);
    Doodle.hatch(canvas, Path()..addRect(front), Doodle.honey.withValues(alpha: 0.7), gap: 3, width: 0.8);
    Doodle.crayon(canvas, path, Doodle.line(Doodle.ink, bold ? width + 1 : width), wobble: 0.6, step: 2.5, seed: seed);
  }

  @override
  bool shouldRepaint(FurniturePainter old) => old.fill != fill || old.bold != bold;
}
