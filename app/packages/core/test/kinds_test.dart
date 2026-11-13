import 'dart:convert';

import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  late Ctx ctx;
  late HomeData d;
  late String living;
  late String veranda;

  setUp(() {
    var n = 0;
    ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 10, 28));
    final a = addSpace(const HomeData(), ctx, '거실');
    final b = addSpace(a.data, ctx, '베란다');
    d = b.data;
    living = a.value.id;
    veranda = b.value.id;
  });

  test('furniture is made with its sections, top to bottom', () {
    final r = addFurniture(d, ctx, spaceId: living, name: 'TV장', sections: ['윗칸', ' 왼쪽 서랍 ', '', '아래 칸']);
    expect(r.value.kind, StorageKind.furniture);
    expect(sectionsOf(r.data, r.value.id).map((s) => s.name), ['윗칸', '왼쪽 서랍', '아래 칸']);
    expect(holdsItems(r.data, r.value), isFalse);
    expect(placesIn(r.data, living).map((s) => s.name), ['윗칸', '왼쪽 서랍', '아래 칸']);
    expect(r.data.pathOf(sectionsOf(r.data, r.value.id)[1].id), ['거실', 'TV장', '왼쪽 서랍']);
  });

  test('furniture without sections holds things itself', () {
    final r = addFurniture(d, ctx, spaceId: living, name: '선반', sections: []);
    expect(holdsItems(r.data, r.value), isTrue);
  });

  test('boxes are numbered in order across the home', () {
    final a = addBox(d, ctx, spaceId: living, name: '상자 1');
    final b = addBox(a.data, ctx, spaceId: veranda, name: '상자 2 · 캠핑');
    expect([a.value.number, b.value.number], [1, 2]);
    expect(nextBoxNumber(b.data), 3);
  });

  test('a box moves with everything in it, boxes inside too', () {
    final f = addFurniture(d, ctx, spaceId: veranda, name: '창고장', sections: ['윗칸']);
    final shelf = sectionsOf(f.data, f.value.id).single;
    final box = addBox(f.data, ctx, spaceId: living, name: '캠핑');
    final inner = addBox(box.data, ctx, spaceId: living, name: '랜턴', parentId: box.value.id);
    var data = addItem(inner.data, ctx, containerId: box.value.id, name: '텐트').data;
    data = addItem(data, ctx, containerId: inner.value.id, name: '건전지').data;

    expect(canMoveContainer(data, box.value.id, f.value.id), isFalse); // pick a section
    expect(canMoveContainer(data, box.value.id, inner.value.id), isFalse); // not into itself
    expect(canMoveContainer(data, shelf.id, null), isFalse); // sections stay put
    expect(canMoveContainer(data, box.value.id, shelf.id), isTrue);

    data = moveContainer(data, box.value.id, spaceId: veranda, parentId: shelf.id);
    expect(data.pathOf(box.value.id), ['베란다', '창고장', '윗칸', '캠핑']);
    expect(data.pathOf(inner.value.id), ['베란다', '창고장', '윗칸', '캠핑', '랜턴']);
    expect(data.container(inner.value.id)!.spaceId, veranda);
    expect(data.container(box.value.id)!.code, startsWith(shelf.code));
    expect(data.itemsIn(inner.value.id).single.name, '건전지');
    expect(itemCountUnder(data, f.value.id), 2);
    expect(searchItems(data, '건전지').single.path, ['베란다', '창고장', '윗칸', '캠핑', '랜턴']);

    data = moveContainer(data, box.value.id, spaceId: living);
    expect(data.container(box.value.id)!.parentId, isNull);
    expect(floorBoxes(data, living).single.id, box.value.id);
  });

  test('kind and number survive saving; old data reads as spots', () {
    final r = addBox(d, ctx, spaceId: living, name: '상자 1');
    final back = HomeData.fromJson(jsonDecode(jsonEncode(r.data.toJson())) as Map<String, Object?>);
    expect(back.container(r.value.id)!.kind, StorageKind.box);
    expect(back.container(r.value.id)!.number, 1);
    final old = Storage.fromJson({'id': 'x', 'spaceId': living, 'name': '서랍', 'code': 'LIV-A'});
    expect(old.kind, StorageKind.spot);
  });

  test('the last change groups one sentence of things put away', () {
    expect(lastChange(d), isNull);
    final box = addBox(d, ctx, spaceId: living, name: '상자 1');
    final r = addItemsFromSentence(box.data, ctx, box.value.id, parseItemSentence('가위, 테이프랑 풀'));
    final c = lastChange(r.data)!;
    expect(c.type, LogType.add);
    expect(c.names, ['풀', '테이프', '가위']);
    expect(c.containerId, box.value.id);
  });

  test('sections set in one go: renamed, added, reordered, removed without losing things', () {
    var n = 0;
    final ctx = Ctx(newId: () => 's${n++}', now: () => DateTime(2026, 11, 13));
    final room = addSpace(const HomeData(), ctx, '거실');
    final tv = addFurniture(room.data, ctx, spaceId: room.value.id, name: 'TV장', sections: ['윗칸', '가운데 칸', '아랫칸']);
    var d = tv.data;
    final secs = d.childrenOf(tv.value.id);
    d = addItem(d, ctx, containerId: secs[1].id, name: '건전지').data;
    d = addItem(d, ctx, containerId: secs[0].id, name: '리모컨').data;
    final out = setSections(d, ctx, tv.value.id, [(id: secs[2].id, name: '아랫서랍'), (id: secs[0].id, name: '윗칸'), (id: null, name: '4번째 칸')]);
    final now = out.childrenOf(tv.value.id);
    expect(now.map((s) => s.name), ['아랫서랍', '윗칸', '4번째 칸']);
    expect(now.first.id, secs[2].id); // the same section, renamed: its code and things stay
    // The batteries were in the removed middle section: now in the first one, not lost.
    final batteries = out.items.singleWhere((i) => i.name == '건전지');
    expect(batteries.containerId, secs[2].id);
    expect(out.items.singleWhere((i) => i.name == '리모컨').containerId, secs[0].id);
    // Nothing left means nothing changes; a blank name keeps the old one.
    expect(setSections(out, ctx, tv.value.id, const []).childrenOf(tv.value.id).length, 3);
    expect(setSections(out, ctx, tv.value.id, [(id: secs[0].id, name: '  ')]).childrenOf(tv.value.id).single.name, '윗칸');
  });
}
