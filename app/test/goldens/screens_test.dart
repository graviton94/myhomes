@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Screenshots for review (not pixel comparisons in CI).
/// Record: flutter test --tags golden --update-goldens
/// Images land in `test/goldens/screens/NAME.png`.
void main() {
  setUpAll(loadAppFonts);

  const screens = {
    'home': '/',
    'settings': '/settings',
    'design': '/settings/design',
    'expiry': '/expiry',
  };
  const modes = {
    'en_light': {'language': 'en', 'theme': 'light'},
    'ko_dark': {'language': 'ko', 'theme': 'dark'},
    'ko_light': {'language': 'ko', 'theme': 'light'},
  };

  for (final s in screens.entries) {
    for (final m in modes.entries) {
      testWidgets('${s.key} ${m.key}', (tester) async {
        final tall = s.key == 'design';
        await pumpApp(tester, location: s.value, prefs: m.value, size: Size(360, tall ? 1500 : 780));
        await precacheFairies(tester);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/${s.key}_${m.key}.png'));
      });
    }
  }
}
