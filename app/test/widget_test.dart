import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/smart_suggest.dart';
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
    expect(find.text('Login with Kakao'), findsOneWidget);
    await tester.tap(find.text('Login with Kakao'));
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
    await tester.tap(find.text('Drawer').last);
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

  Future<void> dragTo(WidgetTester tester, Finder from, Finder to) async {
    final g = await tester.startGesture(tester.getCenter(from));
    await tester.pump(const Duration(milliseconds: 700));
    final end = tester.getCenter(to);
    final start = tester.getCenter(from);
    for (var i = 1; i <= 10; i++) {
      await g.moveTo(Offset.lerp(start, end, i / 10)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pumpAndSettle();
  }

  testWidgets('drag an item onto another storage spot to move it', (tester) async {
    final container = await pumpApp(tester, location: '/spaces', prefs: {'language': 'en'}, home: sampleHome());
    await dragTo(tester, find.byKey(const ValueKey('slot-$sampleTv-1')), find.text('Drawer'));
    final remote = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Remote');
    expect(remote.containerId, sampleDrawer);
    expect(find.text('Moved 1 to Drawer'), findsOneWidget);
  });

  testWidgets('drag within a storage spot swaps squares', (tester) async {
    final container = await pumpApp(tester, location: '/storage/$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    await dragTo(tester, find.byKey(const ValueKey('slot-$sampleTv-0')), find.byKey(const ValueKey('slot-$sampleTv-3')));
    final items = container.read(homeProvider).requireValue.itemsIn(sampleTv);
    expect(items.singleWhere((i) => i.name == 'AA batteries').slot, 3);
  });

  testWidgets('search result opens the room with the item flashing', (tester) async {
    await pumpApp(tester, location: '/search', prefs: {'language': 'en'}, home: sampleHome());
    await tester.enterText(find.byType(TextField), 'band');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Band-aids ×20'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Living room'), findsWidgets);
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Flash'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('places outside the home get their own tabs', (tester) async {
    final container = await pumpApp(tester, location: '/spaces', prefs: {'language': 'en'}, home: sampleHome());
    await tester.ensureVisible(find.text('Outside'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outside'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Office');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final office = container.read(homeProvider).requireValue.spaces.singleWhere((s) => s.name == 'Office');
    expect(office.outside, isTrue);
    expect(office.icon, 'office');
    expect(find.text('Back by (optional)'), findsNothing);
    await tester.tap(find.text('Add a storage spot').last);
    await tester.pumpAndSettle();
    expect(find.text('Back by (optional)'), findsOneWidget);
  });

  testWidgets('drag across rooms: hold over a room in the dock to open it, then drop on a spot', (tester) async {
    final container = await pumpApp(tester, location: '/spaces', prefs: {'language': 'en'}, home: sampleHome());
    final from = tester.getCenter(find.byKey(const ValueKey('slot-$sampleTv-1')));
    final g = await tester.startGesture(from);
    await tester.pump(const Duration(milliseconds: 700));
    await g.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(find.text('Hold over a room to open it, or drop it on the room'), findsOneWidget);
    final kitchen = find.descendant(of: find.byType(Positioned), matching: find.text('Kitchen'));
    await g.moveTo(tester.getCenter(kitchen.last));
    await tester.pump(const Duration(milliseconds: 100));
    await g.moveBy(const Offset(2, 0));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(find.text('Fridge'), findsOneWidget);
    await g.moveTo(tester.getCenter(find.text('Fridge')));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    await tester.pumpAndSettle();
    final remote = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Remote');
    expect(remote.containerId, sampleFridge);
  });

  testWidgets('drop on a room with one spot moves straight there', (tester) async {
    final container = await pumpApp(tester, location: '/spaces', prefs: {'language': 'en'}, home: sampleHome());
    final g = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('slot-$sampleTv-1'))));
    await tester.pump(const Duration(milliseconds: 700));
    await g.moveBy(const Offset(0, 30));
    await tester.pump();
    final car = find.descendant(of: find.byType(Positioned), matching: find.text('Car'));
    await tester.ensureVisible(car.last);
    await g.moveTo(tester.getCenter(car.last));
    await tester.pump(const Duration(milliseconds: 100));
    await g.up();
    await tester.pumpAndSettle();
    final remote = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Remote');
    expect(container.read(homeProvider).requireValue.container(remote.containerId)!.name, 'Lent to Alex');
  });

  testWidgets('storage spots can be edited and deleted from the bag menu', (tester) async {
    final container = await pumpApp(tester, location: '/spaces', prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit storage spot'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'TV cabinet');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.container(sampleTv)!.name, 'TV cabinet');
    await tester.tap(find.byTooltip('More').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit storage spot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete TV cabinet'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.container(sampleTv), isNull);
  });

  testWidgets('a confident suggestion picks the category and icon', (tester) async {
    final container = await pumpApp(
      tester,
      location: '/item/new?storage=$sampleDrawer',
      prefs: {'language': 'en'},
      home: sampleHome(),
      suggest: _FakeSuggest(),
    );
    await tester.enterText(find.byType(TextField).first, 'Tylenol');
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('The fairy picked the category and icon. Change them if they are wrong.'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final item = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Tylenol');
    expect(item.category.name, 'medicine');
    expect(item.icon, 'pill');
  });

  testWidgets('search shows what the fairy matched by meaning', (tester) async {
    await pumpApp(tester, location: '/search', prefs: {'language': 'en'}, home: sampleHome(), suggest: _FakeSuggest());
    await tester.enterText(find.byType(TextField), 'plaster');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('The fairy found it'), findsOneWidget);
    expect(find.text('Band-aids ×20'), findsOneWidget);
  });

  testWidgets('with suggestions off nothing is asked', (tester) async {
    final fake = _FakeSuggest();
    await pumpApp(tester, location: '/search', prefs: {'language': 'en', 'smartSuggest': false}, home: sampleHome(), suggest: fake);
    await tester.enterText(find.byType(TextField), 'plaster');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(fake.calls, 0);
    expect(find.text('The fairy found it'), findsNothing);
  });
}

class _FakeSuggest implements SmartSuggest {
  int calls = 0;

  @override
  Future<({Pick? category, Pick? icon})?> classify(String name) async {
    calls++;
    return (category: const Pick('medicine', 0.93, [('medicine', 0.93)]), icon: const Pick('pill', 0.88, [('pill', 0.88), ('syrup', 0.1)]));
  }

  @override
  Future<Pick?> find(String query, List<String> itemNames) async {
    calls++;
    return const Pick('Band-aids', 0.91, [('Band-aids', 0.91)]);
  }
}
