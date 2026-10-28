@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:homefairy/features/onboarding/splash_screen.dart';
import 'package:homefairy/widgets/doodle.dart';
import 'package:homefairy/widgets/fairy_sketch.dart';

import '../helpers.dart';

/// Frames of the start-screen drawing, side by side, for the screenshot check.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('splash drawing frames', (tester) async {
    tester.view.physicalSize = const Size(1100, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const frames = [0.15, 0.3, 0.45, 0.6, 0.75, 0.85, 1.0];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFBF4F24),
          body: Row(
            children: [
              for (final t in frames)
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: 144,
                    height: 144,
                    decoration: const BoxDecoration(color: Color(0xFFFBE3D6), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: FairySketch(progress: AlwaysStoppedAnimation(t), height: 128),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    final context = tester.element(find.byType(Scaffold));
    await tester.runAsync(() => precacheImage(const AssetImage('assets/fairy/hello.webp'), context));
    await tester.pumpAndSettle();
    await expectLater(find.byType(Scaffold), matchesGoldenFile('screens/splash_frames.png'));
  });

  testWidgets('intro pages 2 and 3', (tester) async {
    await pumpApp(tester, location: '/intro', onboarded: false, prefs: {'language': 'ko', 'theme': 'light'});
    await precacheFairies(tester);
    for (final page in [2, 3]) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/intro_page${page}_ko_light.png'));
    }
  });

  testWidgets('room with furniture, sections and boxes', (tester) async {
    var n = 0;
    final ctx = Ctx(newId: () => 'k${n++}', now: () => DateTime(2026, 10, 28));
    final room = addSpace(const HomeData(), ctx, '거실', icon: 'living');
    final tv = addFurniture(room.data, ctx, spaceId: room.value.id, name: 'TV장', icon: 'tv', sections: ['윗칸', '왼쪽 서랍', '아래 칸']);
    final secs = sectionsOf(tv.data, tv.value.id);
    var d = tv.data;
    for (final (i, name) in ['공유기', '리모컨'].indexed) {
      d = addItem(d, ctx, containerId: secs[0].id, name: name, qty: i + 1, icon: i == 0 ? 'router' : 'tv').data;
    }
    for (final name in ['AA 건전지', '가위', '줄자']) {
      d = addItem(d, ctx, containerId: secs[1].id, name: name, icon: iconsFromName(name).firstOrNull).data;
    }
    final game = addBox(d, ctx, spaceId: room.value.id, name: '상자 1 · 게임기', parentId: secs[2].id, icon: 'game');
    d = addItem(game.data, ctx, containerId: game.value.id, name: '조이콘').data;
    final camp = addBox(d, ctx, spaceId: room.value.id, name: '상자 2 · 캠핑', icon: 'box');
    d = addItem(camp.data, ctx, containerId: camp.value.id, name: '랜턴').data;
    await pumpApp(tester, location: '/space/${room.value.id}', prefs: {'language': 'ko', 'theme': 'light'}, home: d, size: const Size(360, 1100));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/room_furniture_ko_light.png'));
  });

  testWidgets('start screen while popping and at rest', (tester) async {
    final container = await pumpApp(tester, location: '/splash', prefs: {'language': 'ko', 'theme': 'light'}, splash: const Duration(milliseconds: 300));
    final context = tester.element(find.byType(SplashScreen));
    await tester.runAsync(() => precacheImage(const AssetImage('assets/fairy/hello.webp'), context));
    await tester.pump(const Duration(milliseconds: 4500));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/start_pop_ko_light.png'));
    await tester.pump(const Duration(milliseconds: 2000));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/start_end_ko_light.png'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tapAt(const Offset(180, 400));
    await tester.pump(const Duration(milliseconds: 600));
    expect(container.read(splashDoneProvider), isTrue);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('doodles: megaphone and pencil, large', (tester) async {
    tester.view.physicalSize = const Size(700, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFFBF6EF),
          body: Row(
            children: [
              const Padding(padding: EdgeInsets.all(20), child: DoodleMegaphone(size: 200)),
              Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(color: Color(0xFFFBE3D6), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const FairySketch(progress: AlwaysStoppedAnimation(0.42), height: 290),
              ),
            ],
          ),
        ),
      ),
    );
    await expectLater(find.byType(Scaffold), matchesGoldenFile('screens/doodles.png'));
  });
}
