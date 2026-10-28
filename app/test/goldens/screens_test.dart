@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'package:homefairy/widgets/hf_icons.g.dart';

import '../helpers.dart';

/// Screenshots for review (not pixel comparisons in CI).
/// Record: flutter test --tags golden --update-goldens
/// Images land in `test/goldens/screens/NAME.png`.
void main() {
  setUpAll(loadAppFonts);

  // name: (location, onboarded, with sample data)
  const screens = {
    'intro': ('/intro', false, false),
    'login': ('/login', false, false),
    'home_empty': ('/', true, false),
    'home': ('/', true, true),
    'spaces': ('/spaces', true, true),
    'space': ('/space/id1', true, true),
    'outside': ('/space/$sampleCar', true, true),
    'storage': ('/storage/$sampleTv', true, true),
    'item_new': ('/item/new?storage=$sampleFridge', true, true),
    'add': ('/add?storage=$sampleTv', true, true),
    'expiry': ('/expiry', true, true),
    'settings': ('/settings', true, false),
  };
  const modes = {
    'en_light': {'language': 'en', 'theme': 'light'},
    'ko_dark': {'language': 'ko', 'theme': 'dark'},
    'ko_light': {'language': 'ko', 'theme': 'light'},
  };

  for (final s in screens.entries) {
    for (final m in modes.entries) {
      testWidgets('${s.key} ${m.key}', (tester) async {
        final (location, onboarded, sample) = s.value;
        final tall = s.key == 'design';
        await pumpApp(
          tester,
          location: location,
          prefs: {...m.value, if (s.key == 'login') 'introSeen': true},
          onboarded: onboarded,
          home: sample ? sampleHome(ko: m.value['language'] == 'ko') : const HomeData(),
          size: Size(360, tall ? 1500 : 780),
        );
        await precacheFairies(tester);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/${s.key}_${m.key}.png'));
      });
    }
  }

  for (final m in modes.entries) {
    testWidgets('splash ${m.key}', (tester) async {
      await pumpApp(tester, prefs: m.value, splash: const Duration(seconds: 5));
      final context = tester.element(find.byType(Scaffold).first);
      await tester.runAsync(() => precacheImage(const AssetImage('assets/fairy/hello.webp'), context));
      await tester.pump(const Duration(milliseconds: 100));
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/splash_${m.key}.png'));
      await tester.pump(const Duration(seconds: 6));
    });
  }

  for (final m in modes.entries) {
    testWidgets('picker ${m.key}', (tester) async {
      await pumpApp(
        tester,
        location: '/storage/$sampleTv',
        prefs: m.value,
        home: sampleHome(ko: m.value['language'] == 'ko'),
      );
      await tester.longPress(find.byKey(const ValueKey('slot-$sampleTv-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.swap_horiz_rounded).last);
      await tester.pumpAndSettle();
      await precacheFairies(tester);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/picker_${m.key}.png'));
    });

    testWidgets('icons ${m.key}', (tester) async {
      await pumpApp(
        tester,
        location: '/item/new?storage=$sampleTv',
        prefs: m.value,
        home: sampleHome(ko: m.value['language'] == 'ko'),
      );
      await tester.ensureVisible(find.byIcon(Icons.apps_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.apps_rounded));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byIcon(HfIcons.bird),
        300,
        scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).last,
      );
      await tester.drag(find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).last, const Offset(0, 260));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/icons_${m.key}.png'));
    });
  }
}
