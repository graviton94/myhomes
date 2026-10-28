/// Furniture with sections, numbered boxes and plain spots (v0.7 step 3).
library;

import 'location_code.dart';
import 'model.dart';
import 'ops.dart';

/// Number for the next box: one more than the highest so far.
int nextBoxNumber(HomeData d) =>
    d.containers.where((c) => c.kind == StorageKind.box).fold(0, (n, c) => (c.number ?? 0) > n ? c.number! : n) + 1;

/// A piece of furniture's sections, top to bottom.
List<Storage> sectionsOf(HomeData d, String furnitureId) =>
    d.childrenOf(furnitureId).where((c) => c.kind == StorageKind.section).toList();

/// Boxes sitting directly in [parentId] (a section, a box, or furniture).
List<Storage> boxesIn(HomeData d, String parentId) => d.childrenOf(parentId).where((c) => c.kind == StorageKind.box).toList();

/// Boxes on a room's floor.
List<Storage> floorBoxes(HomeData d, String spaceId) =>
    d.containersIn(spaceId).where((c) => c.kind == StorageKind.box).toList();

/// Whether things can be put straight into [s]. Furniture split into
/// sections holds its things in the sections.
bool holdsItems(HomeData d, Storage s) => s.kind != StorageKind.furniture || sectionsOf(d, s.id).isEmpty;

/// Every spot in a room that can hold things, in board order: each top-level
/// storage, then its sections and boxes depth first.
List<Storage> placesIn(HomeData d, String spaceId) {
  final out = <Storage>[];
  void walk(Storage s) {
    if (holdsItems(d, s)) out.add(s);
    for (final child in d.childrenOf(s.id)) {
      walk(child);
    }
  }

  for (final s in d.containersIn(spaceId)) {
    walk(s);
  }
  return out;
}

/// Furniture with its sections (top to bottom) in one change.
Result<Storage> addFurniture(
  HomeData d,
  Ctx ctx, {
  required String spaceId,
  required String name,
  required List<String> sections,
  String? photoPath,
  String? icon,
}) {
  final f = addContainer(d, ctx, spaceId: spaceId, name: name, photoPath: photoPath, icon: icon, kind: StorageKind.furniture);
  var data = f.data;
  for (final s in sections.map((s) => s.trim()).where((s) => s.isNotEmpty)) {
    data = addContainer(data, ctx, spaceId: spaceId, name: s, parentId: f.value.id, kind: StorageKind.section).data;
  }
  return Result(data, f.value);
}

/// A new numbered box on a room's floor, or inside [parentId].
Result<Storage> addBox(
  HomeData d,
  Ctx ctx, {
  required String spaceId,
  required String name,
  String? parentId,
  String? photoPath,
  String? icon,
}) => addContainer(
  d,
  ctx,
  spaceId: spaceId,
  name: name,
  parentId: parentId,
  photoPath: photoPath,
  icon: icon,
  kind: StorageKind.box,
  number: nextBoxNumber(d),
);

/// Whether box or spot [id] may go into [parentId] (null = a room's floor):
/// not into itself or anything inside it, and not into furniture that has
/// sections (pick a section).
bool canMoveContainer(HomeData d, String id, String? parentId) {
  final s = d.container(id);
  if (s == null || s.kind == StorageKind.furniture || s.kind == StorageKind.section) return false;
  if (parentId == null) return true;
  final target = d.container(parentId);
  if (target == null || !holdsItems(d, target)) return false;
  for (Storage? p = target; p != null; p = p.parentId == null ? null : d.container(p.parentId!)) {
    if (p.id == id) return false;
  }
  return true;
}

/// Moves a box (or spot) with everything in it to [spaceId], into
/// [parentId] or onto the floor. Location codes are given anew for it and
/// what is inside.
HomeData moveContainer(HomeData d, String id, {required String spaceId, String? parentId}) {
  assert(canMoveContainer(d, id, parentId));
  final space = d.space(spaceId)!;
  String code;
  if (parentId == null) {
    final taken = d.containersIn(spaceId).where((c) => c.id != id).map((c) => c.code).toSet();
    var i = d.containersIn(spaceId).length;
    while (taken.contains(containerCode(space.code, i))) {
      i++;
    }
    code = containerCode(space.code, i);
  } else {
    final parent = d.container(parentId)!;
    final taken = d.childrenOf(parentId).where((c) => c.id != id).map((c) => c.code).toSet();
    var i = d.childrenOf(parentId).length;
    while (taken.contains(childCode(parent.code, i))) {
      i++;
    }
    code = childCode(parent.code, i);
  }
  final codes = <String, String>{id: code};
  void recode(String parent) {
    for (final (i, child) in d.childrenOf(parent).indexed) {
      codes[child.id] = childCode(codes[parent]!, i);
      recode(child.id);
    }
  }

  recode(id);
  return d.copyWith(
    containers: [
      for (final c in d.containers)
        if (c.id == id)
          c.copyWith(spaceId: spaceId, parentId: parentId, clearParent: parentId == null, code: code)
        else if (codes.containsKey(c.id))
          c.copyWith(spaceId: spaceId, code: codes[c.id])
        else
          c,
    ],
  );
}

/// Items in [containerId] and everything inside it (sections, boxes).
int itemCountUnder(HomeData d, String containerId) {
  final ids = <String>{containerId};
  var grew = true;
  while (grew) {
    final more = d.containers.where((c) => c.parentId != null && ids.contains(c.parentId) && !ids.contains(c.id));
    grew = more.isNotEmpty;
    ids.addAll(more.map((c) => c.id));
  }
  return d.items.where((i) => ids.contains(i.containerId)).length;
}

/// The last thing that changed, for the megaphone line: what was done, to
/// which items (newest first) and where. Entries of the same kind to the same
/// place within a few seconds count as one change ("가위, 테이프 넣음").
class Change {
  const Change(this.type, this.names, this.containerId, this.at);

  final LogType type;
  final List<String> names;

  /// Where things went (add, move) or came from (use, used up, remove).
  final String? containerId;
  final DateTime at;
}

Change? lastChange(HomeData d) {
  if (d.log.isEmpty) return null;
  final first = d.log.first;
  String? where(LogEntry e) => e.toContainerId ?? e.fromContainerId;
  final names = <String>[];
  for (final e in d.log) {
    if (e.type != first.type || where(e) != where(first) || first.at.difference(e.at).inSeconds.abs() > 5) break;
    if (!names.contains(e.itemName)) names.add(e.itemName);
  }
  return Change(first.type, names, where(first), first.at);
}
