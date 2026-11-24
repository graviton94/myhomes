import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);
  const en = {'language': 'en'};

  testWidgets('telling the fairy what was put away asks once, then puts it there', (tester) async {
    final c = await pumpApp(tester, prefs: en, home: sampleHome());
    await openAsk(tester);
    await tester.enterText(find.byKey(const ValueKey('home-search')), 'I put 3 candles in the fridge');
    await tester.pumpAndSettle();
    expect(find.textContaining('Put these in Kitchen › Fridge?'), findsOneWidget);
    expect(c.read(homeProvider).requireValue.items.where((i) => i.name == 'candles'), isEmpty);
    await tester.tap(find.byKey(const ValueKey('ask-put')));
    await tester.pumpAndSettle();
    final d = c.read(homeProvider).requireValue;
    final candles = d.items.where((i) => i.name == 'candles').single;
    expect(candles.containerId, sampleFridge);
    expect(find.textContaining('Put in Fridge!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('no place in the sentence: the fairy asks where, and Put away opens with it', (tester) async {
    await pumpApp(tester, prefs: en, home: sampleHome());
    await openAsk(tester);
    await tester.enterText(find.byKey(const ValueKey('home-search')), 'I put the candles away');
    await tester.pumpAndSettle();
    expect(find.text('Where shall these go?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ask-put-fix')));
    await tester.pumpAndSettle();
    expect(find.text('I put the candles away'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('Put away picks the place named in the sentence', (tester) async {
    final c = await pumpApp(tester, location: '/put', prefs: en, home: sampleHome());
    await tester.enterText(find.byType(TextField).first, 'candles and matches in the fridge');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Put away 2'));
    await tester.pumpAndSettle();
    final d = c.read(homeProvider).requireValue;
    expect(d.items.where((i) => i.name == 'matches').single.containerId, sampleFridge);
    await tester.pump(const Duration(seconds: 10));
  });
}
