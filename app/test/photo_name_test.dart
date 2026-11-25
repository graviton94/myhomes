import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/smart_suggest.dart';

import 'helpers.dart';

class _Eyes extends NoSuggest {
  int looks = 0;

  @override
  Future<FairyCredits?> credits() async => (used: 0, limit: 150, shared: false, bonus: 0, plus: false, plusUntil: null);

  @override
  Future<List<PhotoThing>?> photo(List<int> jpeg) async {
    looks++;
    return const [(key: 'scissors', name: 'Scissors', p: 0.9), (key: 'tape', name: 'Tape', p: 0.6), (key: 'cat', name: 'Cat', p: 0.2)];
  }
}

// A 1×1 PNG, so the square can draw the photo.
const _png = [
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, //
  120, 156, 99, 248, 15, 4, 0, 9, 251, 3, 253, 227, 85, 242, 156, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
];

void main() {
  setUpAll(loadAppFonts);

  // User request: a photo in the item form should lead somewhere. The fairy
  // names what it shows, only when asked (it costs dust, shown on the button).
  testWidgets('the fairy names what the photo shows, on asking', (tester) async {
    final file = File('${Directory.systemTemp.createTempSync('hf').path}/p.png')..writeAsBytesSync(_png);
    var d = sampleHome();
    final item = d.items.first;
    d = d.copyWith(items: [for (final i in d.items) i.id == item.id ? i.copyWith(photoPath: file.path, updatedAt: i.updatedAt) : i]);
    final eyes = _Eyes();
    final container = await pumpApp(tester, location: '/item/${item.id}/edit', prefs: {'language': 'en'}, home: d, suggest: eyes);
    await tester.pumpAndSettle();
    expect(eyes.looks, 0); // never on its own
    // Reading the photo file is real work: let it run.
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('photo-ask')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(eyes.looks, 1);
    expect(find.byKey(const ValueKey('photo-seen-Scissors')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-seen-Tape')), findsOneWidget);
    expect(find.byKey(const ValueKey('photo-seen-Cat')), findsNothing); // too unsure
    await tester.tap(find.byKey(const ValueKey('photo-seen-Scissors')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.item(item.id)!.name, 'Scissors');
  });
}
