import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/doodle.dart';

/// Places a room's furniture, boxes and spots on its floor: tap one below
/// to put it down, drag to move, drag the corner dot to resize. Squares are
/// 0.5 m, like the house plan.
class RoomEditScreen extends ConsumerStatefulWidget {
  const RoomEditScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<RoomEditScreen> createState() => _RoomEditScreenState();
}

class _RoomEditScreenState extends ConsumerState<RoomEditScreen> {
  String? _selected;
  String? _dragging;
  PlanRect? _live;
  Offset _drag = Offset.zero;

  void _start(Storage s) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = s.id;
      _dragging = s.id;
      _live = s.plan;
      _drag = Offset.zero;
    });
  }

  void _update(Storage s, Offset delta, double cell, {required bool resize}) {
    _drag += delta;
    final dx = (_drag.dx / cell).round(), dy = (_drag.dy / cell).round();
    final p = s.plan!;
    setState(
      () => _live = resize
          ? PlanRect(p.x, p.y, math.max(1, p.w + dx), math.max(1, p.h + dy))
          : PlanRect(math.max(0, p.x + dx), math.max(0, p.y + dy), p.w, p.h),
    );
  }

  Future<void> _end(Storage s) async {
    final r = _live;
    setState(() {
      _dragging = null;
      _live = null;
    });
    if (r != null && r != s.plan) await ref.read(homeProvider.notifier).apply((d, _) => setStoragePlan(d, s.id, r));
  }

  Future<void> _place(Storage s) async {
    final (w, h) = switch (s.kind) {
      StorageKind.furniture => (3, 1),
      StorageKind.box => (1, 1),
      _ => (2, 1),
    };
    await ref.read(homeProvider.notifier).apply((d, _) => setStoragePlan(d, s.id, freeStorageSpot(d, widget.spaceId, w: w, h: h)));
    setState(() => _selected = s.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final space = d.space(widget.spaceId);
    if (space == null) return const Scaffold();
    final room = space.plan ?? const PlanRect(0, 0, 8, 8);
    final storages = floorStorages(d, space.id);
    final placed = storages.where((s) => s.plan != null).toList();
    final waiting = storages.where((s) => s.plan == null).toList();
    final selected = _selected == null ? null : d.container(_selected!);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.roomEditTitle(space.name)),
        actions: [
          TextButton(
            key: const ValueKey('room-done'),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            child: Text(l.houseDone),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
            child: Text(l.roomEditHint, style: AppType.caption.copyWith(color: c.mutedFg)),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final cell = math.min((box.maxWidth - AppSpace.lg * 2) / room.w, (box.maxHeight - AppSpace.lg) / room.h);
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = null),
                      child: SizedBox(
                        width: room.w * cell,
                        height: room.h * cell,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: RoomFloorPainter(cell: cell, fill: c.secondarySoft, grid: c.border),
                              ),
                            ),
                            for (final s in placed) _block(s, cell, c),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
          child: selected != null
              ? Row(
                  children: [
                    Expanded(
                      child: Text(selected.name, style: AppType.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    TextButton.icon(
                      key: const ValueKey('room-take-off'),
                      onPressed: () async {
                        await ref.read(homeProvider.notifier).apply((d, _) => setStoragePlan(d, selected.id, null));
                        setState(() => _selected = null);
                      },
                      icon: const Icon(Icons.layers_clear_rounded),
                      label: Text(l.houseTakeOff),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(waiting.isEmpty ? l.roomAllPlaced : l.roomTapToPlace, style: AppType.caption.copyWith(color: c.mutedFg)),
                    if (waiting.isNotEmpty) ...[
                      const SizedBox(height: AppSpace.xs),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final s in waiting) ...[
                              ActionChip(
                                key: ValueKey('place-${s.id}'),
                                avatar: storageGlyph(s, size: 18, color: c.accentInk),
                                label: Text(s.name),
                                onPressed: () => _place(s),
                              ),
                              const SizedBox(width: AppSpace.sm),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _block(Storage s, double cell, AppColors c) {
    final r = _dragging == s.id && _live != null ? _live! : s.plan!;
    final picked = _selected == s.id;
    return Positioned(
      left: r.x * cell,
      top: r.y * cell,
      width: r.w * cell,
      height: r.h * cell,
      child: GestureDetector(
        key: ValueKey('room-block-${s.id}'),
        onTap: () => setState(() => _selected = s.id),
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (_) => _start(s),
        onPanUpdate: (e) => _update(s, e.delta, cell, resize: false),
        onPanEnd: (_) => _end(s),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: FurniturePainter(fill: picked ? c.primarySoft : c.accentSoft, seed: s.id.hashCode, bold: picked),
              ),
            ),
            Positioned.fill(
              child: Padding(
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
            ),
            if (picked)
              Positioned(
                right: -12,
                bottom: -12,
                child: GestureDetector(
                  key: ValueKey('room-resize-${s.id}'),
                  dragStartBehavior: DragStartBehavior.down,
                  onPanStart: (_) => _start(s),
                  onPanUpdate: (e) => _update(s, e.delta, cell, resize: true),
                  onPanEnd: (_) => _end(s),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.onPrimary, width: 3),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
