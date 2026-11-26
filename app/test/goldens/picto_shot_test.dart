@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/widgets/icon_chooser.dart';

import '../helpers.dart';

/// The icon picker with the ordered pictograms, for review: screens/picto_ko.png.
void main() {
  setUpAll(loadAppFonts);
  testWidgets('pictograms ko', (tester) async {
    await pumpApp(tester, prefs: {'language': 'ko', 'theme': 'light'}, size: const Size(360, 740));
    pickIcon(tester.element(find.byType(Scaffold).first), selected: null);
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/picto_ko.png'));
  });
}
