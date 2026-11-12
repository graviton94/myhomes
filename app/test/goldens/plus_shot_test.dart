@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homefairy/data/shop.dart';
import 'package:homefairy/data/smart_suggest.dart';

import '../helpers.dart';

class _Shop extends NoShop {
  @override
  Future<List<ShopProduct>> products() async => const [ShopProduct(ShopIds.plus, '₩3,300'), ShopProduct(ShopIds.dust, '₩2,200')];
}

class _Dust extends NoSuggest {
  @override
  Future<FairyCredits?> credits() async => (used: 138, limit: 150, shared: false, bonus: 0, plus: false);
}

/// "요정 가루 더 받기" for review. Images land in `test/goldens/screens/plus_*.png`.
void main() {
  setUpAll(loadAppFonts);
  for (final lang in ['ko', 'en']) {
    testWidgets('plus $lang', (tester) async {
      await pumpApp(
        tester,
        location: '/plus',
        prefs: {'language': lang, 'theme': 'light'},
        accounts: const SignedIn(),
        shop: _Shop(),
        suggest: _Dust(),
        size: const Size(360, 1000),
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('screens/plus_$lang.png'));
    });
  }
}
