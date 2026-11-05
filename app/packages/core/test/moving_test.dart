import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('a move: pack into numbered boxes, find them, unpack, finish', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'm${n++}', now: () => DateTime(2026, 11, 5));
    final kitchen = addSpace(const HomeData(), ctx, '주방');
    final drawer = addContainer(kitchen.data, ctx, spaceId: kitchen.value.id, name: '서랍');
    var d = drawer.data;
    d = addItem(d, ctx, containerId: drawer.value.id, name: '식칼').data;
    d = addItem(d, ctx, containerId: drawer.value.id, name: '도마', qty: 2).data;
    final knife = d.items.firstWhere((i) => i.name == '식칼');
    final board = d.items.firstWhere((i) => i.name == '도마');

    expect(movingSpace(d), isNull);
    final start = startMoving(d, ctx, '이사 박스');
    d = start.data;
    expect(start.value.moving, isTrue);
    expect(start.value.outside, isTrue);
    expect(startMoving(d, ctx, '이사 박스').value.id, start.value.id); // only one move at a time

    final b1 = addMovingBox(d, ctx, '상자 1');
    d = b1.data;
    final b2 = addMovingBox(d, ctx, '상자 2');
    d = b2.data;
    expect([for (final b in movingBoxes(d)) b.number], [1, 2]);
    d = setGoesTo(d, b1.value.id, '주방');
    expect(d.container(b1.value.id)!.goesTo, '주방');

    // Packing is moving.
    d = moveItems(d, ctx, {knife.id: 1, board.id: 2}, b1.value.id);
    expect(d.itemsIn(b1.value.id), hasLength(2));
    expect(boxesToUnpack(d).map((b) => b.id), [b1.value.id]); // the empty box 2 waits for nothing
    expect(d.pathOf(d.items.firstWhere((i) => i.name == '식칼').containerId), ['이사 박스', '상자 1']);

    // Survives saving.
    final again = HomeData.fromJson(d.toJson());
    expect(again.container(b1.value.id)!.goesTo, '주방');
    expect(movingSpace(again)!.moving, isTrue);

    // Unpack one thing: not done yet; the other: the box is unpacked.
    d = unpack(d, ctx, b1.value.id, {d.items.firstWhere((i) => i.name == '식칼').id: 1}, drawer.value.id);
    expect(d.container(b1.value.id)!.unpacked, isFalse);
    d = unpack(d, ctx, b1.value.id, {d.items.firstWhere((i) => i.name == '도마').id: 2}, drawer.value.id);
    expect(d.container(b1.value.id)!.unpacked, isTrue);
    expect(movingProgress(d), (done: 1, total: 2));
    expect(boxesToUnpack(d), isEmpty);

    // Finishing removes the boxes and, if asked, empty spots.
    final empty = addContainer(d, ctx, spaceId: kitchen.value.id, name: '빈 선반');
    d = finishMoving(empty.data, clearEmpty: true);
    expect(movingSpace(d), isNull);
    expect(d.container(empty.value.id), isNull);
    expect(d.container(drawer.value.id), isNotNull);
    expect(d.items, hasLength(2));
  });

  test('a box put down whole leaves the move with its things', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'p${n++}', now: () => DateTime(2026, 11, 5));
    final room = addSpace(const HomeData(), ctx, '안방');
    var d = startMoving(room.data, ctx, '이사 박스').data;
    final box = addMovingBox(d, ctx, '상자 1');
    d = addItem(box.data, ctx, containerId: box.value.id, name: '이불').data;
    d = setGoesTo(d, box.value.id, '안방');
    d = placeBox(d, box.value.id, spaceId: room.value.id);
    expect(movingBoxes(d), isEmpty);
    expect(d.container(box.value.id)!.spaceId, room.value.id);
    expect(d.container(box.value.id)!.goesTo, isNull);
    expect(d.itemsIn(box.value.id), hasLength(1));
  });
}
