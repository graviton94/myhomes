import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  late Ctx ctx;
  late HomeData d;
  late String drawer, box;
  final now = DateTime(2026, 11, 5, 10); // a Thursday

  setUp(() {
    var n = 0;
    ctx = Ctx(newId: () => 'g${n++}', now: () => now);
    final s = addSpace(const HomeData(), ctx, '거실');
    final a = addContainer(s.data, ctx, spaceId: s.value.id, name: '서랍');
    final b = addContainer(a.data, ctx, spaceId: s.value.id, name: '빈 상자');
    drawer = a.value.id;
    box = b.value.id;
    d = b.data;
    for (final name in ['가위', '테이프', '건전지']) {
      d = addItem(d, ctx, containerId: drawer, name: name).data;
    }
    d = addItem(d, ctx, containerId: drawer, name: '우유', category: ItemCategory.food, expiresOn: DateTime(2026, 11, 1)).data;
  });

  test('stars come from the home; stages follow them', () {
    // 4 things, 1 spot with things (2), 1 detail (the date).
    expect(homeStars(d), 4 + 2 + 1);
    expect(homeStars(d, members: 3, taskStars: 10), 7 + 10 + 10);
    expect(stageOf(0), FairyStage.sprout);
    expect(stageOf(20), FairyStage.little);
    expect(stageOf(249), FairyStage.steady);
    expect(stageOf(999), FairyStage.guardian);
    expect(starsToNext(42), 8);
    expect(starsToNext(300), isNull);
    expect(stageProgress(35), closeTo(0.5, 0.001));
  });

  test('this week: three tasks picked from the home, done when the home says so', () {
    final tasks = pickWeekTasks(d, now);
    expect(tasks.map((t) => t.kind), [WeekTaskKind.clearExpired, WeekTaskKind.fillSpot, WeekTaskKind.addFive]);
    expect(tasks.first.label, '우유');
    final since = weekStart(now);
    expect(since, DateTime(2026, 11, 2));
    expect(tasks.any((t) => weekTaskDone(t, d, since)), isFalse);
    final milk = d.items.firstWhere((i) => i.name == '우유');
    var x = useUpItems(d, ctx, [milk.id]);
    x = addItem(x, ctx, containerId: box, name: '공구').data;
    expect(weekTaskDone(tasks[0], x, since), isTrue);
    expect(weekTaskDone(tasks[1], x, since), isTrue);
    expect(weekTaskDone(tasks[2], x, since), isTrue); // 5 put away this week (setUp + 공구)
    final back = WeekTask.fromJson(tasks[1].toJson())!;
    expect((back.kind, back.target, back.label), (WeekTaskKind.fillSpot, box, '빈 상자'));
  });

  test('stamps', () {
    expect(stampsOf(d, now), [Stamp.fridgeKeeper]);
    var x = addItem(d, ctx, containerId: drawer, name: '풀').data;
    x = editItem(x, ctx, x.items.first.copyWith(warrantyUntil: DateTime(2027), updatedAt: now));
    expect(stampsOf(x, now, members: 2), [Stamp.firstDrawer, Stamp.family, Stamp.fridgeKeeper, Stamp.warranty]);
    final thrown = discardItems(x, ctx, [x.items.firstWhere((i) => i.name == '우유').id]);
    expect(stampsOf(thrown, now), isNot(contains(Stamp.fridgeKeeper)));
  });
}
