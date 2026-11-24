import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  var n = 0;
  final ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 11, 24));

  test('rooms offer their usual spots; spots their usual things', () {
    final k = addSpace(const HomeData(), ctx, '주방', icon: 'kitchen');
    final l = addSpace(k.data, ctx, '거실', icon: 'living');
    final car = addSpace(l.data, ctx, '차', icon: 'car', outside: true);
    var d = car.data;
    final rooms = spotIdeasByRoom(d, ko: true);
    expect(rooms.map((r) => r.$1.name), ['주방', '거실']);
    expect(rooms.first.$2.take(2), ['냉장고', '냉동실']);

    final spots = addSpots(d, ctx, {k.value.id: ['냉장고', '싱크대 아래'], l.value.id: ['TV장', '소파 옆']});
    expect(spots.value, 4);
    d = spots.data;
    final fridge = d.containers.firstWhere((c) => c.name == '냉장고');
    final things = thingIdeasBySpot(d, ko: true);
    expect(things.firstWhere((t) => t.$1.id == fridge.id).$2, contains('우유'));

    final put = addThings(d, ctx, {fridge.id: [const ParsedItem('우유', 1), const ParsedItem('계란', 2)]});
    expect(put.value, 2);
    expect(put.data.itemsIn(fridge.id).map((i) => (i.name, i.qty)), [('우유', 1), ('계란', 2)]);
    // What is there is not offered again.
    expect(thingIdeasBySpot(put.data, ko: true).firstWhere((t) => t.$1.id == fridge.id).$2, isNot(contains('우유')));
    expect(spotIdeasByRoom(put.data, ko: true).first.$2, isNot(contains('냉장고')));
  });

  test('a spot picked twice gets a number', () {
    final k = addSpace(const HomeData(), ctx, '거실', icon: 'living');
    final r = addSpots(k.data, ctx, {k.value.id: ['선반', '선반']});
    expect(r.data.containers.map((c) => c.name), ['선반', '선반 2']);
  });
}
