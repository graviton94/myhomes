@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../helpers.dart';

/// The map editor with a room picked, for review: `screens/map_edit_*.png`.
void main() {
  setUpAll(loadAppFonts);
  for (final lang in ['ko', 'en']) {
    testWidgets('map edit $lang', (tester) async {
      var d = sampleHome();
      var n = 0;
      final ctx = Ctx(newId: () => 'r${n++}', now: () => DateTime(2026, 11, 25));
      for (final name in lang == 'ko' ? ['주방', '욕실'] : ['Kitchen', 'Bath']) {
        d = addSpace(d, ctx, name).data;
      }
      final rooms = d.spaces.where((s) => !s.outside).toList();
      const at = [PlanRect(0, 0, 8, 7), PlanRect(8, 0, 5, 5), PlanRect(0, 7, 7, 6), PlanRect(8, 5, 4, 4)];
      for (final (i, s) in rooms.take(4).indexed) {
        d = setRoomPlan(d, s.id, at[i]);
      }
      await pumpApp(tester, location: '/house/edit', prefs: {'language': lang, 'theme': 'light'}, home: d, size: const Size(360, 740));
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 48);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('house-room-${rooms[3].id}')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/map_edit_$lang.png'));
    });
  }
}
