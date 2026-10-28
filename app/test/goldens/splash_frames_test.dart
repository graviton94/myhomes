@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
