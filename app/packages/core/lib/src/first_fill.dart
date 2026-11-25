/// Filling a new home by picking (user request, roadmap 3-1): right after the
/// floor plan, each room offers the spots it usually has, then each spot the
/// things it usually holds, from the short lists in name_ideas.dart. Nothing
/// is typed unless the person wants to ("+ 직접").
library;

import 'icons.dart';
import 'model.dart';
import 'name_ideas.dart';
import 'ops.dart';
import 'plan_draft.dart';
import 'sentence.dart';

bool _inside(Space? s) => s != null && !s.outside && !s.moving;

String? _key(String? icon, String name) => icon ?? iconsFromName(name).firstOrNull;

/// Rooms inside the home, each with the spots it usually has (those already
/// there left out). The first [preselect] of each are the most common.
List<(Space, List<String>)> spotIdeasByRoom(HomeData d, {required bool ko}) => [
  for (final s in d.spaces)
    if (!s.outside && !s.moving)
      (
        s,
        [
          for (final n in (ko ? roomStorageIdeas[_key(s.icon, s.name)]?.$1 : roomStorageIdeas[_key(s.icon, s.name)]?.$2) ?? const <String>[])
            if (!d.containers.any((c) => c.spaceId == s.id && c.name == n)) n,
        ],
      ),
];

/// Spots with things they usually hold (names already there left out).
List<(Storage, List<String>)> thingIdeasBySpot(HomeData d, {required bool ko}) => [
  for (final c in d.containers)
    if (c.parentId == null && _inside(d.space(c.spaceId)))
      (
        c,
        [
          for (final n in (ko ? storageItemIdeas[_key(c.icon, c.name)]?.$1 : storageItemIdeas[_key(c.icon, c.name)]?.$2) ?? const <String>[])
            if (!d.itemsIn(c.id).any((i) => i.name == n)) n,
        ],
      ),
];

/// Adds the picked spots, room by room, as one change; returns how many.
Result<int> addSpots(HomeData d, Ctx ctx, Map<String, List<String>> bySpace) {
  var out = d;
  var n = 0;
  for (final MapEntry(key: spaceId, value: names) in bySpace.entries) {
    for (final name in names) {
      final taken = out.containers.where((c) => c.spaceId == spaceId).map((c) => c.name);
      final r = addContainer(out, ctx, spaceId: spaceId, name: numberedName(name, taken));
      // On the map as furniture, not only a label (user request).
      out = placeOnFloor(r.data, [r.value.id]);
      n++;
    }
  }
  return Result(out, n);
}

/// Adds the picked things, spot by spot, as one change; returns how many.
Result<int> addThings(HomeData d, Ctx ctx, Map<String, List<ParsedItem>> bySpot) {
  var out = d;
  var n = 0;
  for (final MapEntry(key: spot, value: items) in bySpot.entries) {
    if (items.isEmpty || out.container(spot) == null) continue;
    out = addItemsFromSentence(out, ctx, spot, items).data;
    n += items.length;
  }
  return Result(out, n);
}
