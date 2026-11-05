import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('medals go bronze, silver, gold by steps; one-step ones are gold at once', () {
    expect(medalFor(Achievement.things, 9), Medal.none);
    expect(medalFor(Achievement.things, 10), Medal.bronze);
    expect(medalFor(Achievement.things, 50), Medal.silver);
    expect(medalFor(Achievement.things, 200), Medal.gold);
    expect(nextStep(Achievement.things, 38), 50);
    expect(nextStep(Achievement.things, 300), isNull);
    expect(medalFor(Achievement.home, 1), Medal.gold);
    expect(stepsOf(Achievement.home, Medal.gold), 1);
    expect(stepsOf(Achievement.things, Medal.silver), 2);
    expect(medalSteps, greaterThan(Achievement.values.length));
  });

  test('values come from the home, counters and the streak', () {
    var n = 0;
    final now = DateTime(2026, 11, 5);
    final ctx = Ctx(newId: () => 'a${n++}', now: () => now);
    final s = addSpace(const HomeData(), ctx, '주방');
    final f = addContainer(s.data, ctx, spaceId: s.value.id, name: '냉장고');
    var d = f.data;
    for (var i = 0; i < 5; i++) {
      d = addItem(
        d,
        ctx,
        containerId: f.value.id,
        name: '식품$i',
        category: ItemCategory.food,
        qty: 2,
        expiresOn: now.add(const Duration(days: 3)),
      ).data;
    }
    final x = AchievementInput(d, now: now, members: 2, counters: const {'finder': 7}, bestStreak: 4);
    expect(achievementValue(Achievement.things, x), 10);
    expect(achievementValue(Achievement.drawers, x), 1);
    expect(achievementValue(Achievement.dated, x), 5);
    expect(achievementValue(Achievement.fridge, x), 1);
    expect(achievementValue(Achievement.family, x), 1);
    expect(achievementValue(Achievement.finder, x), 7);
    expect(achievementValue(Achievement.streak, x), 4);
    expect(achievementValue(Achievement.home, x), 0);
    // Something past its date: no fridge keeper.
    d = addItem(
      d,
      ctx,
      containerId: f.value.id,
      name: '우유',
      category: ItemCategory.food,
      expiresOn: now.subtract(const Duration(days: 1)),
    ).data;
    expect(achievementValue(Achievement.fridge, AchievementInput(d, now: now)), 0);
  });
}
