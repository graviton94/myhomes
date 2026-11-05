/// Moving home: numbered boxes in one "이사 박스" space outside the home.
/// Packing moves things into a box; in the new home a box is unpacked thing
/// by thing (each gets its place) or put down whole in a room. Started only
/// by the person; nothing here suggests it.
library;

import 'kinds.dart';
import 'model.dart';
import 'ops.dart';

/// The moving boxes' space, if a move is on.
Space? movingSpace(HomeData d) => d.spaces.where((s) => s.moving).firstOrNull;

/// Starts a move: the space for the boxes ([name]: "이사 박스").
Result<Space> startMoving(HomeData d, Ctx ctx, String name) {
  final on = movingSpace(d);
  if (on != null) return Result(d, on);
  return addSpace(d, ctx, name, icon: 'box', moving: true);
}

/// The boxes of the move, by number.
List<Storage> movingBoxes(HomeData d) {
  final s = movingSpace(d);
  if (s == null) return const [];
  return d.containersIn(s.id).where((c) => c.kind == StorageKind.box).toList()..sort((a, b) => (a.number ?? 0).compareTo(b.number ?? 0));
}

/// A new box; [name] is the app's "상자 {n}" for [nextBoxNumber].
Result<Storage> addMovingBox(HomeData d, Ctx ctx, String name) {
  final s = movingSpace(d);
  if (s == null) throw StateError('no move');
  return addBox(d, ctx, spaceId: s.id, name: name);
}

/// The room a box goes to in the new home (null: not decided).
HomeData setGoesTo(HomeData d, String boxId, String? room) => d.copyWith(
  containers: [
    for (final c in d.containers) c.id == boxId ? c.copyWith(goesTo: room, clearGoesTo: room == null || room.trim().isEmpty) : c,
  ],
);

/// Whether [c] is a box of the move.
bool isMovingBox(HomeData d, Storage c) => c.kind == StorageKind.box && (d.space(c.spaceId)?.moving ?? false);

/// Things out of box [boxId] into their new place; the box is unpacked once empty.
HomeData unpack(HomeData d, Ctx ctx, String boxId, Map<String, int> picks, String toContainerId) {
  final out = moveItems(d, ctx, picks, toContainerId);
  final empty = out.itemsIn(boxId).isEmpty && out.childrenOf(boxId).isEmpty;
  if (!empty) return out;
  return out.copyWith(containers: [for (final c in out.containers) c.id == boxId ? c.copyWith(unpacked: true) : c]);
}

/// How far the unpacking is: boxes done of all.
({int done, int total}) movingProgress(HomeData d) {
  final boxes = movingBoxes(d);
  return (done: boxes.where((b) => b.unpacked).length, total: boxes.length);
}

/// Boxes still holding things (not unpacked yet).
List<Storage> boxesToUnpack(HomeData d) => [
  for (final b in movingBoxes(d))
    if (!b.unpacked && (d.itemsIn(b.id).isNotEmpty || d.childrenOf(b.id).isNotEmpty)) b,
];

/// Puts box [boxId] down whole in the new home ([spaceId], optionally into
/// [parentId]): it leaves the move as it is, things and all.
HomeData placeBox(HomeData d, String boxId, {required String spaceId, String? parentId}) =>
    setGoesTo(moveContainer(d, boxId, spaceId: spaceId, parentId: parentId), boxId, null);

/// Ends the move: removes the boxes' space, and with [clearEmpty] every spot
/// in the home that holds nothing (the old home's empty places).
HomeData finishMoving(HomeData d, {bool clearEmpty = false}) {
  final s = movingSpace(d);
  var out = s == null ? d : deleteSpace(d, s.id);
  if (!clearEmpty) return out;
  bool holds(String id) => out.itemsIn(id).isNotEmpty || out.childrenOf(id).any((c) => holds(c.id));
  final keep = {
    for (final c in out.containers)
      if (holds(c.id)) c.id,
  };
  return out.copyWith(
    containers: [
      for (final c in out.containers)
        if (keep.contains(c.id)) c,
    ],
  );
}
