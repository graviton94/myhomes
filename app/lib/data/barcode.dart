import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A food product's name from its barcode (food-safety ministry, through the
/// `barcode` Cloud Function, which shares answers between everyone).
abstract interface class BarcodeLookup {
  /// The product name, or null when it isn't food we know or the server can't be reached.
  Future<String?> nameOf(String code);
}

class NoBarcodeLookup implements BarcodeLookup {
  const NoBarcodeLookup();

  @override
  Future<String?> nameOf(String code) async => null;
}

class FunctionsBarcodeLookup implements BarcodeLookup {
  final _fn = FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('barcode');

  @override
  Future<String?> nameOf(String code) async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) await auth.signInAnonymously().timeout(const Duration(seconds: 6));
      final r = await _fn.call<Object?>({'code': code}).timeout(const Duration(seconds: 8));
      final name = (r.data as Map?)?['name'];
      return name is String && name.trim().isNotEmpty ? name.trim() : null;
    } catch (e) {
      debugPrint('barcode lookup: ${e.runtimeType}');
      return null;
    }
  }
}

/// Overridden in main() when Firebase is available.
final barcodeLookupProvider = Provider<BarcodeLookup>((ref) => const NoBarcodeLookup());
