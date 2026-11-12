import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:homefairy/data/home_store.dart';

import 'helpers.dart';

void main() {
  testWidgets('the map shows the home where it is, not from the corner of the squares', (tester) async {
    HomeData placed(int dx, int dy) {
      final base = sampleHome();
      var d = base;
      for (final (i, s) in base.spaces.where((s) => !s.outside).indexed) {
        d = setRoomPlan(d, s.id, PlanRect(dx + i * 6, dy, 6, 6));
      }
      return d;
    }

    await pumpApp(tester, prefs: {'language': 'en'}, home: placed(0, 0));
    final first = find.byKey(const ValueKey('map-room-id0'));
    final at = tester.getRect(first);
    // The same home drawn in the middle of the squares looks the same on the map.
    await pumpApp(tester, prefs: {'language': 'en'}, home: placed(9, 12));
    expect(tester.getRect(first), at);
  });

  testWidgets('empty rooms left with the same name are cleared once; "sofa" finds an icon', (tester) async {
    var n = 0;
    final ctx = Ctx(newId: () => 'tw${n++}', now: () => DateTime(2026, 11, 12));
    final a = addSpace(const HomeData(), ctx, 'Living room');
    final box = addContainer(a.data, ctx, spaceId: a.value.id, name: 'By the sofa');
    final twins = addSpace(addSpace(box.data, ctx, 'Living room').data, ctx, 'Living room').data;
    final container = await pumpApp(tester, prefs: {'language': 'en'}, home: twins);
    await tester.pumpAndSettle();
    final d = container.read(homeProvider).requireValue;
    expect(d.spaces.map((s) => s.name), ['Living room']);
    expect(d.containers.single.name, 'By the sofa');
    // A spot named after the sofa is offered the sofa, and a search for it finds it.
    expect(suggestIcons('소파 옆', IconKind.storage).first, 'living');
    expect(searchIcons('소파'), contains('living'));
    expect(searchIcons('sofa'), contains('living'));
  });
}
