import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadAppFonts);

  // User request: with the keyboard up, 저장 and 저장하고 계속 sit right
  // above it, so a typed name is saved without closing the keyboard.
  testWidgets('the item form\'s save buttons stay above the keyboard', (tester) async {
    await pumpApp(tester, location: '/item/new?storage=$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    tester.view.viewInsets = const FakeViewPadding(bottom: 900); // a tall keyboard, in physical pixels
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final keyboardTop = tester.view.physicalSize.height / tester.view.devicePixelRatio - 900 / tester.view.devicePixelRatio;
    for (final label in ['Save', 'Save & add next']) {
      final button = find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      expect(button, findsOneWidget, reason: label);
      expect(tester.getRect(button).bottom, lessThanOrEqualTo(keyboardTop + 0.5), reason: label);
    }
  });
}
