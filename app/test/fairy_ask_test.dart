import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/household.dart';

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

  testWidgets('not found in a shared home: ask the family', (tester) async {
    final homes = FakeHouseholds();
    await homes.create('Our home', upload: sampleHome());
    homes.add(const Member('mom', 'Mom', null));
    await pumpApp(tester, prefs: {'language': 'en'}, accounts: const SignedIn(), households: homes);
    await ask(tester, 'gloves');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ask-family')));
    await tester.pumpAndSettle();
    expect(homes.asked, ['gloves']);
    expect(find.text('Asked the family'), findsOneWidget);
  });

  testWidgets('alone, there is nobody to ask', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await ask(tester, 'gloves');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ask-family')), findsNothing);
  });
}
