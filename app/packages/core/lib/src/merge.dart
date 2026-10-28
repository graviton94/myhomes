/// Bringing a phone's own things into a shared home (v0.9): rooms and
/// storage with the same name become one, the rest is added; things of the
/// same kind in the same place add up.
library;

import 'hangul.dart';
import 'kinds.dart';
import 'model.dart';
import 'ops.dart';

/// Puts [from] into [into]. Returns the merged home and how many things
/// (quantities) came in. Rooms come in off the floor plan; spots keep their
/// return dates and boxes get the next free number.
Result<int> mergeHome(HomeData into, HomeData from, Ctx ctx) {
  var d = into;
  String key(String name) => cleanText(name).toLowerCase();
  final spaces = <String, String>{}, boxes = <String, String>{};

  for (final s in from.spaces) {
    final same = d.spaces.where((t) => t.outside == s.outside && key(t.name) == key(s.name)).firstOrNull;
    if (same != null) {
      spaces[s.id] = same.id;
    } else {
      final r = addSpace(d, ctx, s.name, photoPath: s.photoPath, icon: s.icon, outside: s.outside);
      d = r.data;
      spaces[s.id] = r.value.id;
    }
  }

  void place(Storage c) {
    final spaceId = spaces[c.spaceId];
    if (spaceId == null) return;
    final parentId = c.parentId == null ? null : boxes[c.parentId];
    if (c.parentId != null && parentId == null) return;
    final same = d.containers
        .where((t) => t.spaceId == spaceId && t.parentId == parentId && t.kind == c.kind && key(t.name) == key(c.name))
        .firstOrNull;
    if (same != null) {
      boxes[c.id] = same.id;
    } else {
      final r = addContainer(
        d,
        ctx,
        spaceId: spaceId,
        name: c.name,
        parentId: parentId,
        photoPath: c.photoPath,
        icon: c.icon,
        returnBy: c.returnBy,
        kind: c.kind,
        number: c.kind == StorageKind.box ? nextBoxNumber(d) : null,
      );
      d = r.data;
      boxes[c.id] = r.value.id;
    }
    for (final child in from.childrenOf(c.id)) {
      place(child);
    }
  }

  for (final c in from.containers.where((c) => c.parentId == null)) {
    place(c);
  }

  var count = 0;
  for (final item in from.items) {
    final containerId = boxes[item.containerId];
    if (containerId == null) continue;
    final same = d.itemsIn(containerId).where((i) => i.sameKindAs(item)).firstOrNull;
    if (same != null) {
      d = adjustQty(d, ctx, same.id, item.qty);
    } else {
      d = addItem(
        d,
        ctx,
        containerId: containerId,
        name: item.name,
        category: item.category,
        qty: item.qty,
        expiresOn: item.expiresOn,
        photoPath: item.photoPath,
        note: item.note,
        icon: item.icon,
        minQty: item.minQty,
        barcode: item.barcode,
      ).data;
    }
    count += item.qty;
  }
  return Result(d, count);
}
