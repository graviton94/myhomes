import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';

import 'helpers.dart';

void main() {
  testWidgets('a thing going into the fridge: the usual ones first, a tap fills the name', (tester) async {
    final container = await pumpApp(tester, location: '/item/new?storage=$sampleFridge', prefs: {'language': 'ko'}, home: sampleHome(ko: true));
    expect(find.byKey(const ValueKey('idea-계란')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('idea-계란')));
    await tester.pumpAndSettle();
    expect(find.text('계란'), findsWidgets);
    // Typing narrows: by initials too.
    await tester.enterText(find.byType(TextField).first, 'ㄷㅂ');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('idea-두부')), findsOneWidget);
    expect(container.read(homeProvider).requireValue.items.every((i) => i.name != '계란'), isTrue); // not saved by a tap
  });

  testWidgets('a room already there is offered again with a number', (tester) async {
    await pumpApp(tester, prefs: {'language': 'ko'}, home: sampleHome(ko: true));
    expect(sampleHome(ko: true).spaces.map((s) => s.name), contains('거실'));
    await tester.ensureVisible(find.byKey(const ValueKey('map-add-room')));
    await tester.tap(find.byKey(const ValueKey('map-add-room')));
    await tester.pumpAndSettle();
    if (find.byKey(const ValueKey('add-place-room')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('add-place-room')));
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byType(TextField).first, '거');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('idea-거실 2')), findsOneWidget);
  });
}
