@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/app_update.dart';

import '../helpers.dart';

/// The store's new version: the toast in each step, and Settings › 앱 정보.
/// Images land in `test/goldens/screens/update_*.png`.
void main() {
  setUpAll(loadAppFonts);

  const steps = {
    'available': UpdateState(UpdatePhase.available, code: 1004),
    'downloading': UpdateState(UpdatePhase.downloading, progress: 0.42),
    'downloaded': UpdateState(UpdatePhase.downloaded),
  };
  for (final s in steps.entries) {
    for (final lang in ['ko', 'en']) {
      testWidgets('update ${s.key} $lang', (tester) async {
        await pumpApp(
          tester,
          prefs: {'language': lang, 'theme': 'light'},
          home: sampleHome(ko: lang == 'ko'),
          updater: FakeUpdates(s.value),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await precacheFairies(tester);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/update_${s.key}_$lang.png'));
      });
    }
  }

  testWidgets('update settings ko', (tester) async {
    await pumpApp(tester, location: '/settings', prefs: const {'language': 'ko', 'theme': 'light'}, updater: FakeUpdates(steps['downloading']!));
    await tester.scrollUntilVisible(find.byKey(const ValueKey('settings-version')), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/update_settings_ko.png'));
  });
}
