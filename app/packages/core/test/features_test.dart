import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime(2026, 10, 28, 12);
  Item item(String id, {int qty = 1, int? minQty, DateTime? expiresOn}) =>
      Item(id: id, containerId: 'c', slot: 0, name: id, qty: qty, minQty: minQty, expiresOn: expiresOn, updatedAt: now);

  test('low stock lists only items under their minimum, emptiest first', () {
    final d = HomeData(
      items: [item('tissue', qty: 2, minQty: 3), item('soap', qty: 0, minQty: 2), item('rice', qty: 5, minQty: 2), item('cup', qty: 0)],
    );
    expect(lowStock(d).map((i) => i.id), ['soap', 'tissue']);
  });

  test('minQty round-trips through JSON and can be cleared', () {
    final i = item('soap', minQty: 2);
    expect(Item.fromJson(i.toJson()).minQty, 2);
    expect(Item.fromJson(item('cup').toJson()).minQty, isNull);
    expect(i.copyWith(clearMinQty: true, updatedAt: now).minQty, isNull);
  });

  test('due within N days includes overdue and today, soonest first', () {
    final d = HomeData(
      items: [
        item('milk', expiresOn: DateTime(2026, 10, 30)),
        item('old', expiresOn: DateTime(2026, 10, 26)),
        item('jam', expiresOn: DateTime(2026, 12, 1)),
        item('plain'),
      ],
    );
    expect(dueWithin(d, DateTime(2026, 10, 28), 3).map((e) => e.$1.id), ['old', 'milk']);
  });

  test('reminders follow the switches, are sorted and capped', () {
    final d = HomeData(
      containers: [Storage(id: 's', spaceId: 'x', name: 'Mina', code: 'A1', returnBy: DateTime(2026, 11, 5))],
      items: [item('milk', expiresOn: DateTime(2026, 10, 30))],
    );
    final both = remindersFrom(d, now, expiry: true, returns: true);
    // milk: D-1 (29th) and the day (30th); D-3 is already past. Return: D-3, D-1, the day.
    expect(both.map((r) => (r.kind, r.at.day, r.daysLeft)), [
      (ReminderKind.expiry, 29, 1),
      (ReminderKind.expiry, 30, 0),
      (ReminderKind.returnBy, 2, 3),
      (ReminderKind.returnBy, 4, 1),
      (ReminderKind.returnBy, 5, 0),
    ]);
    expect(both.every((r) => r.at.hour == 9), isTrue);
    expect(both.map((r) => r.id).toSet().length, 5);
    expect(remindersFrom(d, now, expiry: false, returns: true).every((r) => r.kind == ReminderKind.returnBy), isTrue);
    expect(remindersFrom(d, now, expiry: false, returns: false), isEmpty);
    expect(remindersFrom(d, now, expiry: true, returns: true, limit: 2).length, 2);
  });

  test('using up a stocked thing keeps it at 0 on the list; others are removed', () {
    final ctx = Ctx(newId: () => 'log', now: () => now);
    final d = HomeData(items: [item('soap', qty: 1, minQty: 2), item('cup', qty: 1)]);
    final a = adjustQty(adjustQty(d, ctx, 'soap', -3), ctx, 'cup', -1);
    expect(a.items.map((i) => (i.id, i.qty)), [('soap', 0)]);
    expect(lowStock(a).single.id, 'soap');
  });
}
