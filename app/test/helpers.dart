import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/app.dart';
import 'package:homefairy/settings/settings.dart';
import 'package:homefairy/widgets/fairy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads every font in the app's FontManifest (our fonts and Material Icons)
/// so screenshots show real glyphs instead of test boxes.
Future<void> loadAppFonts() async {
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

/// Pumps the whole app at [location] with stored settings, at phone size.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  String location = '/',
  Map<String, Object> prefs = const {},
  Size size = const Size(360, 780),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: HomeFairyApp(initialLocation: location)),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Decodes the fairy images so they appear in screenshots.
Future<void> precacheFairies(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final pose in FairyPose.values) {
      for (final b in Brightness.values) {
        await precacheImage(AssetImage(Fairy.asset(pose, b)), context);
      }
    }
  });
  await tester.pumpAndSettle();
}
