import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);
  const en = {'language': 'en'};

  testWidgets('a new home: pick spots, then things, with names of my own too', (tester) async {
    final c = await pumpApp(tester, prefs: en);
    await tester.tap(find.byKey(const ValueKey('home-empty-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('use-template')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('house-done')));
    await tester.pumpAndSettle();

    // Spots: the usual two per room are picked; one more of my own.
    expect(find.text('Pick storage spots'), findsOneWidget);
    final room = c.read(homeProvider).requireValue.spaces.first;
    await tester.ensureVisible(find.byKey(ValueKey('fill-own-spot-${room.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('fill-own-spot-${room.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Piano bench');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fill-next')));
    await tester.pumpAndSettle();
    var d = c.read(homeProvider).requireValue;
    expect(d.containers.map((s) => s.name), contains('Piano bench'));
    expect(d.containers.length, greaterThan(3));

    // Things: one tap is 1, two taps 2.
    expect(find.text('Pick things'), findsOneWidget);
    Future<void> tapChip(int i) async {
      final chip = find.byType(FilterChip).at(i);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    await tapChip(0);
    await tapChip(1);
    await tapChip(1);
    await tester.tap(find.byKey(const ValueKey('fill-next')));
    await tester.pumpAndSettle();
    d = c.read(homeProvider).requireValue;
    expect(d.items.length, 2);
    expect(d.items.map((i) => i.qty).toList()..sort(), [1, 2]);
    expect(find.text('2 things put away!'), findsOneWidget);
    expect(find.byKey(const ValueKey('fill-more')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fill-map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-ask')), findsOneWidget);
  });
}
