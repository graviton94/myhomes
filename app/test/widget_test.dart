import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/settings/settings.dart';

import 'helpers.dart';

void main() {
  testWidgets('starts in English on the home tab', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'});
    expect(find.text('My home'), findsOneWidget);
    expect(find.text('Snap & add'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('switching language to Korean updates the screen', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'});
    await container.read(settingsProvider.notifier).setLanguage(AppLanguage.ko);
    await tester.pumpAndSettle();
    expect(find.text('우리 집'), findsOneWidget);
    expect(find.text('찍어서 넣기'), findsOneWidget);
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

  testWidgets('quick actions say they are coming later', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'});
    await tester.tap(find.text('Snap & add'));
    await tester.pump();
    expect(find.text('Coming in a later build.'), findsOneWidget);
  });

  testWidgets('bottom navigation opens the use-by tab', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'});
    await tester.tap(find.text('Use by'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing is about to expire'), findsOneWidget);
  });
}
