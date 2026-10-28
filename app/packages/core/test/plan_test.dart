import 'dart:convert';

import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  late Ctx ctx;
  setUp(() {
    var n = 0;
    ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 10, 28));
  });

  String ko(String k) => {'living': '거실', 'kitchen': '주방', 'master': '안방'}[k] ?? k;

  test('templates have rooms inside their size that never overlap', () {
    for (final t in houseTemplates) {
      for (final (i, a) in t.rooms.indexed) {
        expect(a.rect.right <= t.cols && a.rect.bottom <= t.rows, isTrue, reason: '${t.id} ${a.key}');
        for (final b in t.rooms.skip(i + 1)) {
          expect(a.rect.overlaps(b.rect), isFalse, reason: '${t.id} ${a.key}/${b.key}');
        }
        expect(templateRoomIcons.containsKey(a.key), isTrue);
      }
    }
  });

  test('a template places existing rooms by name and adds the rest', () {
    final living = addSpace(const HomeData(), ctx, '거실');
    final car = addSpace(living.data, ctx, '거실', outside: true);
    final d = applyTemplate(car.data, ctx, houseTemplates.first, ko);
    expect(d.space(living.value.id)!.plan, const PlanRect(6, 7, 9, 9));
    expect(d.space(car.value.id)!.plan, isNull); // outside places stay off the plan
    expect(plannedRooms(d).length, houseTemplates.first.rooms.length);
    expect(planSize(d), (22, 19));
    expect(d.spaces.where((s) => s.name == '주방').single.icon, 'kitchen');
  });

  test('room plans are kept at least 1 m and survive saving', () {
    final r = addSpace(const HomeData(), ctx, '방');
    var d = setRoomPlan(r.data, r.value.id, const PlanRect(-1, 2, 1, 0));
    expect(d.space(r.value.id)!.plan, const PlanRect(0, 2, 2, 2));
    final back = HomeData.fromJson(jsonDecode(jsonEncode(d.toJson())) as Map<String, Object?>);
    expect(back.space(r.value.id)!.plan, const PlanRect(0, 2, 2, 2));
    d = setRoomPlan(d, r.value.id, null);
    expect(d.space(r.value.id)!.plan, isNull);
  });

  test('a new room goes to a free spot', () {
    final d = applyTemplate(const HomeData(), ctx, houseTemplates.last, ko);
    final spot = freePlanSpot(d, w: 4, h: 4);
    expect(plannedRooms(d).any((s) => s.plan!.overlaps(spot)), isFalse);
  });

  test('furniture stands inside its room, finds free floor, and loses its spot when moved', () {
    var d = addSpace(const HomeData(), ctx, '거실').data;
    final room = d.spaces.single.id;
    d = setRoomPlan(d, room, const PlanRect(0, 0, 6, 4));
    final tv = addFurniture(d, ctx, spaceId: room, name: 'TV장', sections: ['윗칸']);
    d = setStoragePlan(tv.data, tv.value.id, const PlanRect(5, 3, 3, 2));
    expect(d.container(tv.value.id)!.plan, const PlanRect(3, 2, 3, 2)); // pushed back inside 6 x 4
    expect(Storage.fromJson(d.container(tv.value.id)!.toJson()).plan, const PlanRect(3, 2, 3, 2));
    final spot = freeStorageSpot(d, room, w: 3, h: 2);
    expect(spot.overlaps(const PlanRect(3, 2, 3, 2)), isFalse);
    final box = addBox(d, ctx, spaceId: room, name: '상자 1');
    d = setStoragePlan(box.data, box.value.id, spot);
    final other = addSpace(d, ctx, '침실');
    d = moveContainer(other.data, box.value.id, spaceId: other.value.id);
    expect(d.container(box.value.id)!.plan, isNull);
  });
}
