import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';

Item named(HomeData d, String name) => d.items.singleWhere((i) => i.name == name);

void main() {
  testWidgets('using scissors marks them in use; put back clears it', (tester) async {
    final container = await pumpApp(tester, location: '/storage/$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.byKey(const ValueKey('slot-$sampleTv-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-use')));
    await tester.pumpAndSettle();
    expect(find.text('Scissors is in use'), findsOneWidget);
    expect(named(container.read(homeProvider).requireValue, 'Scissors').inUseSince, isNotNull);

    await tester.tap(find.byKey(const ValueKey('slot-$sampleTv-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-in-use')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('item-put-back')));
    await tester.pumpAndSettle();
    expect(named(container.read(homeProvider).requireValue, 'Scissors').inUseSince, isNull);
  });

  testWidgets('using batteries takes one away', (tester) async {
    final container = await pumpApp(tester, location: '/storage/$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.byKey(const ValueKey('slot-$sampleTv-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-use')));
    await tester.pumpAndSettle();
    expect(named(container.read(homeProvider).requireValue, 'AA batteries').qty, 7);
  });

  HomeData scissorsOut(Duration ago) {
    final d = sampleHome();
    final s = named(d, 'Scissors');
    return d.copyWith(
      items: [
        for (final i in d.items) i.id == s.id ? i.copyWith(inUseSince: DateTime.now().subtract(ago), updatedAt: i.updatedAt) : i,
      ],
    );
  }

  testWidgets('opening the app asks about scissors taken out hours ago', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, asks: true, home: scissorsOut(const Duration(hours: 3)));
    await tester.pumpAndSettle();
    expect(find.text('Done with the Scissors?'), findsOneWidget);
    await tester.tap(find.text('Yes, put back'));
    await tester.pumpAndSettle();
    expect(named(container.read(homeProvider).requireValue, 'Scissors').inUseSince, isNull);
  });

  testWidgets('"still using" waits until tomorrow; nothing is asked an hour in', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, asks: true, home: scissorsOut(const Duration(hours: 3)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Still using it'));
    await tester.pumpAndSettle();
    final s = named(container.read(homeProvider).requireValue, 'Scissors');
    expect(s.inUseSince, isNotNull);
    expect(s.askedAt, isNotNull);

    await pumpApp(tester, prefs: {'language': 'en'}, asks: true, home: scissorsOut(const Duration(hours: 1)));
    await tester.pumpAndSettle();
    expect(find.text('Done with the Scissors?'), findsNothing);
  });

  testWidgets('history filters by + ⇄ −', (tester) async {
    final base = sampleHome();
    final ctx = Ctx(newId: () => 'u${DateTime.now().microsecondsSinceEpoch}', now: DateTime.now);
    final d = useItem(base, ctx, named(base, 'Milk').id);
    await pumpApp(tester, location: '/history', prefs: {'language': 'en'}, home: d);
    expect(find.byType(ListTile), findsAtLeastNWidgets(3));
    await tester.tap(find.text('Used'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    await tester.tap(find.text('In'));
    await tester.pumpAndSettle();
    expect(find.text('Milk'), findsNothing);
    expect(find.textContaining('and 2 more'), findsWidgets);
  });

  testWidgets('opening the app asks about yogurt past its date', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, asks: true, home: sampleHome());
    await tester.pumpAndSettle();
    expect(find.text('Is the Yogurt used up?'), findsOneWidget);
    await tester.tap(find.text('Threw it away'));
    await tester.pumpAndSettle();
    final d = container.read(homeProvider).requireValue;
    expect(d.items.where((i) => i.name == 'Yogurt'), isEmpty);
    expect(d.log.first.type, LogType.discard);
  });
}
