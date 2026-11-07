// What the house and room editors share: a canvas that zooms and pans with
// two fingers, and blocks that work the same everywhere (user request):
// tap to pick a block (its eight handles appear: four sides, four corners,
// drag one to resize), long-press to lift it and drag to move it.
// Everything snaps to the 0.5 m squares.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../design/theme.dart';

/// The squares, zoomable: pinch to zoom in on a corner, drag the empty floor
/// to look around. A tap on empty floor calls [onTapEmpty].
class PlanCanvas extends StatefulWidget {
  const PlanCanvas({super.key, required this.size, required this.children, this.onTapEmpty});

  final Size size;
  final List<Widget> children;
  final VoidCallback? onTapEmpty;

  @override
  State<PlanCanvas> createState() => _PlanCanvasState();
}

class _PlanCanvasState extends State<PlanCanvas> {
  final _view = TransformationController();

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        key: const ValueKey('plan-canvas'),
        transformationController: _view,
        constrained: false,
        minScale: 0.6,
        maxScale: 4,
        boundaryMargin: const EdgeInsets.all(120),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTapEmpty,
          child: SizedBox.fromSize(
            size: widget.size,
            child: Stack(clipBehavior: Clip.none, children: widget.children),
          ),
        ),
      ),
    );
  }
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
      // A big invisible target around a small visible dot or bar.
      const target = 36.0;
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
              width: corner ? 18 : (at.x == 0 ? 26 : 10),
              height: corner ? 18 : (at.y == 0 ? 26 : 10),
              decoration: BoxDecoration(
                color: corner ? c.primary : c.card,
                borderRadius: BorderRadius.circular(corner ? 9 : 5),
                border: Border.all(color: corner ? c.onPrimary : c.primary, width: 2.5),
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
