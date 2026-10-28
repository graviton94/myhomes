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
    final same = data.spaces.where((s) => !s.outside && s.plan == null && s.name.trim() == name.trim()).firstOrNull;
    if (same != null) {
      data = setRoomPlan(data, same.id, room.rect);
    } else {
      final r = addSpace(data, ctx, name, icon: templateRoomIcons[room.key]);
      data = setRoomPlan(r.data, r.value.id, room.rect);
    }
  }
  return data;
}

/// Puts a room on the plan (or takes it off with null). Sizes are at least
/// 2 x 2 squares (1 m) and never negative.
HomeData setRoomPlan(HomeData d, String spaceId, PlanRect? rect) {
  final r = rect == null
      ? null
      : PlanRect(rect.x < 0 ? 0 : rect.x, rect.y < 0 ? 0 : rect.y, rect.w < 2 ? 2 : rect.w, rect.h < 2 ? 2 : rect.h);
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
