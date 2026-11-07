import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy_core/homefairy_core.dart';
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
}
