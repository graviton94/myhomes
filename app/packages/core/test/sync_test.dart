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
}
