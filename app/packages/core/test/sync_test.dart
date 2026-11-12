import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  late Ctx ctx;
  setUp(() {
    var n = 0;
    ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 10, 28, 9), by: 'kakao:1');
  });

  test('a change writes only the documents it touched, and log entries once', () {
    final a = addSpace(const HomeData(), ctx, '거실');
    final b = addContainer(a.data, ctx, spaceId: a.value.id, name: 'TV장');
    final c = addItem(b.data, ctx, containerId: b.value.id, name: '가위');
    expect(uploadHome(c.data).map((w) => '${w.shelf.name}/${w.id}'), ['spaces/id0', 'containers/id1', 'items/id2', 'log/id4']);
    expect(c.data.log.single.by, 'kakao:1');

    final d = adjustQty(c.data, ctx, c.value.id, 2);
    final w = diffHome(c.data, d);
    expect(w.map((w) => '${w.shelf.name}/${w.id}'), ['items/id2', 'log/id6']);
    expect(w.first.data!['qty'], 3);

    final e = deleteSpace(d, a.value.id);
    expect(diffHome(d, e).where((w) => w.data == null).map((w) => w.shelf), containsAll([Shelf.spaces, Shelf.containers, Shelf.items]));
  });

  test('documents come back as the same home, in the order things were made', () {
    final a = addSpace(const HomeData(), ctx, '거실');
    final b = addSpace(a.data, ctx, '주방');
    final c = addItem(
      addContainer(b.data, ctx, spaceId: b.value.id, name: '냉장고').data,
      ctx,
      containerId: 'id2',
      name: '우유',
    );
    var o = 0;
    Map<String, Object?> doc(Map<String, Object?> j) => {...j, orderField: o++};
    final docs = uploadHome(c.data);
    List<Map<String, Object?>> of(Shelf s) => [for (final w in docs.where((w) => w.shelf == s)) doc(w.data!)].reversed.toList();
    final back = homeFromDocs(spaces: of(Shelf.spaces), containers: of(Shelf.containers), items: of(Shelf.items), log: of(Shelf.log));
    expect(back.toJson(), c.data.toJson());
  });

  test('the last change says who made it', () {
    final a = addSpace(const HomeData(), ctx, '거실');
    final b = addContainer(a.data, ctx, spaceId: a.value.id, name: 'TV장');
    final c = addItem(b.data, ctx, containerId: b.value.id, name: '가위');
    expect(lastChange(c.data)!.by, 'kakao:1');
  });

  test("undo takes back only its own change, not the family's since", () {
    final a = addSpace(const HomeData(), ctx, '거실');
    final b = addContainer(a.data, ctx, spaceId: a.value.id, name: 'TV장');
    final scissors = addItem(b.data, ctx, containerId: b.value.id, name: '가위', qty: 2);
    final before = scissors.data;
    // I use the scissors...
    final after = useItem(before, ctx, scissors.value.id);
    // ...and meanwhile the family adds milk and a shopping line.
    final milk = addItem(after, ctx, containerId: b.value.id, name: '우유');
    final current = addToBuy(milk.data, ctx, '두부');

    final undone = revertChange(current, before, after);
    expect(undone.items.map((i) => i.name), ['가위', '우유']); // the milk stays
    expect(undone.toBuy.single.name, '두부');
    expect(undone.item(scissors.value.id)!.toJson(), before.item(scissors.value.id)!.toJson()); // the scissors are as before
    // Nothing else happened since: plain undo.
    expect(identical(revertChange(after, before, after), before), isTrue);
    // Undoing a delete brings the thing back next to the family's new one.
    final gone = removeItem(before, ctx, scissors.value.id);
    final withMilk = addItem(gone, ctx, containerId: b.value.id, name: '우유').data;
    expect(revertChange(withMilk, before, gone).items.map((i) => i.name).toSet(), {'가위', '우유'});
  });

  test('a change of amount alone is sent as "this many more or fewer"', () {
    final a = addSpace(const HomeData(), ctx, '거실');
    final b = addContainer(a.data, ctx, spaceId: a.value.id, name: 'TV장');
    final c = addItem(b.data, ctx, containerId: b.value.id, name: '건전지', qty: 6);
    final used = adjustQty(c.data, ctx, c.value.id, -2);
    expect(countChanges(c.data, used), {c.value.id: -2});
    // Renamed as well: the whole thing is written, not counted.
    final renamed = used.copyWith(
      items: [for (final i in used.items) i.copyWith(name: 'AA 건전지', updatedAt: i.updatedAt)],
    );
    expect(countChanges(c.data, renamed), isEmpty);
    // A stub left by a delete racing an amount change is not a thing.
    final back = homeFromDocs(
      spaces: const [],
      containers: const [],
      items: [
        {'id': 'x', 'qty': -1, 'updatedAt': '2026-11-12T00:00:00.000'},
      ],
      log: const [],
    );
    expect(back.items, isEmpty);
  });
}
