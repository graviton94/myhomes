/// The floor plan: rooms as rectangles on 0.5 m squares, started from a
/// template of common Korean apartment layouts (v0.7 step 5).
library;

import 'model.dart';
import 'ops.dart';

/// A room in a template. [key] names it (the app turns it into words and an
/// icon in the user's language).
class TemplateRoom {
  const TemplateRoom(this.key, this.rect);

  final String key;
  final PlanRect rect;
}

class HouseTemplate {
  const HouseTemplate(this.id, this.cols, this.rows, this.rooms);

  final String id;
  final int cols, rows;
  final List<TemplateRoom> rooms;
}

/// Real sizes by exclusive area, south (the balcony) at the bottom.
const houseTemplates = [
  HouseTemplate('apt84', 22, 19, [
    TemplateRoom('bedroom3', PlanRect(0, 0, 5, 7)),
    TemplateRoom('bath', PlanRect(5, 0, 4, 7)),
    TemplateRoom('entrance', PlanRect(9, 0, 3, 7)),
    TemplateRoom('kitchen', PlanRect(12, 0, 6, 7)),
    TemplateRoom('dressroom', PlanRect(18, 0, 4, 3)),
    TemplateRoom('masterBath', PlanRect(18, 3, 4, 4)),
    TemplateRoom('bedroom2', PlanRect(0, 7, 6, 9)),
    TemplateRoom('living', PlanRect(6, 7, 9, 9)),
    TemplateRoom('master', PlanRect(15, 7, 7, 9)),
    TemplateRoom('balcony', PlanRect(0, 16, 22, 3)),
  ]),
  HouseTemplate('apt84bay4', 26, 19, [
    TemplateRoom('bath', PlanRect(0, 0, 5, 7)),
    TemplateRoom('entrance', PlanRect(5, 0, 4, 7)),
    TemplateRoom('kitchen', PlanRect(9, 0, 9, 7)),
    TemplateRoom('dressroom', PlanRect(18, 0, 4, 7)),
    TemplateRoom('masterBath', PlanRect(22, 0, 4, 7)),
    TemplateRoom('bedroom3', PlanRect(0, 7, 6, 9)),
    TemplateRoom('bedroom2', PlanRect(6, 7, 6, 9)),
    TemplateRoom('living', PlanRect(12, 7, 8, 9)),
    TemplateRoom('master', PlanRect(20, 7, 6, 9)),
    TemplateRoom('balcony', PlanRect(0, 16, 26, 3)),
  ]),
  HouseTemplate('apt84tower', 24, 19, [
    TemplateRoom('master', PlanRect(16, 0, 8, 5)),
    TemplateRoom('masterBath', PlanRect(16, 5, 8, 4)),
    TemplateRoom('bath', PlanRect(0, 5, 4, 4)),
    TemplateRoom('entrance', PlanRect(4, 5, 3, 4)),
    TemplateRoom('utility', PlanRect(7, 5, 4, 4)),
    TemplateRoom('kitchen', PlanRect(11, 5, 5, 4)),
    TemplateRoom('bedroom2', PlanRect(0, 9, 7, 8)),
    TemplateRoom('bedroom3', PlanRect(7, 9, 6, 8)),
    TemplateRoom('living', PlanRect(13, 9, 11, 8)),
    TemplateRoom('balcony', PlanRect(0, 17, 24, 2)),
  ]),
  HouseTemplate('apt59', 19, 17, [
    TemplateRoom('bedroom3', PlanRect(0, 0, 5, 6)),
    TemplateRoom('bath', PlanRect(5, 0, 3, 6)),
    TemplateRoom('entrance', PlanRect(8, 0, 4, 6)),
    TemplateRoom('kitchen', PlanRect(12, 0, 4, 6)),
    TemplateRoom('masterBath', PlanRect(16, 0, 3, 6)),
    TemplateRoom('bedroom2', PlanRect(0, 6, 5, 8)),
    TemplateRoom('living', PlanRect(5, 6, 8, 8)),
    TemplateRoom('master', PlanRect(13, 6, 6, 8)),
    TemplateRoom('balcony', PlanRect(0, 14, 19, 3)),
  ]),
  HouseTemplate('villa2', 16, 14, [
    TemplateRoom('bedroom2', PlanRect(0, 0, 7, 7)),
    TemplateRoom('living', PlanRect(7, 0, 9, 8)),
    TemplateRoom('master', PlanRect(0, 7, 7, 7)),
    TemplateRoom('bath', PlanRect(7, 8, 4, 6)),
    TemplateRoom('entrance', PlanRect(11, 8, 5, 3)),
    TemplateRoom('utility', PlanRect(11, 11, 5, 3)),
  ]),
  HouseTemplate('studio', 10, 14, [
    TemplateRoom('bath', PlanRect(0, 0, 4, 3)),
    TemplateRoom('entrance', PlanRect(4, 0, 6, 3)),
    TemplateRoom('kitchen', PlanRect(0, 3, 10, 3)),
    TemplateRoom('room', PlanRect(0, 6, 10, 8)),
  ]),
];

/// Icon for each template room key.
const templateRoomIcons = {
  'bedroom2': 'bedroom',
  'bedroom3': 'kids',
  'master': 'bedroom',
  'bath': 'bathroom',
  'masterBath': 'bathroom',
  'entrance': 'entrance',
  'kitchen': 'kitchen',
  'dressroom': 'wardrobe',
  'living': 'living',
  'balcony': 'balcony',
  'utility': 'laundry',
  'room': 'home',
};

/// Lays [t] out: a room already named like a template room (and not on the
/// plan yet) takes that place; the rest are created. [nameOf] gives each key's
/// name in the user's language.
HomeData applyTemplate(HomeData d, Ctx ctx, HouseTemplate t, String Function(String key) nameOf) {
  var data = d;
  for (final room in t.rooms) {
    final name = nameOf(room.key);
    // A room of that name already there takes the place, on the plan or not:
    // laying a template out a second time must not make a second living room.
    final named = data.spaces.where((s) => !s.outside && !s.moving && s.name.trim() == name.trim()).toList();
    final same = named.where((s) => s.plan == null).firstOrNull ?? named.firstOrNull;
    if (same != null) {
      data = setRoomPlan(data, same.id, room.rect);
    } else {
      final r = addSpace(data, ctx, name, icon: templateRoomIcons[room.key]);
      data = setRoomPlan(r.data, r.value.id, room.rect);
    }
  }
  return dropEmptyTwins(data);
}

/// Rooms with the same name where only one is in use: the empty extras go
/// (an earlier version made a new room each time a template was laid out).
/// A room with anything in it is never removed; if the one kept is off the
/// plan and an extra was on it, the kept one takes that place.
HomeData dropEmptyTwins(HomeData d) {
  final byName = <String, List<Space>>{};
  for (final s in d.spaces.where((s) => !s.outside && !s.moving)) {
    byName.putIfAbsent(s.name.trim(), () => []).add(s);
  }
  var out = d;
  for (final twins in byName.values.where((t) => t.length > 1)) {
    bool used(Space s) => d.containersIn(s.id).isNotEmpty;
    final keep = twins.where(used).toList();
    if (keep.isEmpty) keep.add(twins.where((s) => s.plan != null).firstOrNull ?? twins.first);
    for (final s in twins.where((s) => !keep.contains(s))) {
      if (s.plan != null && keep.every((k) => out.space(k.id)?.plan == null)) {
        out = setRoomPlan(out, keep.first.id, s.plan);
      }
      out = deleteSpace(out, s.id);
    }
  }
  return out;
}

/// Puts a room on the plan (or takes it off with null). Sizes are at least
/// 2 x 2 squares (1 m) and never negative.
HomeData setRoomPlan(HomeData d, String spaceId, PlanRect? rect) {
  final r = rect == null ? null : PlanRect(rect.x < 0 ? 0 : rect.x, rect.y < 0 ? 0 : rect.y, rect.w < 2 ? 2 : rect.w, rect.h < 2 ? 2 : rect.h);
  return d.copyWith(
    spaces: [for (final s in d.spaces) s.id == spaceId ? s.copyWith(plan: r, clearPlan: r == null) : s],
  );
}

/// Rooms on the plan.
List<Space> plannedRooms(HomeData d) => d.spaces.where((s) => !s.outside && s.plan != null).toList();

/// Size of the plan in squares (columns, rows); (0, 0) when nothing is placed.
(int, int) planSize(HomeData d) {
  var cols = 0, rows = 0;
  for (final s in plannedRooms(d)) {
    if (s.plan!.right > cols) cols = s.plan!.right;
    if (s.plan!.bottom > rows) rows = s.plan!.bottom;
  }
  return (cols, rows);
}

/// A free w x h spot for a new room: right of the plan, else below it.
PlanRect freePlanSpot(HomeData d, {int w = 6, int h = 6}) {
  final rooms = plannedRooms(d).map((s) => s.plan!).toList();
  final (cols, rows) = planSize(d);
  for (var y = 0; y <= rows; y++) {
    for (var x = 0; x <= cols; x++) {
      final r = PlanRect(x, y, w, h);
      if (!rooms.any(r.overlaps)) return r;
    }
  }
  return PlanRect(0, rows, w, h);
}

/// Furniture, boxes and spots standing on a room's floor (not inside another).
List<Storage> floorStorages(HomeData d, String spaceId) => d.containersIn(spaceId);

/// Places [storageId] in its room (null takes it off the floor plan). At
/// least one square, and kept inside the room when the room is on the plan.
HomeData setStoragePlan(HomeData d, String storageId, PlanRect? rect) {
  final s = d.container(storageId);
  if (s == null) return d;
  PlanRect? r;
  if (rect != null) {
    final room = d.space(s.spaceId)?.plan;
    var w = rect.w < 1 ? 1 : rect.w, h = rect.h < 1 ? 1 : rect.h;
    var x = rect.x < 0 ? 0 : rect.x, y = rect.y < 0 ? 0 : rect.y;
    if (room != null) {
      if (w > room.w) w = room.w;
      if (h > room.h) h = room.h;
      if (x + w > room.w) x = room.w - w;
      if (y + h > room.h) y = room.h - h;
    }
    r = PlanRect(x, y, w, h);
  }
  return d.copyWith(
    containers: [for (final c in d.containers) c.id == storageId ? c.copyWith(plan: r, clearPlan: r == null) : c],
  );
}

/// A free w x h spot on a room's floor, else its top left corner.
PlanRect freeStorageSpot(HomeData d, String spaceId, {int w = 2, int h = 1}) {
  final room = d.space(spaceId)?.plan ?? const PlanRect(0, 0, 8, 8);
  final taken = floorStorages(d, spaceId).map((s) => s.plan).whereType<PlanRect>().toList();
  for (var y = 0; y + h <= room.h; y++) {
    for (var x = 0; x + w <= room.w; x++) {
      final r = PlanRect(x, y, w, h);
      if (!taken.any(r.overlaps)) return r;
    }
  }
  return PlanRect(0, 0, w, h);
}

/// Where a block is being stretched from: its four sides and four corners.
enum PlanHandle { left, top, right, bottom, topLeft, topRight, bottomLeft, bottomRight }

/// [r] stretched by [dx], [dy] squares from [h]: the opposite side stays put.
/// Never smaller than [min] squares; never past 0 or, when given, [cols] /
/// [rows] (a room's furniture stays in the room).
PlanRect resizePlan(PlanRect r, PlanHandle h, int dx, int dy, {int min = 2, int? cols, int? rows}) {
  var left = r.x, top = r.y, right = r.right, bottom = r.bottom;
  final west = h == PlanHandle.left || h == PlanHandle.topLeft || h == PlanHandle.bottomLeft;
  final east = h == PlanHandle.right || h == PlanHandle.topRight || h == PlanHandle.bottomRight;
  final north = h == PlanHandle.top || h == PlanHandle.topLeft || h == PlanHandle.topRight;
  final south = h == PlanHandle.bottom || h == PlanHandle.bottomLeft || h == PlanHandle.bottomRight;
  if (west) left = (left + dx).clamp(0, right - min);
  if (east) right = (right + dx).clamp(left + min, cols ?? 1 << 20);
  if (north) top = (top + dy).clamp(0, bottom - min);
  if (south) bottom = (bottom + dy).clamp(top + min, rows ?? 1 << 20);
  return PlanRect(left, top, right - left, bottom - top);
}

/// [r] moved by [dx], [dy] squares, kept at 0 or more and, when given,
/// inside [cols] × [rows].
PlanRect movePlan(PlanRect r, int dx, int dy, {int? cols, int? rows}) => PlanRect(
  (r.x + dx).clamp(0, cols == null ? 1 << 20 : (cols - r.w).clamp(0, 1 << 20)),
  (r.y + dy).clamp(0, rows == null ? 1 << 20 : (rows - r.h).clamp(0, 1 << 20)),
  r.w,
  r.h,
);

/// A new room where the floor was double-tapped (square [x], [y]): up to
/// w x h around that square, shrunk (down to 2 x 2) to stay off the other
/// rooms. Null when the square is in a room or the gap is too small.
PlanRect? planSpotAt(HomeData d, int x, int y, {int w = 6, int h = 6}) {
  final rooms = plannedRooms(d).map((s) => s.plan!).toList();
  if (x < 0 || y < 0 || rooms.any((r) => r.overlaps(PlanRect(x, y, 1, 1)))) return null;
  // Bigger first, and among one size the one centred on the tap.
  for (var size = w > h ? w : h; size >= 2; size--) {
    final cw = size < w ? size : w, ch = size < h ? size : h;
    final tries = <PlanRect>[];
    for (var dy = 0; dy < ch; dy++) {
      for (var dx = 0; dx < cw; dx++) {
        final r = PlanRect(x - dx, y - dy, cw, ch);
        if (r.x >= 0 && r.y >= 0 && !rooms.any(r.overlaps)) tries.add(r);
      }
    }
    if (tries.isEmpty) continue;
    double off(PlanRect r) => ((r.x + r.w / 2) - (x + 0.5)).abs() + ((r.y + r.h / 2) - (y + 0.5)).abs();
    tries.sort((a, b) => off(a).compareTo(off(b)));
    return tries.first;
  }
  return null;
}

/// The box around every room on the plan; null when none is placed.
PlanRect? planBounds(HomeData d) {
  final rooms = plannedRooms(d).map((s) => s.plan!).toList();
  if (rooms.isEmpty) return null;
  var x0 = rooms.first.x, y0 = rooms.first.y, x1 = rooms.first.right, y1 = rooms.first.bottom;
  for (final r in rooms) {
    if (r.x < x0) x0 = r.x;
    if (r.y < y0) y0 = r.y;
    if (r.right > x1) x1 = r.right;
    if (r.bottom > y1) y1 = r.bottom;
  }
  return PlanRect(x0, y0, x1 - x0, y1 - y0);
}
