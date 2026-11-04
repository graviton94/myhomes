import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('things that run out are used up; the rest come back', () {
    expect(useKindOf(ItemCategory.food), UseKind.usedUp);
    expect(useKindOf(ItemCategory.household), UseKind.usedUp);
    expect(useKindOf(ItemCategory.tools), UseKind.returned);
    expect(useKindOf(ItemCategory.electronics), UseKind.returned);
  });

  test('asks on opening the app two hours later, once a day', () {
    final taken = DateTime(2026, 11, 4, 11, 40);
    expect(askOnOpen(takenAt: taken, now: DateTime(2026, 11, 4, 13, 0)), isFalse);
    expect(askOnOpen(takenAt: taken, now: DateTime(2026, 11, 4, 13, 40)), isTrue);
    expect(askOnOpen(takenAt: taken, now: DateTime(2026, 11, 4, 18), askedAt: DateTime(2026, 11, 4, 14)), isFalse);
    expect(askOnOpen(takenAt: taken, now: DateTime(2026, 11, 5, 15), askedAt: DateTime(2026, 11, 4, 14)), isTrue);
  });

  test('the evening reminder is 8 pm, or the next evening when too late', () {
    expect(askReminderAt(takenAt: DateTime(2026, 11, 4, 11, 40)), DateTime(2026, 11, 4, 20));
    expect(askReminderAt(takenAt: DateTime(2026, 11, 4, 19)), DateTime(2026, 11, 5, 20));
    expect(askReminderAt(takenAt: DateTime(2026, 11, 4, 11), askedAt: DateTime(2026, 11, 4, 14)), isNull);
    expect(askReminderAt(takenAt: DateTime(2026, 11, 4, 11), askedAt: DateTime(2026, 11, 3, 14)), DateTime(2026, 11, 4, 20));
  });

  test('using scissors marks them in use; tissues go down; asked two hours later', () {
    var now = DateTime(2026, 11, 4, 11, 40);
    var n = 0;
    final ctx = Ctx(newId: () => 'id${n++}', now: () => now);
    final space = addSpace(const HomeData(), ctx, 'Living');
    final box = addContainer(space.data, ctx, spaceId: space.value.id, name: 'TV stand');
    final cut = addItem(box.data, ctx, containerId: box.value.id, name: '가위', category: ItemCategory.tools);
    final paper = addItem(cut.data, ctx, containerId: box.value.id, name: '휴지', category: ItemCategory.household, qty: 3);
    var d = useItem(paper.data, ctx, cut.value.id);
    d = useItem(d, ctx, paper.value.id);
    expect(d.item(cut.value.id)!.inUseSince, now);
    expect(d.item(cut.value.id)!.qty, 1);
    expect(d.item(paper.value.id)!.qty, 2);
    expect(d.item(paper.value.id)!.inUseSince, isNull);
    expect(itemsToAsk(d, now.add(const Duration(hours: 1))), isEmpty);
    now = now.add(const Duration(hours: 2));
    expect(itemsToAsk(d, now).map((i) => i.name), ['가위']);
    d = stillUsing(d, ctx, cut.value.id);
    expect(itemsToAsk(d, now.add(const Duration(hours: 3))), isEmpty);
    d = putBack(d, ctx, cut.value.id);
    expect(d.item(cut.value.id)!.inUseSince, isNull);
    expect(itemsToAsk(d, now.add(const Duration(days: 2))), isEmpty);
    // An item can say otherwise: these tissues come back (a pack lent out).
    final own = editItem(d, ctx, d.item(paper.value.id)!.copyWith(returns: true, updatedAt: now));
    expect(useKindOfItem(own.item(paper.value.id)!), UseKind.returned);
    // In use survives a save and load.
    expect(Item.fromJson(useItem(d, ctx, cut.value.id).item(cut.value.id)!.toJson()).inUseSince, now);
  });

  test('history filters by + ⇄ −, and edits only show under all', () {
    var n = 0;
    final ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 11, 4));
    final space = addSpace(const HomeData(), ctx, 'Living');
    final a = addContainer(space.data, ctx, spaceId: space.value.id, name: 'A');
    final b = addContainer(a.data, ctx, spaceId: space.value.id, name: 'B');
    final milk = addItem(b.data, ctx, containerId: a.value.id, name: '우유', qty: 2);
    var d = moveItems(milk.data, ctx, {milk.value.id: 1}, b.value.id);
    d = adjustQty(d, ctx, milk.value.id, -1);
    d = editItem(d, ctx, d.item(d.items.first.id)!);
    expect(changes(d).length, 4);
    expect(changes(d, only: ActionKind.add).single.names, ['우유']);
    expect(changes(d, only: ActionKind.move).single.containerId, b.value.id);
    expect(changes(d, only: ActionKind.use).single.type, LogType.usedUp);
    expect(actionOf(LogType.edit), isNull);
  });
}
