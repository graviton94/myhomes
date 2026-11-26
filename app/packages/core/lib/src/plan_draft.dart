/// Editing the map as a draft (user request: nothing changes until 저장,
/// 취소 puts it back; rooms may overlap while being arranged and are asked
/// about once on saving; the squares go on in every direction; the picked
/// block is grabbed anywhere near its walls, corners stretch both ways).
library;

import 'dart:math' as math;

import 'model.dart';
import 'kinds.dart';
import 'plan.dart';

/// What a finger took hold of on the picked block: its middle (move), or a
/// side or corner (stretch).
class PlanGrab {
  const PlanGrab._(this.handle);

  static const move = PlanGrab._(null);

  final PlanHandle? handle;
}

/// Where a finger at [x], [y] (squares × [cell] px, on the plan) lands on the
/// picked block [r] when the view is zoomed by [scale]. The grab zone runs
/// [outside] screen px beyond the walls and a quarter of the block (between
/// [inside] and [insideMax] screen px, at most a third) in from them; the zones at the corners
/// stretch both ways. Null when the finger is not near the block at all.
PlanGrab? planGrab(
  PlanRect r,
  double x,
  double y, {
  required double cell,
  double scale = 1,
  double outside = 48,
  double inside = 24,
  double insideMax = 44,
}) {
  final out = outside / scale;
  final l = r.x * cell, t = r.y * cell, rt = r.right * cell, b = r.bottom * cell;
  if (x < l - out || x > rt + out || y < t - out || y > b + out) return null;
  // Never more than a third, so even a small block keeps a middle to move it by.
  double band(double size) => math.min((size * 0.25).clamp(inside / scale, insideMax / scale), size / 3);
  final ix = band(rt - l), iy = band(b - t);
  final north = y < t + iy, south = !north && y > b - iy;
  final west = x < l + ix, east = !west && x > rt - ix;
  final handle = switch ((north, south, west, east)) {
    (true, _, true, _) => PlanHandle.topLeft,
    (true, _, _, true) => PlanHandle.topRight,
    (_, true, true, _) => PlanHandle.bottomLeft,
    (_, true, _, true) => PlanHandle.bottomRight,
    (true, _, _, _) => PlanHandle.top,
    (_, true, _, _) => PlanHandle.bottom,
    (_, _, true, _) => PlanHandle.left,
    (_, _, _, true) => PlanHandle.right,
    _ => null,
  };
  return handle == null ? PlanGrab.move : PlanGrab._(handle);
}

bool _west(PlanHandle h) => h == PlanHandle.left || h == PlanHandle.topLeft || h == PlanHandle.bottomLeft;
bool _east(PlanHandle h) => h == PlanHandle.right || h == PlanHandle.topRight || h == PlanHandle.bottomRight;
bool _north(PlanHandle h) => h == PlanHandle.top || h == PlanHandle.topLeft || h == PlanHandle.topRight;
bool _south(PlanHandle h) => h == PlanHandle.bottom || h == PlanHandle.bottomLeft || h == PlanHandle.bottomRight;

/// [r] stretched by [dx], [dy] squares from [h], the opposite side staying
/// put, never smaller than [min]. Free in every direction, or kept inside
/// [within] (a room's floor, for its furniture).
PlanRect stretchPlan(PlanRect r, PlanHandle h, int dx, int dy, {int min = 2, PlanRect? within}) {
  var l = r.x, t = r.y, rt = r.right, b = r.bottom;
  if (_west(h)) l = l + dx > rt - min ? rt - min : l + dx;
  if (_east(h)) rt = rt + dx < l + min ? l + min : rt + dx;
  if (_north(h)) t = t + dy > b - min ? b - min : t + dy;
  if (_south(h)) b = b + dy < t + min ? t + min : b + dy;
  if (within != null) {
    if (l < within.x) l = within.x;
    if (t < within.y) t = within.y;
    if (rt > within.right) rt = within.right;
    if (b > within.bottom) b = within.bottom;
  }
  return PlanRect(l, t, rt - l, b - t);
}

/// [r] moved by [dx], [dy] squares; free, or kept inside [within].
PlanRect shiftPlan(PlanRect r, int dx, int dy, {PlanRect? within}) {
  var x = r.x + dx, y = r.y + dy;
  if (within != null) {
    if (x + r.w > within.right) x = within.right - r.w;
    if (y + r.h > within.bottom) y = within.bottom - r.h;
    if (x < within.x) x = within.x;
    if (y < within.y) y = within.y;
  }
  return PlanRect(x, y, r.w, r.h);
}

/// A moved or stretched block pulled onto a neighbour's wall it has come
/// within one square of (it never holds a wall back once it is past). [from]
/// is where the block was when the finger came down; [handle] null = moving.
/// Also says whether it was pulled (for a small buzz).
(PlanRect, bool) magnetPlan(PlanRect r, PlanRect from, PlanHandle? handle, Iterable<PlanRect> others) {
  var l = r.x, t = r.y, rt = r.right, b = r.bottom;
  var pulled = false;
  bool may(bool Function(PlanHandle) side) => handle == null || side(handle);
  // Within one square and coming from the same side it was on.
  bool near(int wall, int now, int was) => (wall - now).abs() == 1 && (wall - now).sign == (wall - was).sign;
  for (final o in others) {
    final facingX = t < o.bottom + 1 && o.y < b + 1, facingY = l < o.right + 1 && o.x < rt + 1;
    if (facingX) {
      for (final wall in [o.x, o.right]) {
        if (may(_west) && near(wall, l, from.x)) {
          final d = wall - l;
          l += d;
          if (handle == null) rt += d;
          pulled = true;
          break;
        }
        if (may(_east) && near(wall, rt, from.right)) {
          final d = wall - rt;
          rt += d;
          if (handle == null) l += d;
          pulled = true;
          break;
        }
      }
    }
    if (facingY) {
      for (final wall in [o.y, o.bottom]) {
        if (may(_north) && near(wall, t, from.y)) {
          final d = wall - t;
          t += d;
          if (handle == null) b += d;
          pulled = true;
          break;
        }
        if (may(_south) && near(wall, b, from.bottom)) {
          final d = wall - b;
          b += d;
          if (handle == null) t += d;
          pulled = true;
          break;
        }
      }
    }
  }
  if (rt - l < 1 || b - t < 1) return (r, false);
  return (PlanRect(l, t, rt - l, b - t), pulled);
}

/// The blocks that overlap another one.
Set<String> overlappingPlans(Map<String, PlanRect> plans) {
  final out = <String>{};
  final list = plans.entries.toList();
  for (var i = 0; i < list.length; i++) {
    for (var j = i + 1; j < list.length; j++) {
      if (list[i].value.overlaps(list[j].value)) out.addAll([list[i].key, list[j].key]);
    }
  }
  return out;
}

/// The plan moved so its top-left block starts at square 0, 0 (rooms
/// dragged up or left of the start are kept, not cut off).
Map<String, PlanRect> normalizePlans(Map<String, PlanRect> plans) {
  if (plans.isEmpty) return plans;
  final x0 = plans.values.map((r) => r.x).reduce((a, b) => a < b ? a : b);
  final y0 = plans.values.map((r) => r.y).reduce((a, b) => a < b ? a : b);
  return {for (final e in plans.entries) e.key: PlanRect(e.value.x - x0, e.value.y - y0, e.value.w, e.value.h)};
}

/// Saves a draft of the house plan: every room in [plans] gets its place
/// (moved to start at 0, 0), every other room comes off the map.
HomeData saveRoomPlans(HomeData d, Map<String, PlanRect> plans) {
  final at = normalizePlans(plans);
  return d.copyWith(
    spaces: [
      for (final s in d.spaces)
        if (s.outside)
          s
        else if (at[s.id] case final r?)
          s.copyWith(plan: r)
        else
          s.copyWith(clearPlan: true),
    ],
  );
}

/// Saves a draft of a room's floor: what is in [plans] stands there (kept
/// inside the room), every other piece of the room comes off the floor.
HomeData saveStoragePlans(HomeData d, String spaceId, Map<String, PlanRect> plans) {
  var out = d;
  for (final s in floorStorages(d, spaceId)) {
    out = setStoragePlan(out, s.id, plans[s.id]);
  }
  return out;
}

/// The size a storage spot gets when first put on its room's floor.
(int, int) floorSize(StorageKind kind) => switch (kind) {
  StorageKind.furniture => (3, 1),
  StorageKind.box => (1, 1),
  _ => (2, 1),
};

/// Puts storage spots standing on a room's floor into a free spot of it
/// (user request: new spots show on the map as furniture, not only as a
/// label). Only rooms on the map; spots inside furniture and spots already
/// placed are left as they are.
HomeData placeOnFloor(HomeData d, Iterable<String> storageIds) {
  var out = d;
  for (final id in storageIds) {
    final s = out.container(id);
    if (s == null || s.parentId != null || s.plan != null || out.space(s.spaceId)?.plan == null) continue;
    final (w, h) = floorSize(s.kind);
    out = setStoragePlan(out, id, freeStorageSpot(out, s.spaceId, w: w, h: h));
  }
  return out;
}

/// Moves a storage spot (with what is inside it) to another room's floor
/// at [rect] (in that room's squares), as dragging it across the map does.
HomeData moveToRoomFloor(HomeData d, String storageId, String spaceId, PlanRect rect) {
  final s = d.container(storageId);
  if (s == null) return d;
  final moved = s.spaceId == spaceId ? d : moveContainer(d, storageId, spaceId: spaceId);
  return setStoragePlan(moved, storageId, rect);
}

/// The land the map is edited on (user request, docs/mockups/map-editor-v3.html):
/// every block with [margin] squares round it. Blocks stay on it; it grows a
/// square at a time only when a block is held against its edge.
PlanRect planLand(Iterable<PlanRect> rects, {int margin = 2}) {
  if (rects.isEmpty) return PlanRect(-6 - margin, -6 - margin, 12 + 2 * margin, 12 + 2 * margin);
  final x0 = rects.map((r) => r.x).reduce(math.min), y0 = rects.map((r) => r.y).reduce(math.min);
  final x1 = rects.map((r) => r.right).reduce(math.max), y1 = rects.map((r) => r.bottom).reduce(math.max);
  return PlanRect(x0 - margin, y0 - margin, x1 - x0 + 2 * margin, y1 - y0 + 2 * margin);
}

/// The smallest land holding both [a] and [b].
PlanRect landUnion(PlanRect a, PlanRect b) {
  final x0 = math.min(a.x, b.x), y0 = math.min(a.y, b.y);
  return PlanRect(x0, y0, math.max(a.right, b.right) - x0, math.max(a.bottom, b.bottom) - y0);
}

/// Whether [r] lies on [land].
bool onLand(PlanRect r, PlanRect land) => r.x >= land.x && r.y >= land.y && r.right <= land.right && r.bottom <= land.bottom;

/// Whether [r] is pressed against [land]'s edge on the side [dx], [dy] points to.
bool atLandEdge(PlanRect r, PlanRect land, int dx, int dy) =>
    (dx < 0 && r.x <= land.x) || (dx > 0 && r.right >= land.right) || (dy < 0 && r.y <= land.y) || (dy > 0 && r.bottom >= land.bottom);

/// [land] one square bigger on the side [dx], [dy] points to.
PlanRect growLand(PlanRect land, int dx, int dy) => PlanRect(
  dx < 0 ? land.x - 1 : land.x,
  dy < 0 ? land.y - 1 : land.y,
  land.w + (dx != 0 ? 1 : 0),
  land.h + (dy != 0 ? 1 : 0),
);

/// The rooms whose wall is [id]'s wall on [side] (a side, not a corner),
/// facing it along some of its length: they move with it when "붙은 벽 같이
/// 밀기" is on (user request, like pushing a wall in house-building games).
List<String> wallNeighbours(Map<String, PlanRect> plans, String id, PlanHandle side) {
  final r = plans[id];
  if (r == null) return const [];
  bool facesY(PlanRect n) => n.y < r.bottom && r.y < n.bottom;
  bool facesX(PlanRect n) => n.x < r.right && r.x < n.right;
  return [
    for (final e in plans.entries)
      if (e.key != id &&
          switch (side) {
            PlanHandle.right => e.value.x == r.right && facesY(e.value),
            PlanHandle.left => e.value.right == r.x && facesY(e.value),
            PlanHandle.bottom => e.value.y == r.bottom && facesX(e.value),
            PlanHandle.top => e.value.bottom == r.y && facesX(e.value),
            _ => false,
          })
        e.key,
  ];
}

/// [to] (stretched from [side]) with the [neighbours] (as they were) following
/// the shared wall: they shrink or grow so no gap or overlap opens, and the
/// wall stops one square before a neighbour would vanish.
(PlanRect, Map<String, PlanRect>) pushWall(PlanRect to, PlanHandle side, Map<String, PlanRect> neighbours) {
  var l = to.x, t = to.y, rt = to.right, b = to.bottom;
  for (final n in neighbours.values) {
    switch (side) {
      case PlanHandle.right:
        rt = math.min(rt, n.right - 1);
      case PlanHandle.left:
        l = math.max(l, n.x + 1);
      case PlanHandle.bottom:
        b = math.min(b, n.bottom - 1);
      case PlanHandle.top:
        t = math.max(t, n.y + 1);
      default:
    }
  }
  final out = {
    for (final e in neighbours.entries)
      e.key: switch (side) {
        PlanHandle.right => PlanRect(rt, e.value.y, e.value.right - rt, e.value.h),
        PlanHandle.left => PlanRect(e.value.x, e.value.y, l - e.value.x, e.value.h),
        PlanHandle.bottom => PlanRect(e.value.x, b, e.value.w, e.value.bottom - b),
        PlanHandle.top => PlanRect(e.value.x, e.value.y, e.value.w, t - e.value.y),
        _ => e.value,
      },
  };
  return (PlanRect(l, t, rt - l, b - t), out);
}

/// [r] turned a quarter round its middle (furniture), kept inside [within].
PlanRect turnPlan(PlanRect r, {PlanRect? within}) {
  final cx = r.x * 2 + r.w, cy = r.y * 2 + r.h; // doubled, to stay on whole squares
  final t = PlanRect(((cx - r.h) / 2).floor(), ((cy - r.w) / 2).floor(), r.h, r.w);
  if (within == null) return t;
  final w = math.min(t.w, within.w), h = math.min(t.h, within.h);
  return shiftPlan(PlanRect(t.x, t.y, w, h), 0, 0, within: within);
}
