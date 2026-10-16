import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:homefairy/app.dart';
import 'package:homefairy/data/home_store.dart';
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
/// [onboarded] skips the intro and login screens. [home] is the starting data.
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  String location = '/',
  Map<String, Object> prefs = const {},
  Size size = const Size(360, 780),
  bool onboarded = true,
  HomeData home = const HomeData(),
  Duration splash = Duration.zero,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({if (onboarded) ...{'introSeen': true, 'started': true}, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    homeRepositoryProvider.overrideWithValue(MemoryHomeRepository(home)),
    splashDelayProvider.overrideWithValue(splash),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: HomeFairyApp(initialLocation: location)),
  );
  // The loading screen spins until data arrives, so only settle once it has.
  if (splash == Duration.zero) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
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

/// Deterministic ids and clock for building sample data.
Ctx testCtx() {
  var n = 0;
  return Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 1, 1));
}

/// A small home: Living room (TV stand, Drawer) and Kitchen (Fridge).
/// Use-by dates are relative to today so badges stay stable.
HomeData sampleHome() {
  final ctx = testCtx();
  final today = DateTime.now();
  DateTime inDays(int d) => DateTime(today.year, today.month, today.day + d);
  var d = const HomeData();
  final living = addSpace(d, ctx, 'Living room');
  d = living.data;
  final kitchen = addSpace(d, ctx, 'Kitchen');
  d = kitchen.data;
  final tv = addContainer(d, ctx, spaceId: living.value.id, name: 'TV stand');
  d = tv.data;
  final drawer = addContainer(d, ctx, spaceId: living.value.id, name: 'Drawer');
  d = drawer.data;
  final fridge = addContainer(d, ctx, spaceId: kitchen.value.id, name: 'Fridge');
  d = fridge.data;
  d = addItem(d, ctx, containerId: tv.value.id, name: 'AA batteries', category: ItemCategory.household, qty: 8).data;
  d = addItem(d, ctx, containerId: tv.value.id, name: 'Remote', category: ItemCategory.other).data;
  d = addItem(d, ctx, containerId: tv.value.id, name: 'Scissors', category: ItemCategory.tools).data;
  d = addItem(d, ctx, containerId: drawer.value.id, name: 'Band-aids', category: ItemCategory.medicine, qty: 20, expiresOn: inDays(200)).data;
  d = addItem(d, ctx, containerId: fridge.value.id, name: 'Milk', category: ItemCategory.food, qty: 2, expiresOn: inDays(1)).data;
  d = addItem(d, ctx, containerId: fridge.value.id, name: 'Eggs', category: ItemCategory.food, qty: 10, expiresOn: inDays(3)).data;
  d = addItem(d, ctx, containerId: fridge.value.id, name: 'Yogurt', category: ItemCategory.food, qty: 4, expiresOn: inDays(-1)).data;
  return d;
}

/// Ids in [sampleHome].
const sampleTv = 'id2';
const sampleDrawer = 'id3';
const sampleFridge = 'id4';
