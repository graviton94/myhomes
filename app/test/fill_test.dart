import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);
  const en = {'language': 'en'};

  testWidgets('a new home on the map: rooms, then storage, then things', (tester) async {
    final c = await pumpApp(tester, prefs: en);
    await tester.tap(find.byKey(const ValueKey('home-empty-plan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('use-template')));
    await tester.pumpAndSettle();
    // ① Rooms: the template's, on the map. 다음 goes on to ② storage on the same map.
    expect(find.byKey(const ValueKey('plan-step-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('house-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('fur-place-usual')), findsOneWidget);
    // The usual storage of every room in one tap, and one of my own kind.
    await tester.tap(find.byKey(const ValueKey('fur-place-usual')));
    await tester.pumpAndSettle();
    var d = c.read(homeProvider).requireValue;
    final usual = d.containers.length;
    expect(usual, greaterThan(3));
    // A suggested spot for the room in view, one tap.
    final idea = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('fur-add-') && (w.key! as ValueKey<String>).value != 'fur-add-own');
    if (idea.evaluate().isNotEmpty) {
      await tester.ensureVisible(idea.first);
      await tester.tap(idea.first);
      await tester.pumpAndSettle();
    }
    final more = c.read(homeProvider).requireValue.containers.length;
    await tester.tap(find.byKey(const ValueKey('house-done')));
    await tester.pumpAndSettle();
    d = c.read(homeProvider).requireValue;
    expect(d.containers.length, more);
    expect(more, greaterThanOrEqualTo(usual));
    expect(d.containers.every((s) => s.plan != null), isTrue); // all standing on the map

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
