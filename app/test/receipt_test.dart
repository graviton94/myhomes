import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:homefairy/data/home_store.dart';
import 'package:homefairy/data/smart_suggest.dart';
import 'package:homefairy/features/item/receipt_screen.dart';

import 'helpers.dart';

const receiptRows = [
  '001 Jasmine rice 2kg 12,900 1 12,900',
  '002 Kitchen towel 4,900 2 9,800',
  'Plastic bag 490',
  'Gift wrap 3,000 1 3,000',
  'TOTAL 26,190',
];

/// Rows as if the phone had read a receipt (the camera can't run in tests).
Future<void> showReceipt(WidgetTester tester, List<String> rows) async {
  (tester.state(find.byType(ReceiptScreen)) as dynamic).showRows(rows);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a read receipt lists the things bought; unticked ones stay out', (tester) async {
    final container = await pumpApp(tester, location: '/receipt?storage=$sampleTv', prefs: {'language': 'en'}, home: sampleHome());
    expect(find.byKey(const ValueKey('receipt-camera')), findsOneWidget);
    await showReceipt(tester, receiptRows);
    expect(find.byKey(const ValueKey('receipt-line-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('receipt-line-3')), findsNothing);
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('receipt-line-2')), matching: find.byType(Checkbox)));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('receipt-save')));
    await tester.pumpAndSettle();
    final names = {for (final i in container.read(homeProvider).requireValue.itemsIn(sampleTv)) i.name: i.qty};
    expect(names['Jasmine rice 2kg'], 1);
    expect(names['Kitchen towel'], 2);
    expect(names.containsKey('Gift wrap'), isFalse);
  });

  testWidgets('the fairy tidies the list: names picked, refills join, non-products unticked', (tester) async {
    final fairy = _TidyFairy();
    final container = await pumpApp(
      tester,
      location: '/receipt?storage=$sampleTv',
      prefs: {'language': 'en'},
      home: sampleHome(),
      suggest: fairy,
    );
    await showReceipt(tester, receiptRows);
    await tester.tap(find.byKey(const ValueKey('receipt-tidy')));
    await tester.pumpAndSettle();
    // What was sent: candidates from code, and the home's similar names.
    expect(fairy.asked.first.names, ['Jasmine rice 2kg', 'Jasmine rice']);
    expect(find.text('Jasmine rice'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('receipt-save')));
    await tester.pumpAndSettle();
    final names = {for (final i in container.read(homeProvider).requireValue.itemsIn(sampleTv)) i.name: i.qty};
    expect(names['Jasmine rice'], 1);
    expect(names.containsKey('Gift wrap'), isFalse);
  });
}

/// Answers like the server would: line 0 renamed, line 2 is not a product.
class _TidyFairy implements SmartSuggest {
  final asked = <ReceiptAsk>[];

  @override
  Future<List<ReceiptPick>?> receipt(List<ReceiptAsk> lines) async {
    asked.addAll(lines);
    return [
      for (final (i, l) in lines.indexed) (keep: i == 2 ? 0.05 : 0.95, name: l.names.last, same: 0.0, item: null),
    ];
  }

  @override
  Future<({Pick? category, Pick? icon})?> classify(String name) async => null;

  @override
  Future<Pick?> find(String query, List<String> itemNames) async => null;

  @override
  Future<FairyCredits?> credits() async => null;

  @override
  ValueListenable<bool> get outOfQuota => ValueNotifier(false);
}
