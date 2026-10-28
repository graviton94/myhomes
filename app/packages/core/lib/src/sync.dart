/// Shared homes (v0.8): the home is stored as one document per space,
/// storage spot, item and log entry, so two phones editing different
/// things never overwrite each other. These rules turn a change on the
/// phone into document writes, and documents back into [HomeData].
library;

import 'model.dart';

enum Shelf { spaces, containers, items, log }

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
  final logged = {for (final e in before.log) e.id};
  for (final e in after.log.reversed) {
    if (!logged.contains(e.id)) out.add(DocWrite(Shelf.log, e.id, e.toJson()));
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
    items: ordered(items).map(Item.fromJson).toList(),
    log: entries,
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
