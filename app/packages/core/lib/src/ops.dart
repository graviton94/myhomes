/// Inventory rules as pure functions: each takes a [HomeData] and returns a
/// new one, so the app can keep the previous value for one-tap undo.
library;

import 'expiry.dart';
import 'hangul.dart';
import 'location_code.dart';
import 'model.dart';

/// Supplies ids and the clock, so tests are deterministic.
class Ctx {
  Ctx({required this.newId, required this.now});

  final String Function() newId;
  final DateTime Function() now;
}

class Result<T> {
  const Result(this.data, this.value);

  final HomeData data;
  final T value;
}

// ---------------------------------------------------------------- spaces

Result<Space> addSpace(HomeData d, Ctx ctx, String name, {String? photoPath, String? icon, bool outside = false}) {
  final code = spacePrefix(name, d.spaces.map((s) => s.code).toSet());
  final s = Space(id: ctx.newId(), name: name.trim(), code: code, photoPath: photoPath, icon: icon, outside: outside);
  return Result(d.copyWith(spaces: [...d.spaces, s]), s);
}

/// Renames and/or changes the photo. [photoPath] null keeps it; pass
/// [clearPhoto] to remove it.
HomeData updateSpace(HomeData d, String spaceId, {String? name, String? photoPath, bool clearPhoto = false, String? icon}) => d.copyWith(
  spaces: [
    for (final s in d.spaces)
      s.id == spaceId ? s.copyWith(name: name?.trim(), photoPath: photoPath, clearPhoto: clearPhoto, icon: icon) : s,
  ],
);

/// Removes a space with all its containers and items.
HomeData deleteSpace(HomeData d, String spaceId) {
  final ids = d.containers.where((c) => c.spaceId == spaceId).map((c) => c.id).toSet();
  return d.copyWith(
    spaces: d.spaces.where((s) => s.id != spaceId).toList(),
    containers: d.containers.where((c) => !ids.contains(c.id)).toList(),
    items: d.items.where((i) => !ids.contains(i.containerId)).toList(),
  );
}

// ------------------------------------------------------------ containers

Result<Storage> addContainer(
  HomeData d,
  Ctx ctx, {
  required String spaceId,
  required String name,
  String? parentId,
  String? photoPath,
  String? icon,
  DateTime? returnBy,
  StorageKind kind = StorageKind.spot,
  int? number,
}) {
  final space = d.space(spaceId)!;
  final String code;
  if (parentId == null) {
    final taken = d.containersIn(spaceId).map((c) => c.code).toSet();
    var i = d.containersIn(spaceId).length;
    while (taken.contains(containerCode(space.code, i))) {
      i++;
    }
    code = containerCode(space.code, i);
  } else {
    final parent = d.container(parentId)!;
    final taken = d.childrenOf(parentId).map((c) => c.code).toSet();
    var i = d.childrenOf(parentId).length;
    while (taken.contains(childCode(parent.code, i))) {
      i++;
    }
    code = childCode(parent.code, i);
  }
  final c = Storage(
    id: ctx.newId(),
    spaceId: spaceId,
    parentId: parentId,
    name: name.trim(),
    code: code,
    photoPath: photoPath,
    icon: icon,
    returnBy: returnBy,
    kind: kind,
    number: number,
  );
  return Result(d.copyWith(containers: [...d.containers, c]), c);
}

/// Renames and/or changes the photo. [photoPath] null keeps it; pass
/// [clearPhoto] to remove it.
HomeData updateContainer(
  HomeData d,
  String id, {
  String? name,
  String? photoPath,
  bool clearPhoto = false,
  String? icon,
  DateTime? returnBy,
  bool clearReturnBy = false,
}) => d.copyWith(
  containers: [
    for (final x in d.containers)
      x.id == id
          ? x.copyWith(
              name: name?.trim(),
              photoPath: photoPath,
              clearPhoto: clearPhoto,
              icon: icon,
              returnBy: returnBy,
              clearReturnBy: clearReturnBy,
            )
          : x,
  ],
);

/// Removes a container, its nested containers and their items.
HomeData deleteContainer(HomeData d, String id) {
  final ids = <String>{id};
  var grew = true;
  while (grew) {
    final more = d.containers.where((c) => c.parentId != null && ids.contains(c.parentId) && !ids.contains(c.id));
    grew = more.isNotEmpty;
    ids.addAll(more.map((c) => c.id));
  }
  return d.copyWith(
    containers: d.containers.where((c) => !ids.contains(c.id)).toList(),
    items: d.items.where((i) => !ids.contains(i.containerId)).toList(),
  );
}

/// Lowest square number with nothing in it. Squares never run out.
int freeSlot(HomeData d, String containerId) {
  final used = d.itemsIn(containerId).map((i) => i.slot).toSet();
  var s = 0;
  while (used.contains(s)) {
    s++;
  }
  return s;
}

/// [wanted] when it is empty, else the first free square.
int _pickSlot(HomeData d, String containerId, [int? wanted]) {
  if (wanted != null && wanted >= 0 && !d.itemsIn(containerId).any((i) => i.slot == wanted)) return wanted;
  return freeSlot(d, containerId);
}

/// Number of squares to draw: every used square, one free square after the
/// last, rounded up to whole rows of [columns].
int gridLength(HomeData d, String containerId, int columns) {
  final last = d.itemsIn(containerId).fold<int>(-1, (m, i) => i.slot > m ? i.slot : m);
  final needed = last + 2;
  final rows = (needed / columns).ceil();
  return (rows < 1 ? 1 : rows) * columns;
}

// ----------------------------------------------------------------- items

LogEntry _log(Ctx ctx, String batchId, LogType type, Item item, int qty, {String? from, String? to}) => LogEntry(
  id: ctx.newId(),
  batchId: batchId,
  type: type,
  itemName: item.name,
  qty: qty,
  at: ctx.now(),
  fromContainerId: from,
  toContainerId: to,
);

/// Adds an item to [containerId] at [slot] if free, else the first free slot.
Result<Item> addItem(
  HomeData d,
  Ctx ctx, {
  required String containerId,
  required String name,
  int? slot,
  ItemCategory category = ItemCategory.other,
  int qty = 1,
  DateTime? expiresOn,
  String? photoPath,
  String note = '',
  String? icon,
}) {
  final s = _pickSlot(d, containerId, slot);
  final item = Item(
    id: ctx.newId(),
    containerId: containerId,
    slot: s,
    name: name.trim(),
    category: category,
    qty: qty < 1 ? 1 : qty,
    expiresOn: expiresOn,
    photoPath: photoPath,
    note: note,
    icon: icon,
    updatedAt: ctx.now(),
  );
  final log = _log(ctx, ctx.newId(), LogType.add, item, item.qty, to: containerId);
  return Result(d.copyWith(items: [...d.items, item], log: [log, ...d.log]), item);
}

HomeData editItem(HomeData d, Ctx ctx, Item updated) => d.copyWith(
  items: [for (final i in d.items) i.id == updated.id ? updated.copyWith(updatedAt: ctx.now()) : i],
  log: [
    _log(ctx, ctx.newId(), LogType.edit, updated, updated.qty, to: updated.containerId),
    ...d.log,
  ],
);

HomeData removeItem(HomeData d, Ctx ctx, String itemId) {
  final item = d.item(itemId)!;
  return d.copyWith(
    items: d.items.where((i) => i.id != itemId).toList(),
    log: [
      _log(ctx, ctx.newId(), LogType.remove, item, item.qty, from: item.containerId),
      ...d.log,
    ],
  );
}

/// +1 / -1 from the item sheet. Reaching zero removes the item ("used up").
HomeData adjustQty(HomeData d, Ctx ctx, String itemId, int delta) {
  final item = d.item(itemId)!;
  final qty = item.qty + delta;
  final type = delta > 0 ? LogType.add : (qty <= 0 ? LogType.usedUp : LogType.use);
  final log = _log(ctx, ctx.newId(), type, item, delta.abs(), from: item.containerId);
  if (qty <= 0) {
    return d.copyWith(items: d.items.where((i) => i.id != itemId).toList(), log: [log, ...d.log]);
  }
  return d.copyWith(
    items: [for (final i in d.items) i.id == itemId ? i.copyWith(qty: qty, updatedAt: ctx.now()) : i],
    log: [log, ...d.log],
  );
}

/// Takes [picks] (item id -> quantity) out in one batch.
HomeData useItems(HomeData d, Ctx ctx, Map<String, int> picks) {
  final batch = ctx.newId();
  var items = d.items;
  final logs = <LogEntry>[];
  for (final e in picks.entries) {
    final item = d.item(e.key);
    if (item == null) continue;
    final take = e.value.clamp(1, item.qty);
    final left = item.qty - take;
    logs.add(_log(ctx, batch, left == 0 ? LogType.usedUp : LogType.use, item, take, from: item.containerId));
    items = left == 0
        ? items.where((i) => i.id != item.id).toList()
        : [for (final i in items) i.id == item.id ? i.copyWith(qty: left, updatedAt: ctx.now()) : i];
  }
  return d.copyWith(items: items, log: [...logs.reversed, ...d.log]);
}

/// "Used up" for several items: removes them whatever their quantity.
HomeData useUpItems(HomeData d, Ctx ctx, Iterable<String> itemIds) {
  final picks = {
    for (final id in itemIds)
      if (d.item(id) != null) id: d.item(id)!.qty,
  };
  return useItems(d, ctx, picks);
}

/// Moves [picks] (item id -> quantity) into [toContainerId] in one batch.
/// Whole stacks move; partial quantities split off a new stack. A stack of
/// the same kind already in the destination absorbs the moved quantity.
/// [toSlot] places a single moved stack in a specific empty cell.
HomeData moveItems(HomeData d, Ctx ctx, Map<String, int> picks, String toContainerId, {int? toSlot}) {
  final batch = ctx.newId();
  var data = d;
  final logs = <LogEntry>[];
  for (final e in picks.entries) {
    final item = data.item(e.key);
    if (item == null) continue;
    final qty = e.value.clamp(1, item.qty);
    if (item.containerId == toContainerId && toSlot == null) continue;
    final whole = qty == item.qty;
    final target = data.itemsIn(toContainerId).where((i) => i.id != item.id && i.sameKindAs(item)).firstOrNull;
    var items = data.items;
    if (target != null) {
      items = [for (final i in items) i.id == target.id ? i.copyWith(qty: i.qty + qty, updatedAt: ctx.now()) : i];
      items = whole
          ? items.where((i) => i.id != item.id).toList()
          : [for (final i in items) i.id == item.id ? i.copyWith(qty: item.qty - qty, updatedAt: ctx.now()) : i];
      data = data.copyWith(items: items);
    } else {
      final grown = whole ? data.copyWith(items: data.items.where((i) => i.id != item.id).toList()) : data;
      final slot = _pickSlot(grown, toContainerId, picks.length == 1 ? toSlot : null);
      final moved = whole
          ? item.copyWith(containerId: toContainerId, slot: slot, updatedAt: ctx.now())
          : Item(
              id: ctx.newId(),
              containerId: toContainerId,
              slot: slot,
              name: item.name,
              category: item.category,
              qty: qty,
              expiresOn: item.expiresOn,
              photoPath: item.photoPath,
              note: item.note,
              icon: item.icon,
              updatedAt: ctx.now(),
            );
      var rest = grown.items;
      if (!whole) {
        rest = [for (final i in rest) i.id == item.id ? i.copyWith(qty: item.qty - qty, updatedAt: ctx.now()) : i];
      }
      data = grown.copyWith(items: [...rest, moved]);
    }
    logs.add(_log(ctx, batch, LogType.move, item, qty, from: item.containerId, to: toContainerId));
  }
  return data.copyWith(log: [...logs.reversed, ...data.log]);
}

/// Drag within a grid: moves to [slot], swapping with whatever is there.
HomeData moveToSlot(HomeData d, Ctx ctx, String itemId, int slot) {
  final item = d.item(itemId)!;
  final other = d.itemsIn(item.containerId).where((i) => i.slot == slot && i.id != itemId).firstOrNull;
  return d.copyWith(
    items: [
      for (final i in d.items)
        if (i.id == itemId)
          i.copyWith(slot: slot, updatedAt: ctx.now())
        else if (other != null && i.id == other.id)
          i.copyWith(slot: item.slot, updatedAt: ctx.now())
        else
          i,
    ],
  );
}

// --------------------------------------------------------------- queries

class Found {
  const Found(this.item, this.path);

  final Item item;
  final List<String> path;
}

/// Items matching [query] by name (with Korean initial consonants), note or
/// container code. Sorted by name.
List<Found> searchItems(HomeData d, String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final codeQ = q.toUpperCase();
  final hits = d.items.where((i) {
    if (matchesQuery(i.name, q) || (i.note.isNotEmpty && matchesQuery(i.note, q))) return true;
    final c = d.container(i.containerId);
    return c != null && c.code.startsWith(codeQ) && codeQ.length >= 3;
  }).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return [for (final i in hits) Found(i, d.pathOf(i.containerId))];
}

/// Items with a use-by date, soonest first, with their status.
List<(Item, ExpiryStatus)> byExpiry(HomeData d, DateTime today) {
  final dated = d.items.where((i) => i.expiresOn != null).toList()..sort((a, b) => a.expiresOn!.compareTo(b.expiresOn!));
  return [for (final i in dated) (i, expiryStatus(today: today, expiresOn: i.expiresOn!))];
}

/// Lent-out spots with a return date, soonest first, with their status.
List<(Storage, ExpiryStatus)> returnsDue(HomeData d, DateTime today) {
  final dated = d.containers.where((c) => c.returnBy != null).toList()..sort((a, b) => a.returnBy!.compareTo(b.returnBy!));
  return [for (final c in dated) (c, expiryStatus(today: today, expiresOn: c.returnBy!))];
}

/// Rooms first, then places outside the home, each in the order added.
List<Space> spacesInOrder(HomeData d) => [...d.spaces.where((s) => !s.outside), ...d.spaces.where((s) => s.outside)];

/// Distinct item names, most recently touched first (for name chips).
List<String> recentNames(HomeData d, {int limit = 8}) {
  final sorted = [...d.items]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final seen = <String>{};
  final out = <String>[];
  for (final i in [...sorted.map((i) => i.name), ...d.log.map((l) => l.itemName)]) {
    if (seen.add(i.toLowerCase())) out.add(i);
    if (out.length >= limit) break;
  }
  return out;
}

/// Containers most recently moved into or added to, for the move sheet.
List<String> recentContainerIds(HomeData d, {int limit = 4}) {
  final out = <String>[];
  for (final l in d.log) {
    final id = l.toContainerId;
    if (id != null && d.container(id) != null && !out.contains(id)) out.add(id);
    if (out.length >= limit) break;
  }
  return out;
}
