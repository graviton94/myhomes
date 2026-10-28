import 'dart:io';
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
import '../../settings/settings.dart';
import '../../widgets/doodle.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/sheets.dart';
import '../spaces/space_actions.dart';

/// HOU-02: rooms as blocks on 0.5 m squares. Drag a block to move it, drag
/// its corner dot to resize; everything snaps to the squares. Not a floor
/// plan editor: no walls, doors or windows.
class HouseEditScreen extends ConsumerStatefulWidget {
  const HouseEditScreen({super.key});

  @override
  ConsumerState<HouseEditScreen> createState() => _HouseEditScreenState();
}

class _HouseEditScreenState extends ConsumerState<HouseEditScreen> {
  String? _selected;

  /// The floor-plan photo under the squares (this phone only).
  late String? _photo = ref.read(settingsProvider.notifier).planPhoto;
  late bool _photoShown = ref.read(settingsProvider.notifier).planPhotoShown;
  late double _photoScale = ref.read(settingsProvider.notifier).planPhotoScale;

  /// The block being dragged, before it is saved.
  String? _dragging;
  PlanRect? _live;
  Offset _drag = Offset.zero;

  void _start(Space s) {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = s.id;
      _dragging = s.id;
      _live = s.plan;
      _drag = Offset.zero;
    });
  }

  void _update(Space s, Offset delta, double cell, {required bool resize}) {
    _drag += delta;
    final dx = (_drag.dx / cell).round(), dy = (_drag.dy / cell).round();
    final p = s.plan!;
    setState(
      () => _live = resize
          ? PlanRect(p.x, p.y, math.max(2, p.w + dx), math.max(2, p.h + dy))
          : PlanRect(math.max(0, p.x + dx), math.max(0, p.y + dy), p.w, p.h),
    );
  }

  Future<void> _end(Space s) async {
    final r = _live;
    setState(() {
      _dragging = null;
      _live = null;
    });
    if (r != null && r != s.plan) await ref.read(homeProvider.notifier).apply((d, _) => setRoomPlan(d, s.id, r));
  }

  Future<void> _addRoom() async {
    final s = await addSpaceFlow(context, ref, open: false);
    if (s == null) return;
    await ref.read(homeProvider.notifier).apply((d, _) => setRoomPlan(d, s.id, freePlanSpot(d)));
    setState(() => _selected = s.id);
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
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.planPhotoChange),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            ListTile(
              leading: const Icon(Icons.hide_image_outlined),
              title: Text(l.planPhotoRemove),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
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
    final rooms = plannedRooms(d);
    final photo = _photo != null && _photoShown && File(_photo!).existsSync() ? _photo : null;
    final (cols, rows) = planSize(d);
    final selected = _selected == null ? null : d.space(_selected!);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.houseEditTitle),
        actions: [
          IconButton(
            key: const ValueKey('plan-photo'),
            tooltip: l.planPhoto,
            onPressed: _photoMenu,
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          TextButton(
            key: const ValueKey('house-done'),
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
            child: Text(l.houseEditHint, style: AppType.caption.copyWith(color: c.mutedFg)),
          ),
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
            child: LayoutBuilder(
              builder: (context, box) {
                // Room to grow: a few empty squares around what is placed.
                final gridCols = math.max(cols + 4, 16);
                final cell = (box.maxWidth - AppSpace.lg * 2) / gridCols;
                final gridRows = math.max(rows + 6, (box.maxHeight / cell).floor());
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = null),
                    child: SizedBox(
                      width: gridCols * cell,
                      height: gridRows * cell,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (photo != null)
                            Positioned(
                              left: 0,
                              top: 0,
                              width: gridCols * cell * _photoScale,
                              child: IgnorePointer(
                                child: Opacity(opacity: 0.4, child: Image.file(File(photo), fit: BoxFit.fitWidth)),
                              ),
                            ),
                          Positioned.fill(child: CustomPaint(painter: _GridPainter(cell, c.border))),
                          for (final s in rooms) _block(s, cell, c),
                        ],
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
          child: selected == null
              ? Row(
                  children: [
                    Expanded(
                      child: Text(l.houseTapBlock, style: AppType.caption.copyWith(color: c.mutedFg)),
                    ),
                    FilledButton.tonalIcon(
                      key: const ValueKey('house-add-room'),
                      onPressed: _addRoom,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l.houseAddRoom),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${selected.name} · ${_meters(selected.plan)}',
                        style: AppType.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('house-furniture'),
                      tooltip: l.roomPlaceFurniture,
                      onPressed: () => context.push('/house/room/${selected.id}'),
                      icon: const Icon(Icons.chair_outlined),
                    ),
                    IconButton(
                      tooltip: l.houseRename,
                      onPressed: () => editSpaceFlow(context, ref, selected),
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    IconButton(
                      tooltip: l.houseTakeOff,
                      onPressed: () async {
                        await ref.read(homeProvider.notifier).apply((d, _) => setRoomPlan(d, selected.id, null));
                        setState(() => _selected = null);
                      },
                      icon: const Icon(Icons.layers_clear_rounded),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// "4.5 × 4.5 m".
  String _meters(PlanRect? p) {
    if (p == null) return '';
    String m(int squares) => (squares / 2).toStringAsFixed(squares.isEven ? 0 : 1);
    return '${m(p.w)} × ${m(p.h)} m';
  }

  Widget _block(Space s, double cell, AppColors c) {
    final r = _dragging == s.id && _live != null ? _live! : s.plan!;
    final picked = _selected == s.id;
    return Positioned(
      left: r.x * cell,
      top: r.y * cell,
      width: r.w * cell,
      height: r.h * cell,
      child: GestureDetector(
        key: ValueKey('house-room-${s.id}'),
        onTap: () => setState(() => _selected = s.id),
        dragStartBehavior: DragStartBehavior.down, // count the finger's whole travel, so blocks land where dropped
        onPanStart: (_) => _start(s),
        onPanUpdate: (e) => _update(s, e.delta, cell, resize: false),
        onPanEnd: (_) => _end(s),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RoomPainter(
                  fill: picked ? c.primarySoft : (s.icon == 'balcony' ? c.accentSoft : c.secondarySoft),
                  seed: s.id.hashCode,
                  bold: picked,
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        spaceGlyph(s, size: 16, color: picked ? c.primaryInk : c.secondaryInk),
                        Text(s.name, style: AppType.label.copyWith(fontSize: 12, color: picked ? c.primaryInk : c.secondaryInk)),
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
                  key: ValueKey('house-resize-${s.id}'),
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

class _GridPainter extends CustomPainter {
  _GridPainter(this.cell, this.color);

  final double cell;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 0.6;
    for (var x = 0.0; x <= size.width + 0.1; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y <= size.height + 0.1; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.cell != cell || old.color != color;
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
