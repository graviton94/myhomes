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
}
