@Tags(['golden'])
library;

import 'dart:io';

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

      await tester.enterText(find.byKey(const ValueKey('home-search')), lang == 'ko' ? '가위' : 'scissors');
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

  // The feature graphic: what the app does, at a glance. A question on the
  // left, the fairy's answer in a real search screen on the right.
  for (final lang in ['ko', 'en']) {
    testWidgets('feature graphic ($lang)', (tester) async {
      tester.view.physicalSize = const Size(1024, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ko = lang == 'ko';
      final screen = MemoryImage(File('../docs/store/$lang-2-search.png').readAsBytesSync());
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          home: Builder(
            builder: (context) {
              final c = HfColors.of(context);
              return Material(
                color: c.accentSoft,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // A warm round behind the phone.
                    Positioned(
                      right: -80,
                      top: -120,
                      child: Container(
                        width: 620,
                        height: 620,
                        decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                      ),
                    ),
                    // Words.
                    Positioned(
                      left: 64,
                      top: 0,
                      bottom: 0,
                      width: 470,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ko ? '우리집요정' : 'Home Fairy', style: AppType.title.copyWith(fontSize: 30, color: c.primaryInk)),
                          const SizedBox(height: 10),
                          Text(
                            ko ? '가위 어디 뒀지?\n요정이 바로 찾아 줘요' : 'Where are the scissors?\nThe fairy knows.',
                            style: AppType.display.copyWith(fontSize: ko ? 54 : 50, color: c.fg, height: 1.22),
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            spacing: 10,
                            children: [
                              for (final t in ko ? ['물건 찾기', '수납 정리', '유통기한'] : ['Find things', 'Organize', 'Use-by dates'])
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(999)),
                                  child: Text(t, style: AppType.label.copyWith(fontSize: 20, color: c.accentInk)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // The real search screen, in a phone, running off the bottom.
                    Positioned(
                      right: 120,
                      top: 34,
                      child: Transform.rotate(
                        angle: 0.06,
                        child: Container(
                          width: 270,
                          height: 520,
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: c.fg,
                            borderRadius: BorderRadius.circular(38),
                            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image(image: screen, fit: BoxFit.cover, alignment: Alignment.topCenter),
                          ),
                        ),
                      ),
                    ),
                    // The fairy, pointing her wand at the answer.
                    const Positioned(right: 330, bottom: -6, child: Fairy(FairyPose.found, height: 230)),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.runAsync(() async {
        final context = tester.element(find.byType(Fairy));
        await precacheImage(AssetImage(Fairy.asset(FairyPose.found, Brightness.light)), context);
        await precacheImage(screen, context);
      });
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../../docs/store/$lang-feature.png'));
    });
  }
}
