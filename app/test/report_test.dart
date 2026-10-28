import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';

/// This month's changes on top of the sample home.
HomeData reportHome({bool ko = false}) {
  var d = sampleHome(ko: ko);
  var n = 0;
  final ctx = Ctx(newId: () => 'r${n++}', now: DateTime.now);
  Item named(String en, String k) => d.items.firstWhere((i) => i.name == (ko ? k : en));
  final milk = named('Milk', '우유'), batteries = named('AA batteries', 'AA 건전지'), yogurt = named('Yogurt', '요거트');
  d = useItems(d, ctx, {batteries.id: 3, milk.id: 1});
  d = adjustQty(d, ctx, batteries.id, 6);
  d = discardItems(d, ctx, [yogurt.id]);
  return d;
}

void main() {
  testWidgets('the monthly report counts this month and goes back a month', (tester) async {
    await pumpApp(tester, location: '/report', prefs: {'language': 'en'}, home: reportHome());
    expect(find.text('Used most'), findsOneWidget);
    expect(find.text('Thrown away'), findsWidgets);
    expect(find.text('6'), findsOneWidget); // put in
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing recorded this month yet'), findsOneWidget);
  });

  testWidgets('throwing something away from its sheet logs it apart from using it', (tester) async {
    final container = await pumpApp(tester, location: '/storage/$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    final item = container.read(homeProvider).requireValue.itemsIn(sampleTv).first;
    await tester.tap(find.byKey(ValueKey('slot-$sampleTv-${item.slot}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-discard')));
    await tester.pumpAndSettle();
    final d = container.read(homeProvider).requireValue;
    expect(d.item(item.id), isNull);
    expect(d.log.first.type, LogType.discard);
  });
}
