// The real app on a real Android (an emulator in CI, device.yml): first
// launch, a home from a template, the map, the tabs, Settings, and the map
// editor's gestures. Widget tests cover the rules; this checks that the app
// starts and its plugins answer on a device.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps until [f] shows (animations that never end rule out pumpAndSettle).
  Future<void> waitFor(WidgetTester tester, Finder f, {int seconds = 30}) async {
    for (var i = 0; i < seconds * 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (f.evaluate().isNotEmpty) return;
    }
    fail('never showed: $f');
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await waitFor(tester, f);
    await tester.tap(f.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('first launch to a home on the map, tabs, settings, map editing', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('language', 'en');
    await app.main();

    // Intro, then in as a guest.
    await tap(tester, find.text('Skip'));
    await tap(tester, find.text('Start without an account'));

    // "What is your home like?": a template lays the rooms out.
    await tap(tester, find.byKey(const ValueKey('use-template')));
    await waitFor(tester, find.byKey(const ValueKey('house-done')));

    // The editor: tap a room for its handles; double-tap empty floor for a new room.
    final room = find.byWidgetPredicate((w) => w.key is ValueKey<String> && RegExp(r'^house-room-[^-]+$').hasMatch((w.key! as ValueKey<String>).value));
    await waitFor(tester, room);
    final rooms = room.evaluate().length;
    await tester.tap(room.first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.endsWith('-bottomRight')), findsOneWidget);
    final canvas = tester.getRect(find.byKey(const ValueKey('plan-canvas')));
    final empty = Offset(canvas.left + canvas.width * 0.3, canvas.bottom - 40);
    await tester.tapAt(empty);
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tapAt(empty);
    await tester.pump(const Duration(milliseconds: 600));
    expect(room.evaluate().length, rooms + 1, reason: 'a double tap on empty floor adds a room');
    await tap(tester, find.byKey(const ValueKey('house-done')));

    // Home: the map with the rooms, and the search box.
    await waitFor(tester, find.byKey(const ValueKey('map-edit-shape')));
    expect(find.text('Living room'), findsWidgets);
    expect(find.byKey(const ValueKey('home-search')), findsOneWidget);

    // The other tabs and Settings open.
    await tap(tester, find.text('Put away'));
    await waitFor(tester, find.byKey(const ValueKey('add-barcode')));
    await tap(tester, find.text('Family'));
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, find.byKey(const ValueKey('settings')));
    await waitFor(tester, find.byKey(const ValueKey('settings-version')), seconds: 10).catchError((Object _) async {
      // Further down the list.
      await tester.scrollUntilVisible(find.byKey(const ValueKey('settings-version')), 400, scrollable: find.byType(Scrollable).first);
    });

    // What was made is saved on the phone.
    final docs = prefs.getKeys();
    expect(docs.contains('started') || docs.contains('flutter.started'), isTrue);
  });
}
