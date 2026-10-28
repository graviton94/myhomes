import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('same-named rooms and storage become one; the rest is added and things add up', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 10, 28), by: 'me');

    // Our home: 주방 › 냉장고 with 우유 2.
    var home = addSpace(const HomeData(), ctx, '주방').data;
    home = addContainer(home, ctx, spaceId: home.spaces.single.id, name: '냉장고').data;
    home = addItem(home, ctx, containerId: home.containers.single.id, name: '우유', qty: 2).data;

    // My phone: 주방 › 냉장고 with 우유 1 and 달걀 10, and 거실 › TV장 (with a section) › 리모컨.
    var phone = addSpace(const HomeData(), ctx, ' 주방 ').data;
    final kitchen = phone.spaces.single.id;
    phone = addContainer(phone, ctx, spaceId: kitchen, name: '냉장고').data;
    final fridge = phone.containers.single.id;
    phone = addItem(phone, ctx, containerId: fridge, name: '우유', qty: 1).data;
    phone = addItem(phone, ctx, containerId: fridge, name: '달걀', qty: 10).data;
    final living = addSpace(phone, ctx, '거실');
    final tv = addFurniture(living.data, ctx, spaceId: living.value.id, name: 'TV장', sections: ['윗칸']);
    phone = tv.data;
    final shelf = sectionsOf(phone, tv.value.id).single.id;
    phone = addItem(phone, ctx, containerId: shelf, name: '리모컨').data;

    final r = mergeHome(home, phone, ctx);
    final d = r.data;
    expect(r.value, 12);
    expect(d.spaces.map((s) => s.name), ['주방', '거실']);
    final homeFridge = d.containers.firstWhere((c) => c.name == '냉장고');
    expect(d.containers.where((c) => c.name == '냉장고').length, 1);
    expect({for (final i in d.itemsIn(homeFridge.id)) i.name: i.qty}, {'우유': 3, '달걀': 10});
    final newShelf = d.containers.firstWhere((c) => c.name == '윗칸');
    expect(d.container(newShelf.parentId!)!.name, 'TV장');
    expect(d.itemsIn(newShelf.id).single.name, '리모컨');
    expect(d.log.first.by, 'me');
  });
}
