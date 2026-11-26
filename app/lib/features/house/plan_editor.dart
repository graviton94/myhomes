// What the house and room editors share: the map is edited as a draft —
// nothing is kept until 저장, 취소 puts it back, ↶ ↷ step through it. How a
// finger works on it follows house-building games and floor-plan apps (user
// request, docs/mockups/map-editor-v3.html): see PlanEditor. Rules: core
// plan_draft.dart.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

  /// Puts several blocks at once (a wall pushed with the rooms next door), as one step.
  void setAll(Map<String, T> rs) {
    _undo.add(Map.of(_plans));
    _redo.clear();
    _plans = {..._plans, ...rs};
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

/// The squares with their blocks, edited by touch (user request, after a
/// look at how house-building games and floor-plan apps do it,
/// docs/mockups/map-editor-v3.html): only the picked block moves when
/// dragged; dragging anything else moves the map, holding it 0.3 s lifts it.
/// The picked block is stretched from knobs outside its walls (hidden on a
/// block too small to show them; picking it zooms in instead). Tapping the
/// same spot again picks what lies under it. Blocks stay on the land; held
/// against its edge, the land grows a square at a time ([grow]).
class PlanEditor extends StatefulWidget {
  const PlanEditor({
    super.key,
    required this.plans,
    required this.selected,
    required this.onSelect,
    required this.onChange,
    required this.block,
    this.onChangeMany,
    this.keyPrefix = 'plan',
    this.min = 2,
    this.within,
    this.under = const [],
    this.extent = const [],
    this.grow = false,
    this.shareWalls = false,
    this.where,
    this.onTapFloor,
  });

  final Map<String, PlanRect> plans;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final void Function(String id, PlanRect r) onChange;

  /// A wall pushed together with the rooms next door: all of them, one step.
  final ValueChanged<Map<String, PlanRect>>? onChangeMany;

  /// A block's drawing, sized to it; [picked] while it is the selected one.
  final Widget Function(String id, PlanRect r, bool picked) block;

  /// Names blocks for tests: `$keyPrefix-$id`.
  final String keyPrefix;
  final int min;

  /// A room's floor: furniture stays on it (it is the land then).
  final PlanRect? within;

  /// Drawn under the blocks, placed in plan pixels (a photo, the floor).
  final List<Widget> under;

  /// More to keep in view and on the land (the rooms under furniture).
  final List<PlanRect> extent;

  /// The land grows when a block is held against its edge (the house's rooms).
  final bool grow;

  /// A side knob whose wall a neighbour shares moves the neighbour's wall too.
  final bool shareWalls;

  /// Said after the size while a block is dragged (the room under a piece).
  final String? Function(PlanRect r)? where;

  /// Empty floor tapped, at this square (the furniture tab picks the room to add to).
  final void Function(int x, int y)? onTapFloor;

  @override
  State<PlanEditor> createState() => PlanEditorState();
}

enum _Kind { pan, hold, move, stretch, pinch }

class _Gesture {
  _Gesture(this.kind, this.start, {this.id, this.from, this.handle, this.at = Duration.zero});

  _Kind kind;
  final Offset start;
  String? id;
  PlanRect? from;
  final PlanHandle? handle;
  final Duration at;
  bool moved = false;
  Offset grab = Offset.zero;
  Map<String, PlanRect> sides = const {};
  late Offset view;
  late double scale, span;
  late Offset focal;
}

/// A knob outside the picked block, on the screen.
class _Knob {
  const _Knob(this.handle, this.at, {this.shared = false});

  final PlanHandle handle;
  final Offset at;
  final bool shared;

  bool get corner => handle.index >= PlanHandle.topLeft.index;
  bool get flat => handle == PlanHandle.top || handle == PlanHandle.bottom;

  bool hits(Offset p) {
    if (corner) return (p - at).distance < 24;
    final d = p - at;
    return flat ? d.dx.abs() < 30 && d.dy.abs() < 20 : d.dx.abs() < 20 && d.dy.abs() < 30;
  }
}

class PlanEditorState extends State<PlanEditor> with SingleTickerProviderStateMixin {
  static const _minScale = 0.3, _maxScale = 4.0;

  /// Hold this long on a block to lift it; at the land's edge, to add a square.
  static const holdLift = Duration(milliseconds: 300);
  static const holdEdge = Duration(milliseconds: 600), stepEdge = Duration(milliseconds: 500);

  /// Knobs show on a block at least this big on the screen; picking a smaller
  /// one shows its room up close (at most [_closeMost]).
  static const _knobsFrom = 32.0, _closeMost = 2.5, _edgeZone = 34.0;

  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _size = Size.zero;
  bool _fitted = false;
  PlanRect? _land;

  final _fingers = <int, Offset>{};
  _Gesture? _g;
  Map<String, PlanRect> _live = const {};
  bool _pulled = false;
  Offset? _last;

  late final Ticker _ticker = createTicker(_tick);
  Duration _now = Duration.zero;

  /// Growing the land: which way, when the next square comes, how many so far.
  (int, int)? _edge, _padHold;
  Duration _edgeNext = Duration.zero;
  int _edgeSteps = 0;
  double _edgeProgress = 0;

  PlanRect get land => _land ??= _landFor();

  PlanRect _landFor() => widget.within ?? planLand([...widget.plans.values, ...widget.extent], margin: widget.grow ? 2 : 1);

  Offset _toPlan(Offset p) => (p - _offset) / _scale;

  Rect _screen(PlanRect r) =>
      Rect.fromLTWH(_offset.dx + r.x * kPlanCell * _scale, _offset.dy + r.y * kPlanCell * _scale, r.w * kPlanCell * _scale, r.h * kPlanCell * _scale);

  @override
  void didUpdateWidget(PlanEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New rooms, undo, a stepper: the land always holds every block.
    final all = [...widget.plans.values, ...widget.extent];
    if (widget.within != null) {
      _land = widget.within;
    } else if (all.isNotEmpty && _land != null) {
      _land = landUnion(_land!, planLand(all, margin: 0));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  /// The square in the middle of what is in view (a new block goes there).
  (int, int) centreSquare() {
    final c = _toPlan(_size.center(Offset.zero)) / kPlanCell;
    return (c.dx.round(), c.dy.round());
  }

  /// The square under a point on the screen (a chip dropped on the map).
  (int, int)? squareAt(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    if (!(Offset.zero & box.size).contains(local)) return null;
    final c = _toPlan(local) / kPlanCell;
    return (c.dx.floor(), c.dy.floor());
  }

  /// Zooms to show every block (or the room's floor).
  void fit() => setState(() => _fit(_size));

  /// How far the view is zoomed (screen px per plan px).
  double get scale => _scale;

  /// Zooms to fill the view with [rects] (a room, to work on its small furniture).
  void zoomTo(List<PlanRect> rects) => setState(() => _fit(_size, rects: rects, most: _maxScale));

  /// The picked block brought close when it is small on the screen: its room
  /// fills the view, so the room stays in sight (user report: zooming to the
  /// piece alone went so far its room was lost).
  void focusPicked() {
    final r = widget.selected == null ? null : widget.plans[widget.selected!];
    if (r == null || _size.isEmpty) return;
    final short = math.min(r.w, r.h) * kPlanCell * _scale;
    if (short >= _knobsFrom) return _reveal(r);
    final cx = r.x + r.w / 2, cy = r.y + r.h / 2;
    final room = [?widget.within, ...widget.extent].where((e) => cx >= e.x && cx <= e.right && cy >= e.y && cy <= e.bottom).firstOrNull;
    final before = _scale;
    setState(() {
      _fit(_size, rects: [room ?? r], most: _closeMost);
      if (_scale < before) _fit(_size, rects: [r], most: before);
    });
    _reveal(r);
  }

  void _fit(Size size, {List<PlanRect>? rects, double most = 2.0}) {
    if (size.isEmpty) return;
    rects ??= [...widget.plans.values, ?widget.within, ...widget.extent];
    if (rects.isEmpty) rects = [land];
    final x0 = rects.map((r) => r.x).reduce(math.min), y0 = rects.map((r) => r.y).reduce(math.min);
    final x1 = rects.map((r) => r.right).reduce(math.max), y1 = rects.map((r) => r.bottom).reduce(math.max);
    final w = (x1 - x0) * kPlanCell, h = (y1 - y0) * kPlanCell;
    // Room around it for the knobs outside the walls.
    _scale = math.min((size.width - 72) / w, (size.height - 72) / h).clamp(_minScale, most);
    _offset = Offset((size.width - w * _scale) / 2 - x0 * kPlanCell * _scale, (size.height - h * _scale) / 2 - y0 * kPlanCell * _scale);
  }

  /// Keeps the middle of the view over the land.
  void _clampView() {
    if (_size.isEmpty) return;
    final c = _toPlan(_size.center(Offset.zero)) / kPlanCell, l = land;
    final x = c.dx.clamp(l.x.toDouble(), l.right.toDouble()), y = c.dy.clamp(l.y.toDouble(), l.bottom.toDouble());
    _offset += Offset(c.dx - x, c.dy - y) * kPlanCell * _scale;
  }

  /// Pans just enough to bring [r] into view.
  void _reveal(PlanRect r) {
    final s = _screen(r);
    var d = Offset.zero;
    if (s.left < 8) d += Offset(8 - s.left, 0);
    if (s.right > _size.width - 8) d -= Offset(s.right - (_size.width - 8), 0);
    if (s.top < 8) d += Offset(0, 8 - s.top);
    if (s.bottom > _size.height - 8) d -= Offset(0, s.bottom - (_size.height - 8));
    if (d != Offset.zero) setState(() => _offset += d);
  }

  /// The blocks under [p] (on the plan), smallest first.
  List<String> _blocksAt(Offset p) {
    bool inside(PlanRect r) => p.dx >= r.x * kPlanCell && p.dx <= r.right * kPlanCell && p.dy >= r.y * kPlanCell && p.dy <= r.bottom * kPlanCell;
    final out = [
      for (final e in widget.plans.entries)
        if (inside(e.value)) e.key,
    ];
    out.sort((a, b) => (widget.plans[a]!.w * widget.plans[a]!.h).compareTo(widget.plans[b]!.w * widget.plans[b]!.h));
    return out;
  }

  List<_Knob> _knobs(String id, PlanRect r) {
    final s = _screen(r);
    if (math.min(s.width, s.height) < _knobsFrom) return const [];
    bool shared(PlanHandle h) => widget.shareWalls && widget.onChangeMany != null && wallNeighbours(widget.plans, id, h).isNotEmpty;
    const g = 13.0;
    return [
      _Knob(PlanHandle.topLeft, s.topLeft + const Offset(-g, -g)),
      _Knob(PlanHandle.topRight, s.topRight + const Offset(g, -g)),
      _Knob(PlanHandle.bottomLeft, s.bottomLeft + const Offset(-g, g)),
      _Knob(PlanHandle.bottomRight, s.bottomRight + const Offset(g, g)),
      _Knob(PlanHandle.top, s.topCenter + const Offset(0, -g), shared: shared(PlanHandle.top)),
      _Knob(PlanHandle.bottom, s.bottomCenter + const Offset(0, g), shared: shared(PlanHandle.bottom)),
      _Knob(PlanHandle.left, s.centerLeft + const Offset(-g, 0), shared: shared(PlanHandle.left)),
      _Knob(PlanHandle.right, s.centerRight + const Offset(g, 0), shared: shared(PlanHandle.right)),
    ];
  }

  void _pick(String? id) {
    widget.onSelect(id);
    if (id != null) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? focusPicked() : null);
  }

  void _run() {
    if (_ticker.isActive) return;
    _now = Duration.zero;
    _ticker.start();
  }

  void _pinchStart() {
    final ps = _fingers.values.take(2).toList();
    _live = const {};
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
    final p = e.localPosition;
    _last = p;
    _run();
    final selId = widget.selected;
    final sel = selId == null ? null : widget.plans[selId];
    if (selId != null && sel != null) {
      for (final k in _knobs(selId, sel)) {
        if (!k.hits(p)) continue;
        HapticFeedback.selectionClick();
        final g = _Gesture(_Kind.stretch, p, id: selId, from: sel, handle: k.handle)..grab = _toPlan(p);
        if (k.shared) g.sides = {for (final n in wallNeighbours(widget.plans, selId, k.handle)) n: widget.plans[n]!};
        _g = g;
        return setState(() => _live = {selId: sel});
      }
      if (_screen(sel).inflate(6).contains(p)) {
        _g = _Gesture(_Kind.move, p, id: selId, from: sel)..grab = _toPlan(p);
        return;
      }
    }
    final under = _blocksAt(_toPlan(p));
    _g = under.isEmpty ? (_Gesture(_Kind.pan, p)..view = _offset) : (_Gesture(_Kind.hold, p, id: under.first, at: _now)..view = _offset);
  }

  /// Held long enough without moving: the block is picked and lifted.
  void _lift(_Gesture g) {
    final r = widget.plans[g.id];
    if (r == null) return;
    HapticFeedback.mediumImpact();
    widget.onSelect(g.id);
    setState(() {
      g
        ..kind = _Kind.move
        ..from = r
        ..grab = _toPlan(_last ?? g.start)
        ..moved = true;
      _live = {g.id!: r};
    });
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
        _clampView();
      });
    }
    _last = e.localPosition;
    final d = e.localPosition - g.start;
    if (g.kind == _Kind.hold) {
      if (d.distance < 8) return;
      g.kind = _Kind.pan; // moved before the hold: the map moves
    }
    if (g.kind == _Kind.pan) {
      if (!g.moved && d.distance < 8) return;
      g.moved = true;
      return setState(() {
        _offset = g.view + d;
        _clampView();
      });
    }
    if (!g.moved) {
      if (d.distance < 6) return;
      g.moved = true;
      HapticFeedback.selectionClick();
    }
    _follow(e.localPosition);
  }

  /// The dragged block (and walls pushed with it) where the finger is now.
  void _follow(Offset p) {
    final g = _g;
    if (g == null || g.from == null) return;
    final d = (_toPlan(p) - g.grab) / kPlanCell;
    final dx = d.dx.round(), dy = d.dy.round();
    final from = g.from!, l = land;
    final want = g.kind == _Kind.move ? shiftPlan(from, dx, dy, within: l) : stretchPlan(from, g.handle!, dx, dy, min: widget.min, within: l);
    final others = [
      for (final e in widget.plans.entries)
        if (e.key != g.id && !g.sides.containsKey(e.key)) e.value,
    ];
    var (r, pulled) = magnetPlan(want, from, g.handle, others);
    if (!onLand(r, l)) (r, pulled) = (want, false);
    var live = {g.id!: r};
    if (g.sides.isNotEmpty) {
      final (to, ns) = pushWall(r, g.handle!, g.sides);
      live = {g.id!: to, ...ns};
    }
    if (live[g.id] != _live[g.id]) HapticFeedback.selectionClick();
    if (pulled && !_pulled) HapticFeedback.lightImpact();
    setState(() {
      _live = live;
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
      _live = const {};
      _pulled = false;
      _edge = null;
    });
    if (cancelled) return;
    switch (g.kind) {
      case _Kind.pan when !g.moved:
        final sq = _toPlan(e.localPosition) / kPlanCell;
        widget.onTapFloor?.call(sq.dx.floor(), sq.dy.floor());
        return _pick(null);
      case _Kind.hold:
        return _pick(g.id);
      case _Kind.move when !g.moved:
        // The same spot again: what lies under the picked one.
        final under = _blocksAt(_toPlan(e.localPosition));
        if (under.length > 1) _pick(under[(under.indexOf(g.id!) + 1) % under.length]);
        return;
      default:
    }
    final changed = {
      for (final en in live.entries)
        if (widget.plans[en.key] != en.value) en.key: en.value,
    };
    if (changed.isEmpty) return;
    if (changed.length > 1 && widget.onChangeMany != null) return widget.onChangeMany!(changed);
    widget.onChange(g.id!, changed[g.id] ?? live[g.id]!);
  }

  void _tick(Duration now) {
    _now = now;
    final g = _g;
    if (g != null && g.kind == _Kind.hold) {
      if (now - g.at >= holdLift) {
        _lift(g);
      } else {
        setState(() {}); // the ring fills
      }
    } else if (g != null && g.moved && (g.kind == _Kind.move || g.kind == _Kind.stretch)) {
      _edgeDrag(now, g);
    } else if (_padHold != null) {
      _edgePad(now);
    } else if (g == null) {
      _ticker.stop();
    }
  }

  /// Which way the finger at [p] presses against the edge of the view.
  (int, int)? _pressing(Offset p) {
    final dx = p.dx < _edgeZone ? -1 : (p.dx > _size.width - _edgeZone ? 1 : 0);
    final dy = p.dy < _edgeZone ? -1 : (p.dy > _size.height - _edgeZone ? 1 : 0);
    return dx == 0 && dy == 0 ? null : (dx, dy);
  }

  /// Dragging near the edge of the view: on the land the map just follows; a
  /// block pressed against the land's edge adds a square after a hold
  /// (user request: slowly, a square at a time, and only then a notice).
  void _edgeDrag(Duration now, _Gesture g) {
    final p = _last, dir = p == null ? null : _pressing(p);
    if (p == null || dir == null) {
      if (_edge != null) setState(() => _edge = null);
      return;
    }
    final r = _live[g.id] ?? g.from!, l = land;
    final bx = atLandEdge(r, l, dir.$1, 0) ? dir.$1 : 0, by = atLandEdge(r, l, 0, dir.$2) ? dir.$2 : 0;
    if (bx == 0 && by == 0) {
      // Follow, faster the nearer the finger is to the edge, until the land's edge shows.
      double speed(double v) => ((_edgeZone - v) / 3).clamp(3, 10);
      final s0 = _screen(l);
      var d = Offset.zero;
      if (dir.$1 < 0 && s0.left < 24) d += Offset(math.min(speed(p.dx), 24 - s0.left), 0);
      if (dir.$1 > 0 && s0.right > _size.width - 24) d -= Offset(math.min(speed(_size.width - p.dx), s0.right - (_size.width - 24)), 0);
      if (dir.$2 < 0 && s0.top < 24) d += Offset(0, math.min(speed(p.dy), 24 - s0.top));
      if (dir.$2 > 0 && s0.bottom > _size.height - 24) d -= Offset(0, math.min(speed(_size.height - p.dy), s0.bottom - (_size.height - 24)));
      if (_edge != null) _edge = null;
      if (d != Offset.zero) {
        _offset += d;
        _follow(p);
      } else {
        setState(() {});
      }
      return;
    }
    if (!widget.grow) {
      if (_edge != null) setState(() => _edge = null);
      return;
    }
    if (_holdEdge(now, (bx, by))) {
      _land = growLand(l, bx, by);
      _offset -= Offset(bx * kPlanCell * _scale, by * kPlanCell * _scale);
      _follow(p);
    }
  }

  /// The nudge pad held against the land's edge.
  void _edgePad(Duration now) {
    final dir = _padHold!, id = widget.selected, r = id == null ? null : widget.plans[id];
    if (r == null || !widget.grow || !atLandEdge(r, land, dir.$1, dir.$2)) {
      if (_edge != null) setState(() => _edge = null);
      return;
    }
    if (_holdEdge(now, dir)) {
      _land = growLand(land, dir.$1, dir.$2);
      final t = shiftPlan(r, dir.$1, dir.$2, within: land);
      widget.onChange(id!, t);
      WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _reveal(t) : null);
    }
  }

  /// Counts a hold at the land's edge towards [dir]: true when a square is due.
  bool _holdEdge(Duration now, (int, int) dir) {
    if (_edge != dir) {
      _edge = dir;
      _edgeSteps = 0;
      _edgeNext = now + holdEdge;
    }
    final span = _edgeSteps == 0 ? holdEdge : stepEdge;
    final due = now >= _edgeNext;
    setState(() {
      _edgeProgress = due ? 0 : 1 - (_edgeNext - now).inMicroseconds / span.inMicroseconds;
      if (due) {
        _edgeSteps++;
        _edgeNext = now + stepEdge;
      }
    });
    if (due) HapticFeedback.selectionClick();
    return due;
  }

  /// One square for the picked block, from the nudge pad. At the land's edge
  /// a tap ([grow]) adds a square of land first; a drag holds instead
  /// ([holdNudge]). False when it could not move.
  bool nudge(int dx, int dy, {bool grow = false}) {
    final id = widget.selected, r = id == null ? null : widget.plans[id];
    if (r == null) return false;
    var t = shiftPlan(r, dx, dy, within: land);
    if (t == r && widget.grow && grow && atLandEdge(r, land, dx, dy)) {
      _land = growLand(land, dx, dy);
      t = shiftPlan(r, dx, dy, within: land);
    }
    if (t == r) return false;
    HapticFeedback.selectionClick();
    widget.onChange(id!, t);
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _reveal(t) : null);
    return true;
  }

  /// The nudge pad pressed towards [dx], [dy] past the land's edge: a square
  /// of land after a hold, then one every half second, until [releaseNudge].
  void holdNudge(int dx, int dy) {
    _padHold = (dx, dy);
    _run();
  }

  void releaseNudge() {
    _padHold = null;
    if (_edge != null) setState(() => _edge = null);
  }

  /// A size from the steppers: kept on the land, which grows by the square
  /// it needs when it may. Null when it does not fit.
  PlanRect? admit(PlanRect r) {
    if (onLand(r, land)) return r;
    if (!widget.grow) return null;
    setState(() => _land = landUnion(land, r));
    WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _reveal(r) : null);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        _size = box.biggest;
        if (!_fitted) {
          _fitted = true;
          _fit(_size);
        }
        final overlaps = overlappingPlans(widget.plans);
        final g = _g;
        final dragging = g != null && g.moved && (g.kind == _Kind.move || g.kind == _Kind.stretch);
        final sel = widget.selected;
        final selRect = sel == null ? null : _live[sel] ?? widget.plans[sel];
        Widget block(String id, PlanRect saved) {
          final r = _live[id] ?? saved;
          final lifted = dragging && _live.containsKey(id);
          final lap = overlaps.contains(id) || (lifted && widget.plans.entries.any((e) => e.key != id && !_live.containsKey(e.key) && e.value.overlaps(r)));
          return Positioned(
            left: r.x * kPlanCell,
            top: r.y * kPlanCell,
            width: r.w * kPlanCell,
            height: r.h * kPlanCell,
            child: SizedBox.expand(
              key: ValueKey('${widget.keyPrefix}-$id'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: lifted && id == g.id ? const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 5))] : const [],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.block(id, r, id == sel),
                    if (lap) CustomPaint(painter: _OverlapPainter(c.danger)),
                    if (lifted && id == g.id && _pulled)
                      DecoratedBox(
                        decoration: BoxDecoration(border: Border.all(color: c.secondary, width: 3)),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        final ids = [...widget.plans.keys.where((id) => id != sel), ?(widget.plans.containsKey(sel) ? sel : null)];
        final tagRect = dragging && selRect != null && g.id == sel ? _screen(selRect) : null;
        final where = tagRect == null ? null : widget.where?.call(selRect!);
        final holdAt = g != null && g.kind == _Kind.hold ? g.start : null;
        final edge = _edge;
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
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SquaresPainter(_offset, _scale * kPlanCell, land, c.border, c.muted, c.mutedFg, edge != null ? c.primary : null),
                  ),
                ),
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
                if (selRect != null && sel != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _PickPainter(
                          _screen(selRect),
                          knobs: dragging && g.kind == _Kind.move ? const [] : _knobs(sel, selRect),
                          ghost: dragging && g.id == sel ? _screen(g.from!) : null,
                          guides: dragging && g.id == sel ? _guides(sel, selRect) : const [],
                          primary: c.primary,
                          shared: c.secondary,
                          card: c.card,
                        ),
                      ),
                    ),
                  ),
                if (tagRect != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: math.max(4, tagRect.top - 34),
                    child: IgnorePointer(child: Center(child: _Tag('${l.planSizeTag(selRect!.w, selRect.h, planMeters(selRect.w), planMeters(selRect.h))}${where == null ? '' : ' · $where'}'))),
                  ),
                if (holdAt != null)
                  Positioned(
                    left: holdAt.dx - 22,
                    top: holdAt.dy - 22,
                    width: 44,
                    height: 44,
                    child: IgnorePointer(
                      child: CustomPaint(painter: _RingPainter(((_now - g!.at).inMicroseconds / holdLift.inMicroseconds).clamp(0, 1), c.primary)),
                    ),
                  ),
                if (edge != null) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 8,
                    child: IgnorePointer(
                      child: Center(
                        child: _Tag(_edgeSteps == 0 ? l.planEdgeHold : l.planEdgeGrowing(_edgeSteps), progress: _edgeProgress, arrow: edge),
                      ),
                    ),
                  ),
                  Positioned(
                    left: edge.$1 > 0 ? null : 0,
                    right: edge.$1 < 0 ? null : 0,
                    top: edge.$2 > 0 ? null : 0,
                    bottom: edge.$2 < 0 ? null : 0,
                    width: edge.$1 != 0 ? 6 : null,
                    height: edge.$1 == 0 ? 6 : null,
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: c.primary.withValues(alpha: 0.25),
                        child: FractionallySizedBox(
                          alignment: Alignment.topLeft,
                          widthFactor: edge.$1 != 0 ? 1 : _edgeProgress,
                          heightFactor: edge.$1 != 0 ? _edgeProgress : 1,
                          child: ColoredBox(color: c.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Lines where the dragged block's walls meet a neighbour's line, on the screen.
  List<(Offset, Offset)> _guides(String id, PlanRect r) {
    final out = <(Offset, Offset)>[];
    final seen = <String>{};
    final others = [
      for (final e in widget.plans.entries)
        if (e.key != id && !_live.containsKey(e.key)) e.value,
      ...widget.extent,
    ];
    Offset at(num x, num y) => _offset + Offset(x * kPlanCell * _scale, y * kPlanCell * _scale);
    for (final o in others) {
      if (((o.x + o.w / 2) - (r.x + r.w / 2)).abs() > 10 || ((o.y + o.h / 2) - (r.y + r.h / 2)).abs() > 10) continue;
      for (final x in [r.x, r.right]) {
        if ((x == o.x || x == o.right) && seen.add('x$x')) out.add((at(x, math.min(r.y, o.y)), at(x, math.max(r.bottom, o.bottom))));
      }
      for (final y in [r.y, r.bottom]) {
        if ((y == o.y || y == o.bottom) && seen.add('y$y')) out.add((at(math.min(r.x, o.x), y), at(math.max(r.right, o.right), y)));
      }
    }
    return out;
  }
}

/// A small dark label over the map: the size while dragging, the land notice.
class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.progress, this.arrow});

  final String text;
  final double? progress;
  final (int, int)? arrow;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final a = arrow;
    final icon = a == null
        ? null
        : a.$1 < 0
        ? Icons.arrow_back_rounded
        : a.$1 > 0
        ? Icons.arrow_forward_rounded
        : a.$2 < 0
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(
        color: progress == null ? const Color(0xE62E241C) : c.card,
        borderRadius: BorderRadius.circular(12),
        border: progress == null ? null : Border.all(color: c.primary, width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x30000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: c.primaryInk), const SizedBox(width: 4)],
              Flexible(
                child: OneLine([text], style: AppType.caption.copyWith(fontSize: 12, color: progress == null ? Colors.white : c.primaryInk)),
              ),
            ],
          ),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(value: progress, minHeight: 3, color: c.primary, backgroundColor: c.primarySoft),
              ),
            ),
        ],
      ),
    );
  }
}

/// The land's squares; outside it, hatched (where nothing goes until the land grows).
class _SquaresPainter extends CustomPainter {
  _SquaresPainter(this.offset, this.cell, this.land, this.line, this.fill, this.outside, this.edge);

  final Offset offset;
  final double cell;
  final PlanRect land;
  final Color line, fill, outside;
  final Color? edge;

  @override
  void paint(Canvas canvas, Size size) {
    final all = Offset.zero & size;
    final on = Rect.fromLTWH(offset.dx + land.x * cell, offset.dy + land.y * cell, land.w * cell, land.h * cell);
    canvas.drawRect(all, Paint()..color = Color.alphaBlend(outside.withValues(alpha: 0.16), fill));
    Doodle.hatch(
      canvas,
      Path.combine(PathOperation.difference, Path()..addRect(all), Path()..addRect(on)),
      outside.withValues(alpha: 0.22),
      gap: 9,
      width: 1.2,
    );
    canvas.drawRect(on, Paint()..color = fill);
    final p = Paint()
      ..color = line
      ..strokeWidth = 0.7;
    if (cell >= 4) {
      final r = on.intersect(all);
      if (!r.isEmpty) {
        for (var x = on.left; x <= on.right + 0.5; x += cell) {
          if (x >= r.left - 0.5 && x <= r.right + 0.5) canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), p);
        }
        for (var y = on.top; y <= on.bottom + 0.5; y += cell) {
          if (y >= r.top - 0.5 && y <= r.bottom + 0.5) canvas.drawLine(Offset(r.left, y), Offset(r.right, y), p);
        }
      }
    }
    final rim = Paint()
      ..color = edge ?? outside.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = edge == null ? 1.5 : 2.5;
    for (final metric in (Path()..addRect(on)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 7), rim);
      }
    }
  }

  @override
  bool shouldRepaint(_SquaresPainter old) =>
      old.offset != offset || old.cell != cell || old.land != land || old.line != line || old.edge != edge || old.fill != fill;
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

/// Holding on a block: a ring fills until it lifts.
class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (Offset.zero & size).deflate(4);
    canvas.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

/// The picked block: its outline, where it was (dashed) while dragged, lines
/// where its walls meet a neighbour's, and the knobs outside its walls:
/// round at the corners (both ways), tabs at the sides (green when the wall
/// next door moves with it).
class _PickPainter extends CustomPainter {
  _PickPainter(this.r, {required this.knobs, required this.ghost, required this.guides, required this.primary, required this.shared, required this.card});

  final Rect r;
  final List<_Knob> knobs;
  final Rect? ghost;
  final List<(Offset, Offset)> guides;
  final Color primary, shared, card;

  void _dashed(Canvas canvas, Path path, Paint paint, {double on = 7, double off = 5}) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += on + off) {
        canvas.drawPath(metric.extractPath(d, d + on), paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (ghost case final g?) {
      _dashed(
        canvas,
        Path()..addRect(g),
        Paint()
          ..color = primary.withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final guide = Paint()
      ..color = shared
      ..strokeWidth = 1.5;
    for (final (a, b) in guides) {
      _dashed(
        canvas,
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy),
        guide,
        on: 5,
        off: 4,
      );
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
    for (final k in knobs) {
      final fill = k.shared ? shared : primary;
      if (k.corner) {
        canvas.drawCircle(k.at + const Offset(0, 1.5), 12, shadow);
        canvas.drawCircle(k.at, 12, Paint()..color = fill);
        canvas.drawCircle(
          k.at,
          12,
          Paint()
            ..color = card
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      } else {
        final pill = RRect.fromRectAndRadius(Rect.fromCenter(center: k.at, width: k.flat ? 30 : 12, height: k.flat ? 12 : 30), const Radius.circular(6));
        canvas.drawRRect(pill.shift(const Offset(0, 1.5)), shadow);
        canvas.drawRRect(pill, Paint()..color = fill);
        canvas.drawRRect(
          pill,
          Paint()
            ..color = card
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PickPainter old) => true;
}

/// Under the steppers: arrows a square at a time, and a round pad dragged to
/// nudge the picked block without a finger over it (user request, after
/// house-building games' move pads). Pressed past the land's edge it holds,
/// and the land grows a square at a time.
class PlanNudgePad extends StatefulWidget {
  const PlanNudgePad({super.key, required this.editor});

  final GlobalKey<PlanEditorState> editor;

  @override
  State<PlanNudgePad> createState() => _PlanNudgePadState();
}

class _PlanNudgePadState extends State<PlanNudgePad> {
  static const _step = 18.0;

  Offset? _start;
  int _cx = 0, _cy = 0;
  (int, int)? _blocked;
  int _blockedAt = 0;

  PlanEditorState? get _ed => widget.editor.currentState;

  void _drag(Offset p) {
    final s = _start;
    if (s == null) return;
    final cx = ((p.dx - s.dx) / _step).truncate(), cy = ((p.dy - s.dy) / _step).truncate();
    final b = _blocked;
    if (b != null) {
      // Still pressing that way: keep holding; drawn back: let go.
      final along = b.$1 != 0 ? b.$1 * (cx - _blockedAt) : b.$2 * (cy - _blockedAt);
      if (along < 0) {
        _blocked = null;
        _ed?.releaseNudge();
      }
    }
    while (cx != _cx || cy != _cy) {
      final dx = (cx - _cx).sign, dy = dx != 0 ? 0 : (cy - _cy).sign;
      _cx += dx;
      _cy += dy;
      if (!(_ed?.nudge(dx, dy) ?? false) && _blocked == null) {
        _blocked = (dx, dy);
        _blockedAt = dx != 0 ? _cx : _cy;
        _ed?.holdNudge(dx, dy);
      }
    }
  }

  void _end() {
    _start = null;
    _blocked = null;
    _ed?.releaseNudge();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    Widget arrow(String key, String tip, IconData icon, int dx, int dy, Alignment at) => Align(
      alignment: at,
      child: IconButton(
        key: ValueKey('plan-nudge-$key'),
        tooltip: tip,
        visualDensity: VisualDensity.compact,
        onPressed: () => _ed?.nudge(dx, dy, grow: true),
        icon: Icon(icon, color: c.fg),
      ),
    );
    return SizedBox(
      width: 112,
      height: 112,
      child: Listener(
        key: const ValueKey('plan-nudge-pad'),
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _start = e.localPosition;
          _cx = _cy = 0;
        },
        onPointerMove: (e) => _drag(e.localPosition),
        onPointerUp: (_) => _end(),
        onPointerCancel: (_) => _end(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.muted,
            shape: BoxShape.circle,
            border: Border.all(color: c.border),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.mutedFg.withValues(alpha: 0.5)),
                  ),
                  padding: const EdgeInsets.all(4),
                  alignment: Alignment.center,
                  child: FitText(
                    l.planNudge,
                    style: AppType.caption.copyWith(fontSize: 10, height: 1.1, color: c.mutedFg),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              arrow('up', l.planNudgeUp, Icons.keyboard_arrow_up_rounded, 0, -1, Alignment.topCenter),
              arrow('down', l.planNudgeDown, Icons.keyboard_arrow_down_rounded, 0, 1, Alignment.bottomCenter),
              arrow('left', l.planNudgeLeft, Icons.keyboard_arrow_left_rounded, -1, 0, Alignment.centerLeft),
              arrow('right', l.planNudgeRight, Icons.keyboard_arrow_right_rounded, 1, 0, Alignment.centerRight),
            ],
          ),
        ),
      ),
    );
  }
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
            SizedBox(
              width: 44,
              child: Text(label, style: AppType.caption.copyWith(color: c.mutedFg)),
            ),
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
                    Expanded(
                      child: Center(child: OneLine([l.planSquares(value, planMeters(value)), l.planSquaresShort(value)], style: AppType.label)),
                    ),
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
