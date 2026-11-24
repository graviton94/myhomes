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

/// Pictures for the Play listing and the studio site.
/// 1. Raw screens of the real app (build/store_raw/, not kept).
/// 2. Promo shots, 1080 × 1920 (Play refuses a side more than twice the
///    other): a headline, the screen in a phone, the fairy.
/// 3. The 1024 × 500 feature graphic.
/// Record: flutter test test/goldens/store_shots_test.dart --update-goldens
/// Images land in `docs/store/`.
void main() {
  setUpAll(loadAppFonts);
  const phone = Size(360, 640);

  /// The sample home with a floor plan and a few more things, so screens look lived in.
  HomeData storeHome(bool ko) {
    String t(String en, String k) => ko ? k : en;
    var d = sampleHome(ko: ko);
    var n = 900;
    final ctx = Ctx(newId: () => 's${n++}', now: DateTime.now);
    d = applyTemplate(d, ctx, houseTemplates.first, (k) => (ko ? _koRooms : _enRooms)[k] ?? k);
    final today = DateTime.now();
    for (final (name, cat, qty) in [
      (t('Power strip', '멀티탭'), ItemCategory.electronics, 1),
      (t('Tape', '테이프'), ItemCategory.tools, 2),
      (t('Earphones', '이어폰'), ItemCategory.electronics, 1),
      (t('Charging cable', '충전 케이블'), ItemCategory.electronics, 3),
    ]) {
      d = addItem(d, ctx, containerId: sampleTv, name: name, category: cat, qty: qty).data;
    }
    for (final (name, days) in [(t('Tofu', '두부'), 1), (t('Spinach', '시금치'), 2)]) {
      d = addItem(
        d,
        ctx,
        containerId: sampleFridge,
        name: name,
        category: ItemCategory.food,
        expiresOn: DateTime(today.year, today.month, today.day + days),
      ).data;
    }
    return d;
  }

  HomeData moving(bool ko) {
    var n = 0;
    final ctx = Ctx(newId: () => 'mv${n++}', now: () => DateTime(2026, 11, 5));
    var d = startMoving(sampleHome(ko: ko), ctx, ko ? '이사 상자' : 'Moving boxes').data;
    final b1 = addMovingBox(d, ctx, ko ? '상자 1' : 'Box 1');
    d = setGoesTo(b1.data, b1.value.id, ko ? '주방' : 'Kitchen');
    final b2 = addMovingBox(d, ctx, ko ? '상자 2' : 'Box 2');
    d = setGoesTo(b2.data, b2.value.id, ko ? '거실' : 'Living room');
    final b3 = addMovingBox(d, ctx, ko ? '상자 3' : 'Box 3');
    d = b3.data.copyWith(containers: [for (final c in b3.data.containers) c.id == b3.value.id ? c.copyWith(unpacked: true) : c]);
    final cut = d.items.firstWhere((i) => i.category == ItemCategory.tools);
    final aa = d.items.firstWhere((i) => i.category == ItemCategory.household);
    d = moveItems(d, ctx, {cut.id: 1, aa.id: aa.qty}, b1.value.id);
    final band = d.items.firstWhere((i) => i.category == ItemCategory.medicine);
    return moveItems(d, ctx, {band.id: band.qty}, b2.value.id);
  }

  // 1. Raw screens.
  for (final lang in ['ko', 'en']) {
    testWidgets('raw screens ($lang)', (tester) async {
      final ko = lang == 'ko';
      final prefs = {'language': lang, 'theme': 'light', 'feature.expiry': true, 'feature.returns': true, 'feature.lowStock': true};
      final home = storeHome(ko);
      Future<void> raw(String name) async {
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../build/store_raw/$lang-$name.png'));
      }

      Future<void> open(String location, [HomeData? d]) async {
        await pumpApp(tester, location: location, prefs: prefs, home: d ?? home, size: phone);
        tester.view.padding = const FakeViewPadding(top: 72);
        tester.view.viewPadding = const FakeViewPadding(top: 72);
        await tester.pumpAndSettle();
      }

      await open('/');
      await precacheFairies(tester);
      await raw('map');

      // Picking things for a new home: a few already picked.
      await open('/fill?things=1');
      for (final i in [0, 1, 1, 3]) {
        await tester.tap(find.byType(FilterChip).at(i));
        await tester.pumpAndSettle();
      }
      await raw('fill');

      await open('/storage/$sampleTv');
      await raw('storage');

      // Putting away in one sentence: the place is picked from it.
      await open('/put');
      await tester.enterText(find.byType(TextField).first, ko ? '냉장고에 우유 2개랑 계란' : 'milk and 2 eggs in the fridge');
      FocusManager.instance.primaryFocus?.unfocus();
      await raw('add');

      await open('/expiry');
      await raw('expiry');

      await open('/moving', moving(ko));
      await raw('moving');
    });
  }

  // 2. Promo shots: headline on top, the screen in a phone below, the fairy beside it.
  final shots = <(String, String, String, FairyPose, int)>[
    ('map', '우리 집 그대로\n집 지도에 적어요', '방 · 가구 · 서랍 · 상자까지', FairyPose.hello, 0),
    ('fill', '고르기만 해도\n첫 집이 채워져요', '방마다 보관함 · 물건을 칩으로', FairyPose.cheer, 1),
    ('storage', '서랍 속까지\n한눈에 보여요', '칸마다 무엇이 몇 개 있는지', FairyPose.carry, 2),
    ('add', '한 문장이면\n넣기 끝', '“냉장고에 우유 2개랑 계란”', FairyPose.answer, 0),
    ('expiry', '기한 지나기 전에\n먼저 챙겨요', '다 쓴 건 장보기 목록에 쏙', FairyPose.worry, 1),
    ('moving', '이사할 때도\n상자마다 번호로', '상자 30개, 다 뜯지 않아도 돼요', FairyPose.carry, 2),
  ];
  const en = {
    'map': ('Your home,\nas a map', 'Rooms, furniture, drawers, boxes'),
    'fill': ('Just tap to\nfill your home', 'Spots and things for every room'),
    'storage': ('See inside\nevery drawer', "What's in each spot, and how many"),
    'add': ('One sentence\nputs it away', '"Milk and eggs in the fridge"'),
    'expiry': ('Use it before\nit expires', 'What runs out goes to shopping'),
    'moving': ('Moving?\nNumber the boxes', 'No need to open all 30'),
  };

  for (final lang in ['ko', 'en']) {
    testWidgets('promo shots ($lang)', (tester) async {
      final ko = lang == 'ko';
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      for (final (i, (name, koHead, koSub, pose, tone)) in shots.indexed) {
        final head = ko ? koHead : en[name]!.$1;
        final sub = ko ? koSub : en[name]!.$2;
        final screen = MemoryImage(File('build/store_raw/$lang-$name.png').readAsBytesSync());
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            home: Builder(
              builder: (context) {
                final c = HfColors.of(context);
                final (bg, round, ink) = switch (tone) {
                  0 => (c.accentSoft, c.primarySoft, c.primaryInk),
                  1 => (c.primarySoft, c.accentSoft, c.primaryInk),
                  _ => (c.secondarySoft, c.accentSoft, c.secondaryInk),
                };
                return Material(
                  color: bg,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        left: -120,
                        top: 300,
                        child: Container(
                          width: 600,
                          height: 600,
                          decoration: BoxDecoration(color: round, shape: BoxShape.circle),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        top: 44,
                        child: Column(
                          children: [
                            Text(
                              head,
                              textAlign: TextAlign.center,
                              style: AppType.display.copyWith(fontSize: ko ? 32 : 31, height: 1.25, color: c.fg),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              sub,
                              textAlign: TextAlign.center,
                              style: AppType.label.copyWith(fontSize: 15, color: ink),
                            ),
                          ],
                        ),
                      ),
                      // The real screen in a phone, running off the bottom.
                      Positioned(
                        left: 50,
                        right: 50,
                        top: 186,
                        child: Container(
                          height: 520,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: c.fg,
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 8))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image(image: screen, fit: BoxFit.fitWidth, alignment: Alignment.topCenter),
                          ),
                        ),
                      ),
                      Positioned(right: i.isEven ? -10 : null, left: i.isOdd ? -10 : null, bottom: 8, child: Fairy(pose, height: 112)),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.runAsync(() async {
          final context = tester.element(find.byType(Fairy));
          await precacheImage(AssetImage(Fairy.asset(pose, Brightness.light)), context);
          await precacheImage(screen, context);
        });
        await tester.pumpAndSettle();
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('../../../docs/store/$lang-${i + 1}-$name.png'));
      }
    });
  }
  // The feature graphic is drawn from ordered art (docs/asset-brief/store.py).
}

const _koRooms = {
  'bedroom2': '침실2',
  'bedroom3': '침실3',
  'master': '안방',
  'bath': '욕실',
  'masterBath': '안방 욕실',
  'entrance': '현관',
  'kitchen': '주방',
  'dressroom': '드레스룸',
  'living': '거실',
  'balcony': '발코니',
  'utility': '다용도실',
  'room': '방',
};

const _enRooms = {
  'bedroom2': 'Bedroom 2',
  'bedroom3': 'Bedroom 3',
  'master': 'Main bedroom',
  'bath': 'Bathroom',
  'masterBath': 'Main bath',
  'entrance': 'Entrance',
  'kitchen': 'Kitchen',
  'dressroom': 'Dressing room',
  'living': 'Living room',
  'balcony': 'Balcony',
  'utility': 'Utility room',
  'room': 'Room',
};
