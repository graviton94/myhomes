import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/smart_suggest.dart';
import 'package:homefairy/features/search/search_results.dart';
import 'package:homefairy/settings/settings.dart';

import 'helpers.dart';

void main() {
  testWidgets('starts in English on the home tab', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'});
    expect(find.text('My home'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Put away'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Changes you make show up here.'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings')), findsOneWidget);
  });

  testWidgets('switching language to Korean updates the screen', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'});
    await container.read(settingsProvider.notifier).setLanguage(AppLanguage.ko);
    await tester.pumpAndSettle();
    expect(find.text(keepWords('우리 집')), findsOneWidget);
    expect(find.text(keepWords('지도')), findsOneWidget);
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
    expect(find.text(keepWords('설정')), findsOneWidget);
  });

  testWidgets('first launch goes intro -> login -> home as a guest', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, onboarded: false);
    expect(find.text('Ask, and find it'), findsOneWidget);
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

  testWidgets('the megaphone line shows what was just put away', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.text('Put away'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Glue, tape');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Put away 2 things'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tape and 1 more'), findsOneWidget);
    expect(find.textContaining('just now'), findsOneWidget);
  });

  testWidgets('the map lights up where a search finds things', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    expect(find.byKey(const ValueKey('map-room-id0')), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'remote');
    await tester.pumpAndSettle();
    final block = tester.widget<Material>(
      find.ancestor(of: find.byKey(const ValueKey('map-block-$sampleTv')), matching: find.byType(Material)).first,
    );
    expect(
      block.color,
      isNot(
        equals(
          tester
              .widget<Material>(
                find.ancestor(of: find.byKey(const ValueKey('map-block-$sampleDrawer')), matching: find.byType(Material)).first,
              )
              .color,
        ),
      ),
    );
  });

  testWidgets('use-by tab groups dated items', (tester) async {
    await pumpApp(tester, location: '/expiry', prefs: {'language': 'en', 'feature.expiry': true}, home: sampleHome());
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

  testWidgets('one sentence puts several things away at once', (tester) async {
    final container = await pumpApp(tester, location: '/add?storage=$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    final remote = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Remote');
    await tester.enterText(find.byType(TextField).first, 'Glue, tape and remote 2 pcs');
    await tester.pumpAndSettle();
    expect(find.text('Glue'), findsOneWidget);
    expect(find.text('remote  ×2'), findsOneWidget);
    expect(find.textContaining('Joins the Remote ×${remote.qty}'), findsOneWidget);
    await tester.tap(find.text('Put away 3 things'));
    await tester.pumpAndSettle();
    final home = container.read(homeProvider).requireValue;
    expect(home.itemsIn(sampleTv).map((i) => i.name), containsAll(['Glue', 'tape', 'Remote']));
    expect(home.item(remote.id)!.qty, remote.qty + 2);
    expect(find.text('Put 3 in TV stand'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.items.where((i) => i.name == 'Glue'), isEmpty);
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

  testWidgets('the search box on Home answers questions', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await tester.enterText(find.byType(TextField).first, 'where are the scissors?');
    await tester.pumpAndSettle();
    expect(find.text('Found it! Here it is.'), findsOneWidget);
    expect(find.text('Scissors'), findsOneWidget);
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

  testWidgets('furniture comes with shelves; a box moves with its things', (tester) async {
    // A tall screen, so the whole room board fits without scrolling.
    final container = await pumpApp(
      tester,
      location: '/space/id1',
      prefs: {'language': 'en'},
      home: sampleHome(),
      size: const Size(360, 2400),
    );
    Future<void> addStorage(String kind, String name) async {
      await tester.tap(find.text('Add a storage spot').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(kind));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, name);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
    }

    await addStorage('Furniture', 'Wardrobe');
    expect(find.text('Shelves and drawers'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('sections')), 'Top, Drawer A');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    var d = container.read(homeProvider).requireValue;
    final wardrobe = d.containers.singleWhere((s) => s.name == 'Wardrobe');
    expect(wardrobe.kind, StorageKind.furniture);
    expect(sectionsOf(d, wardrobe.id).map((s) => s.name), ['Top', 'Drawer A']);
    expect(find.textContaining('Drawer A', findRichText: true), findsOneWidget);

    await addStorage('Box', 'Box 1 · Camping');
    d = container.read(homeProvider).requireValue;
    final box = d.containers.singleWhere((s) => s.kind == StorageKind.box);
    expect(box.number, 1);
    await container.read(homeProvider.notifier).apply((d, ctx) => addItem(d, ctx, containerId: box.id, name: 'Tent'));
    await tester.pumpAndSettle();

    final menu = find.byKey(ValueKey('bag-menu-${box.id}'));
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move the whole box'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wardrobe › Top'));
    await tester.pumpAndSettle();
    d = container.read(homeProvider).requireValue;
    expect(d.pathOf(box.id), ['Kitchen', 'Wardrobe', 'Top', 'Box 1 · Camping']);
    expect(searchItems(d, 'tent').single.path, ['Kitchen', 'Wardrobe', 'Top', 'Box 1 · Camping']);
    expect(find.text('Box 1 · Camping · 1 item'), findsOneWidget); // now a chip on the shelf
  });

  testWidgets('a template puts rooms on the map; a block moves on the squares', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.byKey(const ValueKey('map-setup')));
    await tester.pumpAndSettle();
    expect(find.text('What shape is your home?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('use-template')));
    await tester.pumpAndSettle();
    var d = container.read(homeProvider).requireValue;
    final living = d.spaces.singleWhere((s) => s.name == 'Living room');
    expect(living.id, 'id0'); // the existing room took its place
    expect(living.plan, const PlanRect(6, 7, 9, 9));
    expect(find.text('Fit our home'), findsOneWidget);

    final block = find.byKey(ValueKey('house-room-${living.id}'));
    final cell = tester.getSize(block).width / 9;
    await tester.drag(block, Offset(cell * 2, 0));
    await tester.pumpAndSettle();
    d = container.read(homeProvider).requireValue;
    expect(d.space(living.id)!.plan, const PlanRect(8, 7, 9, 9));

    await tester.tap(find.byKey(const ValueKey('house-done')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('map-room-${living.id}')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-edit-shape')), findsOneWidget);
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
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    await tester.enterText(find.byType(TextField).first, 'band');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Band-aids ×20'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Living room'), findsWidgets);
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Flash'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('places outside the home get their own tabs', (tester) async {
    final container = await pumpApp(tester, location: '/spaces', prefs: {'language': 'en', 'feature.returns': true}, home: sampleHome());
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
    final fake = _FakeSuggest();
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome(), suggest: fake);
    await tester.enterText(find.byType(TextField).first, 'plas');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField).first, 'plaster');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('The fairy found it'), findsOneWidget);
    expect(find.text('Band-aids ×20'), findsOneWidget);
    expect(fake.calls, 1); // asked once, after typing paused
  });

  testWidgets('names found on the phone never ask the server', (tester) async {
    final fake = _FakeSuggest();
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome(), suggest: fake);
    await tester.enterText(find.byType(TextField).first, 'scissors');
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(fake.calls, 0);
  });

  testWidgets('past the daily AI allowance, search switches to words and offers the subscription', (tester) async {
    final fake = _FakeSuggest()..exhausted = true;
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome(), suggest: fake);
    await tester.enterText(find.byType(TextField).first, 'plaster');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();
    expect(find.text('The fairy found it'), findsNothing);
    expect(find.textContaining('Switching from AI search to word search.'), findsOneWidget);
    expect(find.textContaining('Subscribe'), findsOneWidget);
  });

  testWidgets('extras stay hidden until switched on in Settings', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    expect(find.byKey(const ValueKey('band-expiry')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('settings')).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('feature-expiry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feature-expiry')));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).expiryOn, isTrue);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('band-expiry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('band-expiry')), findsOneWidget);
  });

  testWidgets('things below their minimum go on the shopping list and can be refilled', (tester) async {
    final base = sampleHome();
    final soap = base.items.firstWhere((i) => i.name == 'AA batteries');
    final home = base.copyWith(items: [for (final i in base.items) i.id == soap.id ? i.copyWith(minQty: 10, updatedAt: i.updatedAt) : i]);
    final container = await pumpApp(tester, prefs: {'language': 'en', 'feature.lowStock': true}, home: home);
    await tester.ensureVisible(find.byKey(const ValueKey('band-low-stock')));
    await tester.pumpAndSettle();
    expect(find.text('Running low · 1'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('band-low-stock')), matching: find.text('See all')));
    await tester.pumpAndSettle();
    expect(find.textContaining('8 left · keep 10'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('refill-${soap.id}')));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.item(soap.id)!.qty, 10);
    expect(find.text('Nothing running low'), findsOneWidget);
  });

  testWidgets('the minimum amount is asked only with running-low alerts on', (tester) async {
    await pumpApp(tester, location: '/storage/$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    await tester.tap(find.byKey(const ValueKey('slot-$sampleTv-3')));
    await tester.pumpAndSettle();
    expect(find.text('Keep at least'), findsNothing);
    expect(find.text('Use by'), findsNothing);

    final container = await pumpApp(
      tester,
      location: '/storage/$sampleTv',
      prefs: {'language': 'en', 'feature.lowStock': true},
      home: sampleHome(),
    );
    await tester.tap(find.byKey(const ValueKey('slot-$sampleTv-3')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Tissues');
    await tester.ensureVisible(find.byKey(const ValueKey('min-qty-set')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('min-qty-set')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final tissues = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Tissues');
    expect(tissues.minQty, 1);
  });
}

class _FakeSuggest implements SmartSuggest {
  int calls = 0;

  /// Acts like the server's daily limit: no answers, and the switch to words.
  bool exhausted = false;
  final _out = ValueNotifier(false);

  @override
  ValueListenable<bool> get outOfQuota => _out;

  @override
  Future<({Pick? category, Pick? icon})?> classify(String name) async {
    calls++;
    return (category: const Pick('medicine', 0.93, [('medicine', 0.93)]), icon: const Pick('pill', 0.88, [('pill', 0.88), ('syrup', 0.1)]));
  }

  @override
  Future<Pick?> find(String query, List<String> itemNames) async {
    calls++;
    if (exhausted) {
      _out.value = true;
      return null;
    }
    return const Pick('Band-aids', 0.91, [('Band-aids', 0.91)]);
  }
}
