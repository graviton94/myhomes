import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/growth.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/settings/settings.dart';
import 'package:homefairy_core/homefairy_core.dart';

import 'helpers.dart';
import 'report_test.dart' show reportHome;

HomeData reportHomeForCard() => reportHome();

void main() {
  testWidgets('the badge shows the stage and stars; the sheet the tasks and stamps', (tester) async {
    await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome());
    expect(find.byKey(const ValueKey('fairy-badge')), findsOneWidget);
    expect(find.textContaining('Little · '), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fairy-badge')));
    await tester.pumpAndSettle();
    expect(find.text("The fairy's story"), findsOneWidget);
    expect(find.text('Little fairy'), findsOneWidget);
    // Yogurt is past its date: sorting it out is this week's first task.
    expect(find.text('Sort out the Yogurt past its date'), findsOneWidget);
    expect(find.byKey(const ValueKey('stamp-firstDrawer')), findsOneWidget);
  });

  testWidgets('a task done adds its stars; a new stage is celebrated once', (tester) async {
    final container = await pumpApp(tester, prefs: {'language': 'en'}, home: sampleHome(), asks: true);
    await tester.pumpAndSettle();
    // Opening asks about the yogurt first: throw it out, which also does the task.
    await tester.tap(find.text('Threw it away'));
    await tester.pumpAndSettle();
    expect(find.text('Now a Little fairy!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('level-up-close')));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.items.where((i) => i.name == 'Yogurt'), isEmpty);
    await tester.tap(find.byKey(const ValueKey('fairy-badge')));
    await tester.pumpAndSettle();
    final box = tester.widget<ListTile>(find.byKey(const ValueKey('week-task-0')));
    expect((box.leading! as Icon).icon, Icons.check_box_rounded);
    // Once: the stage it was shown for is remembered, so it is not shown again.
    expect(container.read(prefsProvider).getInt('growth.shown'), 1);
    expect(container.read(growthProvider)!.leveledUp, isFalse);
  });

  testWidgets('the share card opens from the report with this month and the stage', (tester) async {
    await pumpApp(tester, location: '/report', prefs: {'language': 'en'}, home: reportHomeForCard());
    await tester.scrollUntilVisible(find.byKey(const ValueKey('report-card')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('report-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('share-card-send')), findsOneWidget);
    expect(find.textContaining('Our home in'), findsOneWidget);
    expect(find.textContaining(' fairy'), findsWidgets); // the stage's name
  });
}
