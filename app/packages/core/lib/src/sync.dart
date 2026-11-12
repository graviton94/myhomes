/// Shared homes (v0.8): the home is stored as one document per space,
/// storage spot, item and log entry, so two phones editing different
/// things never overwrite each other. These rules turn a change on the
/// phone into document writes, and documents back into [HomeData].
library;

import 'model.dart';

/// [toBuy] is stored as "buy" (the hand-added shopping list).
enum Shelf { spaces, containers, items, log, buy }

/// One document to write ([data]) or delete (null).
class DocWrite {
  const DocWrite(this.shelf, this.id, this.data);

  final Shelf shelf;
  final String id;
  final Map<String, Object?>? data;

  @override
  String toString() => 'DocWrite(${shelf.name}/$id, ${data == null ? 'delete' : 'set'})';
}

/// Field that keeps the order things were made in (lists on screen follow it).
const orderField = '_o';

/// Documents that differ between [before] and [after]. Log entries are only
/// ever added.
List<DocWrite> diffHome(HomeData before, HomeData after) {
  final out = <DocWrite>[];
  void shelf<T>(Shelf s, List<T> a, List<T> b, String Function(T) id, Map<String, Object?> Function(T) json) {
    final old = {for (final x in a) id(x): x};
    final seen = <String>{};
    for (final x in b) {
      final k = id(x);
      seen.add(k);
      final was = old[k];
      if (was == null || !_sameJson(json(was), json(x))) out.add(DocWrite(s, k, json(x)));
    }
    for (final k in old.keys) {
      if (!seen.contains(k)) out.add(DocWrite(s, k, null));
    }
  }

  shelf<Space>(Shelf.spaces, before.spaces, after.spaces, (x) => x.id, (x) => x.toJson());
  shelf<Storage>(Shelf.containers, before.containers, after.containers, (x) => x.id, (x) => x.toJson());
  shelf<Item>(Shelf.items, before.items, after.items, (x) => x.id, (x) => x.toJson());
  shelf<ToBuy>(Shelf.buy, before.toBuy, after.toBuy, (x) => x.id, (x) => x.toJson());
  final logged = {for (final e in before.log) e.id};
  for (final e in after.log.reversed) {
    if (!logged.contains(e.id)) out.add(DocWrite(Shelf.log, e.id, e.toJson()));
  }
  return out;
}

/// Things whose amount is the only difference between [before] and [after]
/// (id → how many more or fewer). A shared home sends these as "add this
/// many" rather than "is now this many", so two phones changing the same
/// amount at once both count.
Map<String, int> countChanges(HomeData before, HomeData after) {
  final old = {for (final i in before.items) i.id: i};
  final out = <String, int>{};
  for (final i in after.items) {
    final was = old[i.id];
    if (was == null || was.qty == i.qty) continue;
    final a = {...was.toJson()}
      ..remove('qty')
      ..remove('updatedAt');
    final b = {...i.toJson()}
      ..remove('qty')
      ..remove('updatedAt');
    if (_sameJson(a, b)) out[i.id] = i.qty - was.qty;
  }
  return out;
}

/// Every document needed to put [d] into an empty shared home.
List<DocWrite> uploadHome(HomeData d) => diffHome(const HomeData(), d);

/// The home from its documents. Spaces, spots and items follow [orderField];
/// the log is newest first.
HomeData homeFromDocs({
  required Iterable<Map<String, Object?>> spaces,
  required Iterable<Map<String, Object?>> containers,
  required Iterable<Map<String, Object?>> items,
  required Iterable<Map<String, Object?>> log,
  Iterable<Map<String, Object?>> buy = const [],
}) {
  List<Map<String, Object?>> ordered(Iterable<Map<String, Object?>> docs) => docs.toList()
    ..sort((a, b) {
      final c = ((a[orderField] as num?) ?? 0).compareTo((b[orderField] as num?) ?? 0);
      return c != 0 ? c : (a['id'] as String).compareTo(b['id'] as String);
    });
  final entries = log.map(LogEntry.fromJson).toList()..sort((a, b) => b.at.compareTo(a.at));
  return HomeData(
    spaces: ordered(spaces).map(Space.fromJson).toList(),
    containers: ordered(containers).map(Storage.fromJson).toList(),
    // A thing deleted on one phone while another changed its amount leaves
    // a stub with no name; it is not a thing.
    items: ordered(items)
        .where((j) => j['name'] is String)
        // Two people took the last one at the same moment: none are left, not minus one.
        .map((j) => (j['qty'] as num? ?? 0) < 0 ? {...j, 'qty': 0} : j)
        .map(Item.fromJson)
        .toList(),
    log: entries,
    toBuy: buy.map(ToBuy.fromJson).toList()..sort((a, b) => a.addedAt.compareTo(b.addedAt)),
  );
}

bool _sameJson(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !_sameJson(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameJson(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Undo in a home others also change: takes back only what the change
/// touched. [before] and [after] are the home around the change being
/// undone; [current] is the home now, which may hold the family's newer
/// changes. Things the change added go, things it removed or edited return
/// as they were; everything else stays as it is now.
HomeData revertChange(HomeData current, HomeData before, HomeData after) {
  if (identical(current, after)) return before;
  List<T> shelf<T>(List<T> now, List<T> was, List<T> then, String Function(T) id, Map<String, Object?> Function(T) json) {
    final old = {for (final x in was) id(x): x};
    final made = {for (final x in then) id(x): x};
    // What the change touched: ids whose document differs across it.
    final touched = <String>{
      for (final k in {...old.keys, ...made.keys})
        if (old[k] == null || made[k] == null || !_sameJson(json(old[k] as T), json(made[k] as T))) k,
    };
    final out = <T>[];
    final kept = <String>{};
    for (final x in now) {
      final k = id(x);
      if (!touched.contains(k)) {
        out.add(x);
      } else if (old[k] != null) {
        out.add(old[k] as T);
        kept.add(k);
      }
    }
    // Removed by the change (or by someone since): back where the list ends.
    for (final x in was) {
      final k = id(x);
      if (touched.contains(k) && !kept.contains(k)) out.add(x);
    }
    return out;
  }

  final logged = {for (final e in before.log) e.id};
  final added = {
    for (final e in after.log)
      if (!logged.contains(e.id)) e.id,
  };
  return HomeData(
    spaces: shelf<Space>(current.spaces, before.spaces, after.spaces, (x) => x.id, (x) => x.toJson()),
    containers: shelf<Storage>(current.containers, before.containers, after.containers, (x) => x.id, (x) => x.toJson()),
    items: shelf<Item>(current.items, before.items, after.items, (x) => x.id, (x) => x.toJson()),
    log: [
      for (final e in current.log)
        if (!added.contains(e.id)) e,
    ],
    toBuy: shelf<ToBuy>(current.toBuy, before.toBuy, after.toBuy, (x) => x.id, (x) => x.toJson()),
  );
}
