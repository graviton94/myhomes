import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';

import 'helpers.dart';

void main() {
  testWidgets('a warranty and a price from the item form show in the valuables list', (tester) async {
    final container = await pumpApp(tester, location: '/item/new?storage=$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    await tester.enterText(find.byType(TextField).first, 'TV');
    await tester.scrollUntilVisible(find.byKey(const ValueKey('more-valuable')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('more-valuable')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('warranty-1'))); // 2 years
    await tester.enterText(find.byKey(const ValueKey('valuable-price')), '1200000');
    await tester.tap(find.byKey(const ValueKey('valuable-done')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final tv = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'TV');
    final now = DateTime.now();
    expect(tv.warrantyUntil, DateTime(now.year + 2, now.month, now.day));
    expect(tv.price, 1200000);

    await pumpApp(tester, location: '/valuables', prefs: {'language': 'en'}, home: container.read(homeProvider).requireValue);
    expect(find.text('1,200,000 won in all'), findsOneWidget);
    expect(find.text('TV'), findsOneWidget);
  });

  testWidgets('with nothing valuable yet the list says what it is for', (tester) async {
    await pumpApp(tester, location: '/valuables', prefs: {'language': 'en'}, home: sampleHome());
    expect(find.text('Things with a warranty or a price gather here'), findsOneWidget);
  });
}
