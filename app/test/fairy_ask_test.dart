import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';

import 'helpers.dart';

void main() {
  Future<void> ask(WidgetTester tester, String q) async {
    await tester.enterText(find.byKey(const ValueKey('home-search')), q);
    await tester.pumpAndSettle();
  }

  testWidgets('"how many eggs" counts them', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await ask(tester, 'how many eggs do we have?');
    expect(find.text('10 Eggs at home'), findsOneWidget);
  });

  testWidgets('"buy milk" offers to put it on the list', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await ask(tester, 'buy milk');
    expect(find.text('Put Milk on the shopping list?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fairy-buy')));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.toBuy.single.name, 'Milk');
  });

  testWidgets('something new to buy goes on the list too', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await ask(tester, 'need to buy tofu');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fairy-buy')));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.toBuy.single.name, 'tofu');
  });

  testWidgets('"milk ran out" offers to mark it used up', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await ask(tester, 'milk ran out');
    expect(find.text('Mark Milk as used up?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fairy-usedUp')));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.items.where((i) => i.name == 'Milk'), isEmpty);
  });
}
