import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/features/fairy/fairy_chat_sheet.dart';
import 'package:homefairy/settings/settings.dart';

import 'helpers.dart';

void main() {
  testWidgets('starts in English on the home tab', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'});
    expect(find.text('My home'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Take out'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('switching language to Korean updates the screen', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'});
    await container.read(settingsProvider.notifier).setLanguage(AppLanguage.ko);
    await tester.pumpAndSettle();
    expect(find.text('우리 집'), findsOneWidget);
    expect(find.text('빼기'), findsOneWidget);
  });

  testWidgets('stored settings are restored', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'ko', 'theme': 'dark'});
    final s = container.read(settingsProvider);
    expect(s.language, AppLanguage.ko);
    expect(s.themeMode, ThemeMode.dark);
  });

  testWidgets('settings change language from the radio list', (tester) async {
    final container = await pumpApp(tester, location: '/settings', prefs: {'language': 'en'});
    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).language, AppLanguage.ko);
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('first launch goes intro -> login -> home as a guest', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, onboarded: false);
    expect(find.text('Find anything in seconds'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Kakao'), findsOneWidget);
    await tester.tap(find.text('Continue with Kakao'));
    await tester.pump();
    expect(find.text('Sign-in opens soon'), findsOneWidget);
    await tester.tap(find.text('Start without an account'));
    await tester.pumpAndSettle();
    expect(find.text('My home'), findsOneWidget);
    expect(container.read(settingsProvider).started, isTrue);
  });

  testWidgets('quick add without storage asks for a space first', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'});
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Add a space and a storage spot first.'), findsOneWidget);
  });

  testWidgets('use-by tab groups dated items', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.text('Use by'));
    await tester.pumpAndSettle();
    expect(find.text('Past the date · 1'), findsOneWidget);
    expect(find.text('Within 3 days · 2'), findsOneWidget);
    expect(find.text('Yogurt ×4'), findsWidgets);
  });

  testWidgets('tapping an empty square adds an item there', (tester) async {
    final container = await pumpApp(tester, location: '/storage/$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.byKey(const ValueKey('slot-$sampleTv-3')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Glue');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final glue = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Glue');
    expect(glue.containerId, sampleTv);
    expect(glue.slot, 3);
  });

  testWidgets('pick several, move, then undo', (tester) async {
    final container = await pumpApp(tester, location: '/storage/$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    await tester.longPress(find.byKey(const ValueKey('slot-$sampleTv-1'))); // Remote, qty 1
    await tester.pumpAndSettle();
    expect(find.text('1 kind · 1 pcs'), findsOneWidget);
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Living room › Drawer').first);
    await tester.pumpAndSettle();
    final home = container.read(homeProvider).requireValue;
    expect(home.items.singleWhere((i) => i.name == 'Remote').containerId, sampleDrawer);
    expect(find.text('Moved 1 to Drawer'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Remote').containerId, sampleTv);
  });

  testWidgets('the fairy finds things', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.bySemanticsLabel(RegExp('Ask the House Fairy')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'where are the scissors?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('Found it! Here it is.'), findsOneWidget);
    expect(find.text('Scissors · ×1'), findsOneWidget);
  });

  test('question words are stripped for the fairy search', () {
    expect(searchTermOf('건전지 어디 있어?'), '건전지');
    expect(searchTermOf('가위는 어디에 있어요?'), '가위');
    expect(searchTermOf('Where are the batteries?'), 'batteries');
    expect(searchTermOf("where's my passport"), 'passport');
  });

  testWidgets('room board shows bags and moves picked items with "Move here"', (tester) async {
    final container = await pumpApp(tester, location: '/spaces', prefs: {'language': 'en'}, home: sampleHome());
    expect(find.text('TV stand'), findsOneWidget);
    expect(find.text('Drawer'), findsOneWidget);
    expect(find.text('Remote'), findsOneWidget);
    await tester.longPress(find.byKey(const ValueKey('slot-$sampleTv-1')));
    await tester.pumpAndSettle();
    expect(find.text('Move here'), findsOneWidget);
    await tester.tap(find.text('Move here'));
    await tester.pumpAndSettle();
    final home = container.read(homeProvider).requireValue;
    expect(home.items.singleWhere((i) => i.name == 'Remote').containerId, sampleDrawer);
    await tester.tap(find.text('Kitchen'));
    await tester.pumpAndSettle();
    expect(find.text('Fridge'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('a new room gets an icon suggested from its name', (tester) async {
    final container = await pumpApp(tester, location: '/spaces', prefs: {'language': 'en'});
    await tester.tap(find.text('Add a space'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Kitchen');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final space = container.read(homeProvider).requireValue.spaces.single;
    expect(space.name, 'Kitchen');
    expect(space.icon, 'kitchen');
    expect(find.text('Add a storage spot'), findsWidgets);
  });
}
