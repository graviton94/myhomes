import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/achievements.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/features/achievements/achievements_screen.dart';
import 'package:homefairy/widgets/medal.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('an old home opens without a flood; a step up is new once', (tester) async {
    final c = await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    final first = c.read(achievementsProvider)!;
    expect(first.fresh, isEmpty);
    final things = first.all.singleWhere((v) => v.a == Achievement.things);
    expect(things.medal, Medal.bronze); // 47 things in the sample home
    // Three more makes 50: silver.
    await c.read(homeProvider.notifier).apply((d, ctx) => addItem(d, ctx, containerId: sampleTv, name: 'Tape', qty: 3).data);
    await tester.pumpAndSettle();
    final now = c.read(achievementsProvider)!;
    expect(now.fresh.map((v) => (v.a, v.medal)), contains((Achievement.things, Medal.silver)));
  });

  testWidgets('the screen shows every medal; a medal opens its steps', (tester) async {
    await pumpApp(tester, location: '/achievements', prefs: {'language': 'en'}, home: sampleHome());
    expect(find.byType(AchievementsScreen), findsOneWidget);
    expect(find.byType(MedalView), findsNWidgets(Achievement.values.length));
    await tester.tap(find.byKey(const ValueKey('ach-things')));
    await tester.pumpAndSettle();
    expect(find.text('Busy hands'), findsWidgets);
    expect(find.text('Silver'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ach-kind-care')));
    await tester.pumpAndSettle();
    expect(find.byType(MedalView), findsNWidgets(AchKind.care.items.length));
  });
}
