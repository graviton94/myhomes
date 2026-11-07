// What the house and room editors share (user request): a canvas that only
// two fingers move and zoom, and blocks that work the same everywhere: tap to
// pick a block (its eight handles appear: four sides, four corners, drag one
// to resize), long-press to lift it and drag to move it, double-tap empty
// floor to add one there. Everything snaps to the 0.5 m squares.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../design/theme.dart';

/// The squares, zoomable. One finger never moves the view (so a resize or a
/// tap never drags the floor away); two fingers move it and pinch to zoom.
/// A tap on empty floor calls [onTapEmpty]; a second tap on the same square
/// soon after calls [onDoubleTapEmpty] with the point on the squares.
class PlanCanvas extends StatefulWidget {
  const PlanCanvas({super.key, required this.size, required this.children, this.onTapEmpty, this.onDoubleTapEmpty});

  final Size size;
  final List<Widget> children;
  final VoidCallback? onTapEmpty;
  final ValueChanged<Offset>? onDoubleTapEmpty;

  @override
  State<PlanCanvas> createState() => _PlanCanvasState();
}

class _PlanCanvasState extends State<PlanCanvas> {
  static const _minScale = 0.6, _maxScale = 4.0;

  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _view = Size.zero;

  // Fingers on the canvas, and the two-finger gesture's start.
  final _fingers = <int, Offset>{};
  double? _startScale, _startSpan;
  Offset? _startOffset, _startFocal;

  // The last tap on empty floor, for the double tap.
  Offset? _lastTap;
  DateTime? _lastTapAt;

  (Offset, double) _focalAndSpan() {
    final ps = _fingers.values.take(2).toList();
    return ((ps[0] + ps[1]) / 2, (ps[0] - ps[1]).distance);
  }

  void _beginTwo() {
    final (focal, span) = _focalAndSpan();
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = focal;
    _startSpan = span < 1 ? 1 : span;
  }

  /// Keeps some of the squares in view.
  Offset _clamp(Offset o, double scale) {
    const margin = 120.0;
    final w = widget.size.width * scale, h = widget.size.height * scale;
    double fit(double v, double content, double view) {
      final lo = math.min(view - content - margin, 0.0), hi = margin;
      return v.clamp(lo, hi);
    }

    return Offset(fit(o.dx, w, _view.width), fit(o.dy, h, _view.height));
  }

  void _down(PointerDownEvent e) {
    _fingers[e.pointer] = e.localPosition;
    if (_fingers.length == 2) _beginTwo();
  }

  void _move(PointerMoveEvent e) {
    if (!_fingers.containsKey(e.pointer)) return;
    _fingers[e.pointer] = e.localPosition;
    if (_fingers.length < 2 || _startScale == null) return;
    final (focal, span) = _focalAndSpan();
    final scale = (_startScale! * span / _startSpan!).clamp(_minScale, _maxScale);
    // The point under the fingers stays under them.
    final onSquares = (_startFocal! - _startOffset!) / _startScale!;
    setState(() {
      _scale = scale;
      _offset = _clamp(focal - onSquares * scale, scale);
    });
  }

  void _up(PointerEvent e) {
    _fingers.remove(e.pointer);
    if (_fingers.length >= 2) {
      _beginTwo();
    } else {
      _startScale = null;
    }
  }

  void _tapUp(TapUpDetails t) {
    final now = DateTime.now();
    final p = t.localPosition;
    final again = _lastTapAt != null && now.difference(_lastTapAt!) < const Duration(milliseconds: 400) && (p - _lastTap!).distance < 24 / _scale;
    if (again && widget.onDoubleTapEmpty != null) {
      _lastTapAt = null;
      widget.onDoubleTapEmpty!(p);
      return;
    }
    _lastTap = p;
    _lastTapAt = now;
    widget.onTapEmpty?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) {
          _view = box.biggest;
          return Listener(
            key: const ValueKey('plan-canvas'),
            behavior: HitTestBehavior.opaque,
            onPointerDown: _down,
            onPointerMove: _move,
            onPointerUp: _up,
            onPointerCancel: _up,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: widget.size.width,
                  height: widget.size.height,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
                      ..scaleByDouble(_scale, _scale, 1, 1),
                    child: PlanScale(
                      scale: _scale,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: _tapUp,
                        child: SizedBox.fromSize(
                          size: widget.size,
                          child: Stack(clipBehavior: Clip.none, children: widget.children),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// How far the canvas is zoomed, so handles keep their size on the screen.
class PlanScale extends InheritedWidget {
  const PlanScale({super.key, required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<PlanScale>()?.scale ?? 1;

  @override
  bool updateShouldNotify(PlanScale old) => old.scale != scale;
}

/// One block on the squares. [rect] is where it is saved; while a finger is
/// on it the block shows where it would land, and [onCommit] gets that
/// place when the finger lifts.
class PlanBlock extends StatefulWidget {
  const PlanBlock({
    super.key,
    required this.id,
    required this.rect,
    required this.cell,
    required this.selected,
    required this.onSelect,
    required this.onCommit,
    required this.child,
    this.min = 2,
    this.cols,
    this.rows,
  });

  /// Names the block and its handles for tests (`house-room-ID`).
  final String id;
  final PlanRect rect;
  final double cell;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<PlanRect> onCommit;

  /// The block's drawing (fill, edge, name), sized to the block.
  final Widget Function(PlanRect live, bool lifted) child;

  /// Smallest size in squares.
  final int min;

  /// The area it must stay in (a room for furniture); null = open-ended.
  final int? cols, rows;

  @override
  State<PlanBlock> createState() => _PlanBlockState();
}

class _PlanBlockState extends State<PlanBlock> {
  PlanRect? _live;
  bool _lifted = false;
  Offset _drag = Offset.zero;

  (int, int) _squares(Offset o) => ((o.dx / widget.cell).round(), (o.dy / widget.cell).round());

  void _begin({required bool lift}) {
    HapticFeedback.selectionClick();
    if (!widget.selected) widget.onSelect();
    setState(() {
      _live = widget.rect;
      _lifted = lift;
      _drag = Offset.zero;
    });
  }

  void _commit() {
    final r = _live;
    setState(() {
      _live = null;
      _lifted = false;
    });
    if (r != null && r != widget.rect) widget.onCommit(r);
  }

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final r = _live ?? widget.rect;
    final cell = widget.cell;
    Widget handle(PlanHandle h, Alignment at) {
      final corner = at.x != 0 && at.y != 0;
      // A big invisible target around a small visible dot or bar, both the
      // same size on the screen at any zoom.
      final zoom = PlanScale.of(context);
      final target = 48.0 / zoom;
      return Positioned(
        left: (at.x + 1) / 2 * r.w * cell - target / 2,
        top: (at.y + 1) / 2 * r.h * cell - target / 2,
        width: target,
        height: target,
        // A handle takes the finger the moment it touches, so the stretch
        // starts at once (not after the usual drag slop) and the canvas
        // does not pan instead.
        child: RawGestureDetector(
          key: ValueKey('${widget.id}-${h.name}'),
          behavior: HitTestBehavior.opaque,
          gestures: {
            _GrabPan: GestureRecognizerFactoryWithHandlers<_GrabPan>(
              () => _GrabPan(),
              (g) => g
                ..dragStartBehavior = DragStartBehavior.down
                ..onStart = ((_) => _begin(lift: false))
                ..onUpdate = (e) {
                  _drag += e.delta;
                  final (dx, dy) = _squares(_drag);
                  setState(() => _live = resizePlan(widget.rect, h, dx, dy, min: widget.min, cols: widget.cols, rows: widget.rows));
                }
                ..onEnd = ((_) => _commit())
                ..onCancel = _commit,
            ),
          },
          child: Center(
            child: Container(
              width: (corner ? 20 : (at.x == 0 ? 28 : 11)) / zoom,
              height: (corner ? 20 : (at.y == 0 ? 28 : 11)) / zoom,
              decoration: BoxDecoration(
                color: corner ? c.primary : c.card,
                borderRadius: BorderRadius.circular((corner ? 10 : 5.5) / zoom),
                border: Border.all(color: corner ? c.onPrimary : c.primary, width: 2.5 / zoom),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: r.x * cell,
      top: r.y * cell,
      width: r.w * cell,
      height: r.h * cell,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: ValueKey(widget.id),
              onTap: widget.onSelect,
              onLongPressStart: (_) => _begin(lift: true),
              onLongPressMoveUpdate: (e) {
                _drag = e.localOffsetFromOrigin;
                final (dx, dy) = _squares(_drag);
                setState(() => _live = movePlan(widget.rect, dx, dy, cols: widget.cols, rows: widget.rows));
              },
              onLongPressEnd: (_) => _commit(),
              onLongPressCancel: () {
                if (_lifted) _commit();
              },
              child: AnimatedScale(
                scale: _lifted ? 1.04 : 1,
                duration: const Duration(milliseconds: 120),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: _lifted ? const [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 6))] : const [],
                  ),
                  child: widget.child(r, _lifted),
                ),
              ),
            ),
          ),
          if (widget.selected && !_lifted) ...[
            for (final (h, at) in const [
              (PlanHandle.top, Alignment.topCenter),
              (PlanHandle.bottom, Alignment.bottomCenter),
              (PlanHandle.left, Alignment.centerLeft),
              (PlanHandle.right, Alignment.centerRight),
              (PlanHandle.topLeft, Alignment.topLeft),
              (PlanHandle.topRight, Alignment.topRight),
              (PlanHandle.bottomLeft, Alignment.bottomLeft),
              (PlanHandle.bottomRight, Alignment.bottomRight),
            ])
              handle(h, at),
          ],
        ],
      ),
    );
  }
}

/// A pan that wins as soon as the finger lands on it.
class _GrabPan extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
