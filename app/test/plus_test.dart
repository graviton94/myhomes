import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/shop.dart';
import 'package:homefairy/data/smart_suggest.dart';

import 'helpers.dart';

class _Shop implements Shop {
  final bought = <String>[];
  final _out = StreamController<ShopResult>.broadcast();

  @override
  Future<List<ShopProduct>> products() async => const [ShopProduct(ShopIds.plus, '₩3,300'), ShopProduct(ShopIds.dust, '₩2,200')];

  @override
  Future<void> buy(String id) async {
    bought.add(id);
    _out.add(ShopResult.done);
  }

  @override
  Future<void> restore() async {}

  @override
  Stream<ShopResult> get results => _out.stream;
}

class _Dust extends NoSuggest {
  @override
  Future<FairyCredits?> credits() async => (used: 150, limit: 150, shared: false, bonus: 40, plus: false);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('a guest is asked to sign in before buying', (tester) async {
    await pumpApp(tester, location: '/plus', prefs: {'language': 'en'}, shop: _Shop());
    expect(find.byKey(const ValueKey('plus-login')), findsOneWidget);
    expect(find.byKey(const ValueKey('plus-buy')), findsNothing);
  });

  testWidgets('Plus and a pouch of dust show the store price; buying says thank you', (tester) async {
    final shop = _Shop();
    await pumpApp(tester, location: '/plus', prefs: {'language': 'en'}, shop: shop, accounts: const SignedIn(), suggest: _Dust());
    expect(find.textContaining('₩3,300 a month', findRichText: true), findsOneWidget);
    expect(find.textContaining('Buy for ₩2,200', findRichText: true), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pack-buy')));
    await tester.pump();
    await tester.pump();
    expect(shop.bought, [ShopIds.dust]);
    expect(find.text('Thank you! The fairy dust is in.'), findsOneWidget);
    // Dust that was bought shows apart from the month's.
    await tester.scrollUntilVisible(find.byKey(const ValueKey('dust-card')), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Bought dust: 40', findRichText: true), findsOneWidget);
  });

  testWidgets('without the store the screen says so and nothing can be bought', (tester) async {
    await pumpApp(tester, location: '/plus', prefs: {'language': 'en'}, accounts: const SignedIn());
    expect(find.byKey(const ValueKey('plus-soon')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('plus-buy'))).onPressed, isNull);
  });
}
