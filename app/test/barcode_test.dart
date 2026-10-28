import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/barcode.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/features/item/barcode_add.dart';
import 'package:homefairy/features/item/sentence_add_screen.dart';

import 'helpers.dart';

class _Lookup implements BarcodeLookup {
  @override
  Future<String?> nameOf(String code) async => code == '8801045522678' ? 'Jin ramen' : null;
}

/// The Put tab's element doubles as a WidgetRef for calling the flow directly
/// (the camera itself can't run in tests).
Future<void> _scan(WidgetTester tester, String code) async {
  final element = tester.element(find.byType(SentenceAddScreen));
  handleBarcode(element, element as WidgetRef, code, storageId: sampleTv);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a new food barcode opens the form named, and the second scan adds one more', (tester) async {
    final container = await pumpApp(tester, location: '/put', prefs: {'language': 'en'}, home: sampleHome(), barcodes: _Lookup());
    await _scan(tester, '8801045522678');
    expect(find.widgetWithText(TextField, 'Jin ramen'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final ramen = container.read(homeProvider).requireValue.items.singleWhere((i) => i.name == 'Jin ramen');
    expect(ramen.barcode, '8801045522678');

    await _scan(tester, '8801045522678');
    expect(find.text('One more'), findsOneWidget);
    await tester.tap(find.text('One more'));
    await tester.pumpAndSettle();
    expect(container.read(homeProvider).requireValue.item(ramen.id)!.qty, 2);
  });

  testWidgets('an unknown barcode still opens the form, empty, and says so', (tester) async {
    await pumpApp(tester, location: '/put', prefs: {'language': 'en'}, home: sampleHome(), barcodes: _Lookup());
    await _scan(tester, '0000000000000');
    expect(find.text('Not in the food list. Type the name.'), findsOneWidget);
  });
}
