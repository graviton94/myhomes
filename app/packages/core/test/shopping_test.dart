import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  late Ctx ctx;
  late HomeData d;
  late String fridge, shelf, tofu;
  setUp(() {
    var n = 0;
    ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 11, 5, 10, n));
    final s = addSpace(const HomeData(), ctx, '주방');
    final f = addContainer(s.data, ctx, spaceId: s.value.id, name: '냉장고');
    final sh = addContainer(f.data, ctx, spaceId: s.value.id, name: '선반');
    fridge = f.value.id;
    shelf = sh.value.id;
    final t = addItem(sh.data, ctx, containerId: fridge, name: '두부', category: ItemCategory.food);
    tofu = t.value.id;
    d = addItem(t.data, ctx, containerId: shelf, name: '키친타월', category: ItemCategory.household, qty: 0, minQty: 2).data;
  });

  test('the list: hand-added lines, then things running low', () {
    d = addToBuy(d, ctx, '두부', qty: 2);
    d = addToBuy(d, ctx, '두부');
    d = addToBuy(d, ctx, 'AA 건전지', qty: 4);
    final list = shoppingList(d);
    expect(list.map((l) => '${l.name} ${l.qty}'), ['두부 3', 'AA 건전지 4', '키친타월 1']);
    expect(list.first.item?.id, tofu);
    expect(list[1].item, isNull);
  });

  test('ticking puts it where it was; buying part leaves the rest on the list', () {
    d = addToBuy(d, ctx, '두부', qty: 2);
    final line = shoppingList(d).first;
    expect(placeFor(d, line), fridge);
    final r = buyLine(d, ctx, line, containerId: fridge, bought: 1);
    expect(r.data.item(tofu)!.qty, 2);
    expect(r.value, tofu);
    expect(shoppingList(r.data).first.qty, 1);
    final all = buyLine(r.data, ctx, shoppingList(r.data).first, containerId: fridge);
    expect(all.data.toBuy, isEmpty);
    expect(all.data.item(tofu)!.qty, 3);
  });

  test('something new goes where things were last put, as a new stack', () {
    d = addToBuy(d, ctx, '우유', qty: 2);
    final line = shoppingList(d).first;
    final at = placeFor(d, line)!;
    final r = buyLine(d, ctx, line, containerId: at);
    final milk = r.data.item(r.value)!;
    expect(milk.name, '우유');
    expect(milk.qty, 2);
    expect(milk.category, ItemCategory.food);
    expect(r.data.toBuy, isEmpty);
  });

  test('a low thing refills; a receipt takes names off by the number put in', () {
    final low = shoppingList(d).single;
    final r = buyLine(d, ctx, low, containerId: shelf);
    expect(lowStock(r.data), isEmpty);
    var x = addToBuy(r.data, ctx, '두부', qty: 3);
    x = addToBuy(x, ctx, '우유');
    final s = settleToBuy(x, {'두부': 1, '우유': 2, '라면': 1});
    expect(s.value, ['두부', '우유']);
    expect(s.data.toBuy.single.qty, 2);
  });

  test('the list syncs as its own documents and survives a backup', () {
    final x = addToBuy(d, ctx, '두부');
    final w = diffHome(d, x).single;
    expect(w.shelf, Shelf.buy);
    final back = homeFromDocs(spaces: const [], containers: const [], items: const [], log: const [], buy: [w.data!]);
    expect(back.toBuy.single.name, '두부');
    expect(HomeData.fromJson(x.toJson()).toBuy.single.qty, 1);
    expect(removeToBuy(x, x.toBuy.single.id).toBuy, isEmpty);
  });
}
