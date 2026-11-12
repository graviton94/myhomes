// Buying in Google Play: Plus (a monthly subscription, ten times the fairy
// dust) and a pack of dust (one-time). The store takes the money; our
// server asks Google whether the purchase is real before giving anything
// (functions/main.py purchase), so nothing is trusted from the phone.
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// The two things on sale; ids as made in Play Console.
abstract final class ShopIds {
  static const plus = 'plus_monthly';
  static const dust = 'dust_500';
}

/// One thing on sale with the store's own price text ("₩3,300").
class ShopProduct {
  const ShopProduct(this.id, this.price);

  final String id;
  final String price;
}

/// How a purchase ended.
enum ShopResult { done, cancelled, failed }

abstract class Shop {
  /// What the store sells now; empty when the store cannot be reached or
  /// the products are not set up.
  Future<List<ShopProduct>> products();

  /// Opens the store's payment sheet; the result comes on [results].
  Future<void> buy(String id);

  /// Brings back a Plus bought before (a new phone, a reinstall).
  Future<void> restore();

  Stream<ShopResult> get results;
}

/// Tests and builds without the store.
class NoShop implements Shop {
  const NoShop();

  @override
  Future<List<ShopProduct>> products() async => const [];

  @override
  Future<void> buy(String id) async {}

  @override
  Future<void> restore() async {}

  @override
  Stream<ShopResult> get results => const Stream.empty();
}

class PlayShop implements Shop {
  PlayShop() {
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) => debugPrint('shop: ${e.runtimeType}'));
  }

  final _iap = InAppPurchase.instance;
  final _out = StreamController<ShopResult>.broadcast();
  final _details = <String, ProductDetails>{};
  late final StreamSubscription<List<PurchaseDetails>> _sub;

  @override
  Stream<ShopResult> get results => _out.stream;

  @override
  Future<List<ShopProduct>> products() async {
    try {
      if (!await _iap.isAvailable()) return const [];
      final r = await _iap.queryProductDetails({ShopIds.plus, ShopIds.dust});
      for (final p in r.productDetails) {
        _details[p.id] = p;
      }
      return [
        for (final id in const [ShopIds.plus, ShopIds.dust])
          if (_details[id] != null) ShopProduct(id, _details[id]!.price),
      ];
    } catch (e) {
      debugPrint('shop products: ${e.runtimeType}');
      return const [];
    }
  }

  @override
  Future<void> buy(String id) async {
    final p = _details[id];
    if (p == null) {
      _out.add(ShopResult.failed);
      return;
    }
    try {
      final param = PurchaseParam(productDetails: p);
      // The server uses the dust up after giving it, so it can be bought again.
      id == ShopIds.dust ? await _iap.buyConsumable(purchaseParam: param, autoConsume: false) : await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      debugPrint('shop buy: ${e.runtimeType}');
      _out.add(ShopResult.failed);
    }
  }

  @override
  Future<void> restore() async {
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('shop restore: ${e.runtimeType}');
      _out.add(ShopResult.failed);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.canceled:
          _out.add(ShopResult.cancelled);
        case PurchaseStatus.error:
          _out.add(ShopResult.failed);
        case PurchaseStatus.purchased || PurchaseStatus.restored:
          final ok = await _give(p);
          // Told the store only once the server has given it; otherwise the
          // store hands the purchase back next time and it is tried again.
          if (ok && p.pendingCompletePurchase) await _iap.completePurchase(p);
          _out.add(ok ? ShopResult.done : ShopResult.failed);
      }
    }
  }

  Future<bool> _give(PurchaseDetails p) async {
    try {
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('purchase')
          .call<Object?>({'product': p.productID, 'token': p.verificationData.serverVerificationData});
      return true;
    } catch (e) {
      debugPrint('shop give: ${e is FirebaseFunctionsException ? e.code : e.runtimeType}');
      return false;
    }
  }

  void dispose() {
    _sub.cancel();
    _out.close();
  }
}

/// Overridden in main() with [PlayShop] on Android when Firebase is there.
final shopProvider = Provider<Shop>((ref) => const NoShop());

/// What is on sale, asked once per visit to the Plus screen.
final shopProductsProvider = FutureProvider.autoDispose<List<ShopProduct>>((ref) => ref.watch(shopProvider).products());
