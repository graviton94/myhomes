import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/features/moving/moving_screen.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);
  const ko = {'language': 'ko'};

  testWidgets('a move from the map: box, pack from home, find it, unpack, finish', (tester) async {
    final c = await pumpApp(tester, prefs: ko, home: sampleHome(ko: true));
    HomeData d() => c.read(homeProvider).requireValue;

    // Started only from "공간 추가".
    await tester.ensureVisible(find.byKey(const ValueKey('map-add-room')));
    await tester.tap(find.byKey(const ValueKey('map-add-room')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-place-moving')));
    await tester.pumpAndSettle();
    expect(find.byType(MovingScreen), findsOneWidget);
    expect(movingSpace(d()), isNotNull);

    // A new box, going to the kitchen.
    await tester.tap(find.byKey(const ValueKey('moving-add-box')));
    await tester.pumpAndSettle();
    expect(find.byType(MovingBoxScreen), findsOneWidget);
    final box = movingBoxes(d()).single;
    await tester.tap(find.byKey(const ValueKey('goes-to-주방')));
    await tester.pumpAndSettle();
    expect(d().container(box.id)!.goesTo, '주방');

    // Pack the scissors from home.
    await tester.tap(find.byKey(const ValueKey('moving-pack-home')));
    await tester.pumpAndSettle();
    final scissors = d().items.firstWhere((i) => i.name == '가위');
    await tester.enterText(find.byKey(const ValueKey('pack-search')), '가위');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('pack-${scissors.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pack-do')));
    await tester.pumpAndSettle();
    expect(d().item(scissors.id)!.containerId, box.id);

    // Search says which box and where it goes.
    await pumpApp(tester, prefs: ko, home: d());
    await tester.enterText(find.byKey(const ValueKey('home-search')), '가위');
    await tester.pumpAndSettle();
    expect(find.textContaining(keepWords('주방에 갈 상자')), findsOneWidget);

    // Unpack it into the TV stand: the last box, so the move asks to finish.
    final c2 = await pumpApp(tester, location: '/moving/box/${box.id}', prefs: ko, home: d());
    await tester.tap(find.byKey(ValueKey('moving-item-${scissors.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('moving-unpack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pick-$sampleTv')));
    await tester.pumpAndSettle();
    final after = c2.read(homeProvider).requireValue;
    expect(after.item(scissors.id)!.containerId, sampleTv);
    expect(after.container(box.id)!.unpacked, isTrue);
    expect(find.byKey(const ValueKey('answer-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('answer-0')));
    await tester.pumpAndSettle();
    expect(movingSpace(c2.read(homeProvider).requireValue), isNull);
  });

  testWidgets('the move cannot be finished while boxes hold things', (tester) async {
    final ctx = testCtx();
    var home = startMoving(sampleHome(ko: true), ctx, '이사 상자').data;
    final b = addMovingBox(home, ctx, '상자 1');
    home = addItem(b.data, ctx, containerId: b.value.id, name: '이불').data;
    final c = await pumpApp(tester, location: '/moving', prefs: ko, home: home);
    await tester.tap(find.byKey(const ValueKey('moving-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(keepWords('이사 마치기')));
    await tester.pumpAndSettle();
    expect(movingSpace(c.read(homeProvider).requireValue), isNotNull);
    expect(find.byKey(const ValueKey('answer-0')), findsNothing);
  });
}
