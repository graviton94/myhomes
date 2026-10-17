import 'dart:convert';

import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  late Ctx ctx;
  late HomeData d;
  late String drawer;
  late String shoes;

  setUp(() {
    var n = 0;
    ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 10, 15, 9));
    final s = addSpace(const HomeData(), ctx, 'Living room');
    final a = addContainer(s.data, ctx, spaceId: s.value.id, name: 'Left drawer');
    final e = addSpace(a.data, ctx, '현관');
    final b = addContainer(e.data, ctx, spaceId: e.value.id, name: '신발장');
    d = b.data;
    drawer = a.value.id;
    shoes = b.value.id;
  });

  test('codes follow space prefix and order', () {
    expect(d.container(drawer)!.code, 'LIV-A1');
    expect(d.container(shoes)!.code, 'SP1-A1');
    final child = addContainer(d, ctx, spaceId: d.container(drawer)!.spaceId, name: 'Box', parentId: drawer);
    expect(child.value.code, 'LIV-A1-1');
    expect(child.data.pathOf(child.value.id), ['Living room', 'Left drawer', 'Box']);
  });

  test('add uses the asked slot, else the first free one', () {
    var r = addItem(d, ctx, containerId: drawer, name: 'AA batteries', slot: 1, qty: 12);
    expect(r.value.slot, 1);
    r = addItem(r.data, ctx, containerId: drawer, name: 'Scissors', slot: 1);
    expect(r.value.slot, 0);
    r = addItem(r.data, ctx, containerId: drawer, name: 'Tape');
    expect(r.value.slot, 2);
    r = addItem(r.data, ctx, containerId: drawer, name: 'Glue', slot: 9);
    expect(r.value.slot, 9);
    expect(freeSlot(r.data, drawer), 3);
    expect(r.data.log.first.type, LogType.add);
  });

  test('adjustQty removes the item at zero and logs used up', () {
    final r = addItem(d, ctx, containerId: drawer, name: 'Milk', qty: 1);
    final after = adjustQty(r.data, ctx, r.value.id, -1);
    expect(after.items, isEmpty);
    expect(after.log.first.type, LogType.usedUp);
    final plus = adjustQty(r.data, ctx, r.value.id, 2);
    expect(plus.item(r.value.id)!.qty, 3);
  });

  test('moving part of a stack splits it; same kind merges at the destination', () {
    var r = addItem(d, ctx, containerId: drawer, name: 'AA batteries', qty: 12);
    final batteries = r.value.id;
    r = addItem(r.data, ctx, containerId: shoes, name: 'aa batteries ', qty: 2);
    final moved = moveItems(r.data, ctx, {batteries: 4}, shoes);
    expect(moved.item(batteries)!.qty, 8);
    expect(moved.itemsIn(shoes).single.qty, 6);
    expect(moved.log.first.type, LogType.move);
    expect(moved.log.first.qty, 4);
  });

  test('moving a whole stack relocates it and keeps its id', () {
    final r = addItem(d, ctx, containerId: drawer, name: 'Flashlight');
    final moved = moveItems(r.data, ctx, {r.value.id: 1}, shoes, toSlot: 5);
    expect(moved.item(r.value.id)!.containerId, shoes);
    expect(moved.item(r.value.id)!.slot, 5);
  });

  test('batch take-out shares one batch id', () {
    var r = addItem(d, ctx, containerId: drawer, name: 'Bandages', qty: 20);
    final band = r.value.id;
    r = addItem(r.data, ctx, containerId: drawer, name: 'Cream', qty: 2);
    final out = useItems(r.data, ctx, {band: 5, r.value.id: 2});
    expect(out.item(band)!.qty, 15);
    expect(out.item(r.value.id), isNull);
    expect(out.log[0].batchId, out.log[1].batchId);
  });

  test('moveToSlot swaps with an occupied cell', () {
    var r = addItem(d, ctx, containerId: drawer, name: 'A', slot: 0);
    final a = r.value.id;
    r = addItem(r.data, ctx, containerId: drawer, name: 'B', slot: 1);
    final swapped = moveToSlot(r.data, ctx, a, 1);
    expect(swapped.item(a)!.slot, 1);
    expect(swapped.item(r.value.id)!.slot, 0);
  });

  test('search by initials, note and code', () {
    var r = addItem(d, ctx, containerId: drawer, name: '건전지 AA', qty: 8);
    r = addItem(r.data, ctx, containerId: shoes, name: 'Umbrella', note: 'big blue one');
    expect(searchItems(r.data, 'ㄱㅈ').single.path, ['Living room', 'Left drawer']);
    expect(searchItems(r.data, 'blue').single.item.name, 'Umbrella');
    expect(searchItems(r.data, 'liv-a1').length, 1);
  });

  test('deleting a space removes its containers and items', () {
    final r = addItem(d, ctx, containerId: drawer, name: 'X');
    final gone = deleteSpace(r.data, r.data.container(drawer)!.spaceId);
    expect(gone.items, isEmpty);
    expect(gone.container(drawer), isNull);
  });

  test('JSON round trip', () {
    final r = addItem(d, ctx, containerId: drawer, name: 'Milk', category: ItemCategory.food, expiresOn: DateTime(2026, 10, 16));
    final back = HomeData.fromJson(jsonDecode(jsonEncode(r.data.toJson())) as Map<String, Object?>);
    expect(back.items.single.expiresOn, DateTime(2026, 10, 16));
    expect(back.items.single.category, ItemCategory.food);
    expect(back.containers.length, 2);
    expect(back.log.length, r.data.log.length);
  });

  test('byExpiry sorts soonest first; recent names are distinct', () {
    var r = addItem(d, ctx, containerId: drawer, name: 'Tofu', expiresOn: DateTime(2026, 10, 18));
    r = addItem(r.data, ctx, containerId: drawer, name: 'Milk', expiresOn: DateTime(2026, 10, 16));
    final list = byExpiry(r.data, DateTime(2026, 10, 15));
    expect(list.first.$1.name, 'Milk');
    expect(list.first.$2.level, ExpiryLevel.tomorrow);
    expect(recentNames(r.data).toSet(), {'Tofu', 'Milk'});
  });

  test('grid length covers used squares plus one free, in whole rows', () {
    expect(gridLength(d, drawer, 4), 4);
    var r = addItem(d, ctx, containerId: drawer, name: 'A', slot: 3);
    expect(gridLength(r.data, drawer, 4), 8);
    r = addItem(r.data, ctx, containerId: drawer, name: 'B', slot: 6);
    expect(gridLength(r.data, drawer, 4), 8);
    expect(gridLength(r.data, drawer, 5), 10);
  });

  test('space and storage photos can be set and cleared', () {
    final sp = d.container(drawer)!.spaceId;
    var x = updateSpace(d, sp, photoPath: '/p/room.jpg');
    expect(x.space(sp)!.photoPath, '/p/room.jpg');
    x = updateSpace(x, sp, name: 'Den');
    expect(x.space(sp)!.photoPath, '/p/room.jpg');
    x = updateContainer(x, drawer, photoPath: '/p/drawer.jpg');
    expect(HomeData.fromJson(jsonDecode(jsonEncode(x.toJson())) as Map<String, Object?>).container(drawer)!.photoPath, '/p/drawer.jpg');
    x = updateContainer(x, drawer, clearPhoto: true);
    expect(x.container(drawer)!.photoPath, isNull);
  });

  test('places outside the home sort after rooms; lent spots have return dates', () {
    final car = addSpace(d, ctx, '자동차', outside: true);
    var x = car.data;
    expect(spacesInOrder(x).last.outside, isTrue);
    expect(spacesInOrder(x).first.outside, isFalse);
    final lent = addContainer(x, ctx, spaceId: car.value.id, name: '민수', returnBy: DateTime(2026, 10, 18));
    x = lent.data;
    final due = returnsDue(x, DateTime(2026, 10, 15));
    expect(due.single.$1.name, '민수');
    expect(due.single.$2.daysLeft, 3);
    final round = HomeData.fromJson(jsonDecode(jsonEncode(x.toJson())) as Map<String, Object?>);
    expect(round.space(car.value.id)!.outside, isTrue);
    expect(round.container(lent.value.id)!.returnBy, DateTime(2026, 10, 18));
    x = updateContainer(x, lent.value.id, clearReturnBy: true);
    expect(returnsDue(x, DateTime(2026, 10, 15)), isEmpty);
  });
}
