import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('a month adds up what came in, was used and was thrown away', () {
    var n = 0;
    var now = DateTime(2026, 10, 3);
    final ctx = Ctx(newId: () => 'id${n++}', now: () => now, by: 'mom');
    var d = addSpace(const HomeData(), ctx, '주방').data;
    d = addContainer(d, ctx, spaceId: d.spaces.single.id, name: '냉장고').data;
    final fridge = d.containers.single.id;
    final milk = addItem(d, ctx, containerId: fridge, name: '우유', qty: 3);
    d = milk.data;
    final yog = addItem(d, ctx, containerId: fridge, name: '요거트', qty: 4);
    d = yog.data;
    d = useItems(d, ctx, {milk.value.id: 2});
    d = discardItems(d, ctx, [yog.value.id]);
    now = DateTime(2026, 11, 1);
    d = adjustQty(d, ctx, milk.value.id, 5); // next month

    final r = monthReport(d.log, 2026, 10);
    expect((r.added, r.used, r.discarded), (7, 2, 4));
    expect(r.topUsed, [('우유', 2)]);
    expect(r.thrownOut, [('요거트', 4)]);
    expect(r.byMember['mom'], 4);
    expect(d.item(yog.value.id), isNull);
    expect(monthReport(d.log, 2026, 11).added, 5);
    expect(monthReport(d.log, 2026, 9).isEmpty, isTrue);
  });
}
