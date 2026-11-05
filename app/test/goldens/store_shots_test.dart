@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/design/theme.dart';
import 'package:homefairy/design/tokens.g.dart';
import 'package:homefairy/widgets/fairy.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../helpers.dart';

/// Pictures for the Play listing and the studio site, from the real screens:
/// phone shots at 1080 × 1920 (Play refuses a side more than twice the other)
/// and the 1024 × 500 feature graphic.
/// Record: flutter test test/goldens/store_shots_test.dart --update-goldens
/// Images land in `docs/store/`.
void main() {
  setUpAll(loadAppFonts);
  const phone = Size(360, 640);

  Future<void> bars(WidgetTester tester) async {
    tester.view.padding = const FakeViewPadding(top: 72, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 48);
  }

  HomeData moving() {
    var n = 0;
    final ctx = Ctx(newId: () => 'mv${n++}', now: () => DateTime(2026, 11, 5));
    var d = startMoving(sampleHome(ko: true), ctx, '이사 상자').data;
    final b1 = addMovingBox(d, ctx, '상자 1');
    d = setGoesTo(b1.data, b1.value.id, '주방');
    final cut = d.items.firstWhere((i) => i.name == '가위');
    final remote = d.items.firstWhere((i) => i.name == '리모컨');
    return moveItems(d, ctx, {cut.id: 1, remote.id: 1}, b1.value.id);
  }

  for (final lang in ['ko', 'en']) {
    testWidgets('store shots ($lang)', (tester) async {
      final prefs = {'language': lang, 'theme': 'light'};
      final home = sampleHome(ko: lang == 'ko');
      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../../docs/store/$lang-$name.png'));
      }

      await pumpApp(tester, prefs: prefs, home: home, size: phone);
      await bars(tester);
      await precacheFairies(tester);
      await shot('1-map');

      await tester.enterText(find.byKey(const ValueKey('home-search')), lang == 'ko' ? '건전지' : 'batteries');
      await shot('2-search');

      await pumpApp(tester, location: '/storage/$sampleTv', prefs: prefs, home: home, size: phone);
      await bars(tester);
      await shot('3-storage');

      await pumpApp(tester, location: '/item/new?storage=$sampleTv', prefs: prefs, home: home, size: phone);
      await bars(tester);
      await shot('4-add');

      if (lang == 'ko') {
        await pumpApp(tester, location: '/moving/box/mv1', prefs: prefs, home: moving(), size: phone);
        await bars(tester);
        await shot('5-moving');
      }
    });
  }

  for (final lang in ['ko', 'en']) {
    testWidgets('feature graphic ($lang)', (tester) async {
      tester.view.physicalSize = const Size(1024, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ko = lang == 'ko';
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          home: Builder(
            builder: (context) {
              final c = HfColors.of(context);
              return Material(
                color: c.accentSoft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 72),
                  child: Row(
                    children: [
                      const Fairy(FairyPose.found, height: 360),
                      const SizedBox(width: 48),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ko ? '우리집요정' : 'Home Fairy', style: AppType.display.copyWith(fontSize: 76, color: c.fg, height: 1.1)),
                            const SizedBox(height: 16),
                            Text(
                              ko ? '물건이 어디 있는지\n요정이 기억해요' : 'Where everything is,\nthe fairy remembers',
                              style: AppType.title.copyWith(fontSize: 38, color: c.accentInk, height: 1.35),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(AssetImage(Fairy.asset(FairyPose.found, Brightness.light)), tester.element(find.byType(Fairy))),
      );
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../../docs/store/$lang-feature.png'));
    });
  }
}
