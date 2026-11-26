// What the house and room editors share (user request, after trying the
// first editor and two mockups): the map is edited as a draft — nothing is
// kept until 저장, 취소 puts it back, ↶ ↷ step through it. Any block is
// grabbed and dragged at once; the picked block is stretched from anywhere
// near its walls (48 px outside, a quarter of the block inside), its corners
// both ways. Blocks may overlap while being arranged (shown hatched, asked
// about once on saving), the squares go on in every direction, a wall one
// square from a neighbour's is pulled onto it. One finger on empty floor
// moves the view, two fingers zoom. Rules: core plan_draft.dart.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/layers.dart';
import '../../widgets/sheets.dart';

/// Pixels per 0.5 m square on the plan, before zooming.
const kPlanCell = 24.0;

/// The house plan's draft: where each room stands.
typedef PlanDraft = Draft<PlanRect>;

/// Furniture placed on the house map: its room, and where in it.
typedef FloorSpot = ({String room, PlanRect r});

/// A draft being edited, with its steps back and forward.
class Draft<T> extends ChangeNotifier {
  Draft(Map<String, T> start) : _start = Map.of(start), _plans = Map.of(start);

  Map<String, T> _start;
  Map<String, T> _plans;
  final _undo = <Map<String, T>>[];
  final _redo = <Map<String, T>>[];

  Map<String, T> get plans => _plans;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get changed => !mapEquals(_plans, _start);

  /// Puts [id] at [r] (null takes it off), as one step.
  void set(String id, T? r) {
    _undo.add(Map.of(_plans));
    _redo.clear();
    _plans = Map.of(_plans);
    r == null ? _plans.remove(id) : _plans[id] = r;
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_plans);
    _plans = _undo.removeLast();
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_plans);
    _plans = _redo.removeLast();
    notifyListeners();
  }

  /// After saving: what is saved is the new start.
  void saved(Map<String, T> plans) {
    _start = Map.of(plans);
    _plans = Map.of(plans);
    _undo.clear();
    _redo.clear();
    notifyListeners();
  }
}

/// "Stop editing? Changes are not kept." True when the person lets the draft go.
Future<bool> confirmDropDraft(BuildContext context) {
  final l = AppLocalizations.of(context);
  return confirm(context, title: l.planDropTitle, body: l.planDropBody, action: l.planDropDo);
}

/// Blocks overlap: fix them (false) or keep them so (true); null = closed.
Future<bool?> askKeepOverlaps(BuildContext context, List<String> names) {
  final l = AppLocalizations.of(context);
  return askQuestion<bool>(
    context,
    title: l.planOverlapTitle,
    detail: l.planOverlapBody(names.join(' · ')),
    answers: [Answer(false, l.planOverlapFix), Answer(true, l.planOverlapKeep)],
  );
}

/// The squares with their blocks, edited by touch. [plans] is the draft; a
/// finished drag or stretch goes to [onChange].
class PlanEditor extends StatefulWidget {
  const PlanEditor({
    super.key,
    required this.plans,
    required this.selected,
    required this.onSelect,
    required this.onChange,
    required this.block,
    this.keyPrefix = 'plan',
    this.min = 2,
    this.within,
    this.under = const [],
    this.extent = const [],
  });

  final Map<String, PlanRect> plans;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final void Function(String id, PlanRect r) onChange;

  /// A block's drawing, sized to it; [picked] while it is the selected one.
  final Widget Function(String id, PlanRect r, bool picked) block;

  /// Names blocks for tests: `$keyPrefix-$id`.
  final String keyPrefix;
  final int min;

  /// A room's floor: furniture stays on it.
  final PlanRect? within;

  /// Drawn under the blocks, placed in plan pixels (a photo, the floor).
  final List<Widget> under;

  /// More to keep in view when zooming to fit (the rooms under furniture).
  final List<PlanRect> extent;

  @override
  State<PlanEditor> createState() => PlanEditorState();
}

enum _Kind { pan, move, stretch, pinch }

class _Gesture {
  _Gesture(this.kind, this.start, {this.id, this.from, this.handle});

  final _Kind kind;
  final Offset start;
  final String? id;
  final PlanRect? from;
  final PlanHandle? handle;
  bool moved = false;
  late Offset view;
  late double scale, span;
  late Offset focal;
}

class PlanEditorState extends State<PlanEditor> {
  static const _minScale = 0.3, _maxScale = 4.0;

  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _size = Size.zero;
  bool _fitted = false;

  final _fingers = <int, Offset>{};
  _Gesture? _g;
  PlanRect? _live;
  bool _pulled = false;

  Offset _toPlan(Offset p) => (p - _offset) / _scale;

  /// The square in the middle of what is in view (a new block goes there).
  (int, int) centreSquare() {
    final c = _toPlan(_size.center(Offset.zero)) / kPlanCell;
    return (c.dx.round(), c.dy.round());
  }

  /// Zooms to show every block (or the room's floor).
  void fit() => setState(() => _fit(_size));

  /// How far the view is zoomed (screen px per plan px).
  double get scale => _scale;

  /// Zooms to fill the view with [rects] (a room, to work on its small furniture).
  void zoomTo(List<PlanRect> rects) => setState(() => _fit(_size, rects: rects, most: _maxScale));

  void _fit(Size size, {List<PlanRect>? rects, double most = 2.0}) {
    if (size.isEmpty) return;
    rects ??= [...widget.plans.values, ?widget.within, ...widget.extent];
    if (rects.isEmpty) {
      _scale = 1;
      _offset = const Offset(kPlanCell, kPlanCell);
      return;
    }
    final x0 = rects.map((r) => r.x).reduce(math.min), y0 = rects.map((r) => r.y).reduce(math.min);
    final x1 = rects.map((r) => r.right).reduce(math.max), y1 = rects.map((r) => r.bottom).reduce(math.max);
    final w = (x1 - x0) * kPlanCell, h = (y1 - y0) * kPlanCell;
    // Room around it for the grab zones (48 px) at the edges.
    _scale = math.min((size.width - 112) / w, (size.height - 112) / h).clamp(_minScale, most);
    _offset = Offset((size.width - w * _scale) / 2 - x0 * kPlanCell * _scale, (size.height - h * _scale) / 2 - y0 * kPlanCell * _scale);
  }

  /// The block under [p] (on the plan): the picked one first, then the top one.
  String? _blockAt(Offset p) {
    bool inside(PlanRect r) => p.dx >= r.x * kPlanCell && p.dx <= r.right * kPlanCell && p.dy >= r.y * kPlanCell && p.dy <= r.bottom * kPlanCell;
    final sel = widget.selected;
    final picked = sel == null ? null : widget.plans[sel];
    if (picked != null && inside(picked)) return sel;
    for (final e in widget.plans.entries.toList().reversed) {
      if (inside(e.value)) return e.key;
    }
    return null;
  }

  void _pinchStart() {
    final ps = _fingers.values.take(2).toList();
    _live = null;
    _g = _Gesture(_Kind.pinch, ps[0])
      ..view = _offset
      ..scale = _scale
      ..span = math.max(1, (ps[0] - ps[1]).distance)
      ..focal = (ps[0] + ps[1]) / 2;
  }

  void _down(PointerDownEvent e) {
    _fingers[e.pointer] = e.localPosition;
    if (_fingers.length == 2) return setState(_pinchStart);
    if (_fingers.length > 2) return;
    final p = e.localPosition, at = _toPlan(p);
    final sel = widget.selected == null ? null : widget.plans[widget.selected!];
    if (sel != null) {
      final grab = planGrab(sel, at.dx, at.dy, cell: kPlanCell, scale: _scale);
      if (grab?.handle case final h?) {
        HapticFeedback.selectionClick();
        _g = _Gesture(_Kind.stretch, p, id: widget.selected, from: sel, handle: h);
        return setState(() => _live = sel);
      }
    }
    final hit = _blockAt(at);
    _g = hit == null ? (_Gesture(_Kind.pan, p, id: null)..view = _offset) : _Gesture(_Kind.move, p, id: hit, from: widget.plans[hit]);
  }

  void _move(PointerMoveEvent e) {
    if (!_fingers.containsKey(e.pointer)) return;
    _fingers[e.pointer] = e.localPosition;
    final g = _g;
    if (g == null) return;
    if (g.kind == _Kind.pinch) {
      if (_fingers.length < 2) return;
      final ps = _fingers.values.take(2).toList();
      final scale = (g.scale * (ps[0] - ps[1]).distance / g.span).clamp(_minScale, _maxScale);
      final onPlan = (g.focal - g.view) / g.scale;
      return setState(() {
        _scale = scale;
        _offset = (ps[0] + ps[1]) / 2 - onPlan * scale;
      });
    }
    final d = e.localPosition - g.start;
    if (g.kind == _Kind.pan) {
      if (!g.moved && d.distance < 8) return;
      g.moved = true;
      return setState(() => _offset = g.view + d);
    }
    if (g.kind == _Kind.move && !g.moved) {
      if (d.distance < 6) return;
      g.moved = true;
      HapticFeedback.selectionClick();
      if (widget.selected != g.id) widget.onSelect(g.id);
    }
    final dx = (d.dx / _scale / kPlanCell).round(), dy = (d.dy / _scale / kPlanCell).round();
    final from = g.from!;
    final want = g.kind == _Kind.move
        ? shiftPlan(from, dx, dy, within: widget.within)
        : stretchPlan(from, g.handle!, dx, dy, min: widget.min, within: widget.within);
    final others = [for (final e in widget.plans.entries) if (e.key != g.id) e.value];
    var (r, pulled) = magnetPlan(want, from, g.handle, others);
    final w = widget.within;
    if (w != null && (r.x < w.x || r.y < w.y || r.right > w.right || r.bottom > w.bottom)) (r, pulled) = (want, false);
    if (pulled && !_pulled) HapticFeedback.lightImpact();
    setState(() {
      _live = r;
      _pulled = pulled;
    });
  }

  void _up(PointerEvent e, {bool cancelled = false}) {
    _fingers.remove(e.pointer);
    final g = _g;
    if (g == null) return;
    if (g.kind == _Kind.pinch) {
      if (_fingers.isEmpty) _g = null;
      return;
    }
    _g = null;
    final live = _live;
    setState(() {
      _live = null;
      _pulled = false;
    });
    if (cancelled) return;
    if (g.kind == _Kind.pan && !g.moved) return widget.onSelect(_blockAt(_toPlan(e.localPosition)));
    if (g.kind == _Kind.move && !g.moved) return widget.onSelect(g.id);
    if (live != null && live != g.from) widget.onChange(g.id!, live);
  }

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        _size = box.biggest;
        if (!_fitted) {
          _fitted = true;
          _fit(_size);
        }
        final overlaps = overlappingPlans(widget.plans);
        final dragged = _g?.id;
        final sel = widget.selected;
        final selRect = sel == null ? null : (dragged == sel ? _live : null) ?? widget.plans[sel];
        Widget block(String id, PlanRect saved) {
          final r = id == dragged && _live != null ? _live! : saved;
          final lap = overlaps.contains(id) || (id == dragged && _live != null && widget.plans.entries.any((e) => e.key != id && e.value.overlaps(r)));
          return Positioned(
            left: r.x * kPlanCell,
            top: r.y * kPlanCell,
            width: r.w * kPlanCell,
            height: r.h * kPlanCell,
            child: SizedBox.expand(
              key: ValueKey('${widget.keyPrefix}-$id'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: id == dragged && _live != null ? const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 5))] : const [],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.block(id, r, id == sel),
                    if (lap) CustomPaint(painter: _OverlapPainter(c.danger)),
                    if (id == dragged && _pulled) DecoratedBox(decoration: BoxDecoration(border: Border.all(color: c.secondary, width: 3))),
                  ],
                ),
              ),
            ),
          );
        }

        final ids = [...widget.plans.keys.where((id) => id != sel), ?(widget.plans.containsKey(sel) ? sel : null)];
        return Listener(
          key: ValueKey('${widget.keyPrefix}-canvas'),
          behavior: HitTestBehavior.opaque,
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: (e) => _up(e, cancelled: true),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _SquaresPainter(_offset, _scale * kPlanCell, c.border, c.muted))),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
                      ..scaleByDouble(_scale, _scale, 1, 1),
                    child: SizedBox(
                      width: 1,
                      height: 1,
                      child: Stack(clipBehavior: Clip.none, children: [...widget.under, for (final id in ids) block(id, widget.plans[id]!)]),
                    ),
                  ),
                ),
                if (selRect != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PickPainter(
                          Rect.fromLTWH(
                            _offset.dx + selRect.x * kPlanCell * _scale,
                            _offset.dy + selRect.y * kPlanCell * _scale,
                            selRect.w * kPlanCell * _scale,
                            selRect.h * kPlanCell * _scale,
                          ),
                          primary: c.primary,
                          card: c.card,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The squares, endless: drawn across the view wherever the plan is.
class _SquaresPainter extends CustomPainter {
  _SquaresPainter(this.offset, this.cell, this.line, this.fill);

  final Offset offset;
  final double cell;
  final Color line, fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    final p = Paint()
      ..color = line
      ..strokeWidth = 0.7;
    if (cell < 4) return;
    for (var x = offset.dx % cell; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = offset.dy % cell; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_SquaresPainter old) => old.offset != offset || old.cell != cell || old.line != line;
}

/// Overlapping blocks: hatched in red, in the house's crayon style.
class _OverlapPainter extends CustomPainter {
  _OverlapPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Path()..addRect(Offset.zero & size);
    Doodle.hatch(canvas, box, color.withValues(alpha: 0.45), gap: 7, width: 1.6);
    canvas.drawRect(
      (Offset.zero & size).deflate(1),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(_OverlapPainter old) => old.color != color;
}

/// The picked block's grab zone (a dashed ring 48 px out) and its knobs:
/// big ones at the corners (both ways), smaller at the sides.
class _PickPainter extends CustomPainter {
  _PickPainter(this.r, {required this.primary, required this.card});

  final Rect r;
  final Color primary, card;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = RRect.fromRectAndRadius(r.inflate(48), const Radius.circular(24));
    final dash = Paint()
      ..color = primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(ring)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 14) {
        canvas.drawPath(metric.extractPath(d, d + 8), dash);
      }
    }
    canvas.drawRect(
      r,
      Paint()
        ..color = primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final shadow = Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    // Knobs sit outside the walls (user report: on small furniture they
    // covered the whole piece, its name and the middle to move it by).
    for (final corner in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      final out = Offset(corner.dx == r.left ? -1 : 1, corner.dy == r.top ? -1 : 1);
      final p = corner + out * 13;
      canvas.drawCircle(p + const Offset(0, 1.5), 14, shadow);
      canvas.drawCircle(p, 14, Paint()..color = primary);
      canvas.drawCircle(
        p,
        14,
        Paint()
          ..color = card
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      // Two little arrows pointing out of the corner: it stretches both ways.
      final arrow = Paint()
        ..color = card
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final tip = p + out * 5, tail = p - out * 5;
      canvas.drawLine(tail, tip, arrow);
      canvas.drawLine(tip, tip - Offset(out.dx * 4.5, 0), arrow);
      canvas.drawLine(tip, tip - Offset(0, out.dy * 4.5), arrow);
    }
    for (final (p, flat) in [
      (r.topCenter - const Offset(0, 11), true),
      (r.bottomCenter + const Offset(0, 11), true),
      (r.centerLeft - const Offset(11, 0), false),
      (r.centerRight + const Offset(11, 0), false),
    ]) {
      final pill = RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: flat ? 28 : 10, height: flat ? 10 : 28), const Radius.circular(5));
      canvas.drawRRect(pill, Paint()..color = card);
      canvas.drawRRect(
        pill,
        Paint()
          ..color = primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_PickPainter old) => old.r != r || old.primary != primary;
}

/// "가로 − 3.0 m +" and "세로 − 2.5 m +": exact sizes, half a metre a tap.
class PlanSizeSteppers extends StatelessWidget {
  const PlanSizeSteppers({super.key, required this.rect, required this.onChange, this.min = 2, this.within});

  final PlanRect rect;
  final ValueChanged<PlanRect> onChange;
  final int min;
  final PlanRect? within;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    Widget row(String label, String key, int value, PlanRect Function(int) by) {
      final more = by(value + 1), less = by(value - 1);
      final canMore = within == null || (more.right <= within!.right && more.bottom <= within!.bottom);
      return Padding(
        padding: const EdgeInsets.only(top: AppSpace.xs),
        child: Row(
          children: [
            SizedBox(width: 44, child: Text(label, style: AppType.caption.copyWith(color: c.mutedFg))),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    IconButton(
                      key: ValueKey('plan-$key-less'),
                      tooltip: l.planLess,
                      onPressed: value > min ? () => onChange(less) : null,
                      icon: Icon(Icons.remove_rounded, color: c.primaryInk),
                    ),
                    Expanded(child: Center(child: Text(planMeters(value), style: AppType.label))),
                    IconButton(
                      key: ValueKey('plan-$key-more'),
                      tooltip: l.planMore,
                      onPressed: canMore ? () => onChange(more) : null,
                      icon: Icon(Icons.add_rounded, color: c.primaryInk),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(l.planWidth, 'w', rect.w, (v) => PlanRect(rect.x, rect.y, v, rect.h)),
        row(l.planHeight, 'h', rect.h, (v) => PlanRect(rect.x, rect.y, rect.w, v)),
      ],
    );
  }
}

/// "3.5 m" for 7 squares.
String planMeters(int squares) => '${(squares / 2).toStringAsFixed(squares.isEven ? 0 : 1)} m';

/// The line under the title: what a finger does, for the picked block or none.
class PlanHint extends StatelessWidget {
  const PlanHint({super.key, required this.picked});

  final bool picked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
      child: FitText(picked ? l.planHintPicked : l.planHintNone, style: AppType.caption.copyWith(color: c.mutedFg)),
    );
  }
}
