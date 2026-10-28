import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One typed decision from the server: the pick, how sure it is, and the
/// runners-up (best first).
class Pick {
  const Pick(this.choice, this.confidence, this.top);

  final String choice;
  final double confidence;
  final List<(String, double)> top;

  static Pick? fromJson(Object? j) {
    if (j is! Map) return null;
    final choice = j['choice'];
    if (choice is! String) return null;
    final top = <(String, double)>[
      for (final t in (j['top'] as List? ?? const []))
        if (t is Map && t['choice'] is String) (t['choice'] as String, (t['p'] as num?)?.toDouble() ?? 0),
    ];
    return Pick(choice, (j['confidence'] as num?)?.toDouble() ?? 0, top);
  }
}

/// Suggestions from the decision model (via the `decide` Cloud Function).
/// Every method returns null when suggestions are off, offline, slow or
/// failing; callers then use the on-phone rules.
abstract class SmartSuggest {
  Future<({Pick? category, Pick? icon})?> classify(String name);
  Future<Pick?> find(String query, List<String> itemNames);

  /// True once this month's fairy credits are used up; until next month
  /// everything answers from the on-phone rules (word search).
  ValueListenable<bool> get outOfQuota;

  /// This month's fairy credits: used, the allowance, and whether they are
  /// the shared home's. Null offline or without the server.
  Future<FairyCredits?> credits();
}

typedef FairyCredits = ({int used, int limit, bool shared});

class NoSuggest implements SmartSuggest {
  const NoSuggest();

  static final _never = ValueNotifier(false);

  @override
  ValueListenable<bool> get outOfQuota => _never;

  @override
  Future<({Pick? category, Pick? icon})?> classify(String name) async => null;

  @override
  Future<Pick?> find(String query, List<String> itemNames) async => null;

  @override
  Future<FairyCredits?> credits() async => null;
}

/// Firebase settings passed at build time (CI reads them from
/// google-services.json). All public values; empty in local builds and tests.
abstract final class FirebaseConfig {
  static const apiKey = String.fromEnvironment('FB_API_KEY');
  static const appId = String.fromEnvironment('FB_APP_ID');
  static const projectId = String.fromEnvironment('FB_PROJECT_ID');
  static const senderId = String.fromEnvironment('FB_SENDER_ID');

  static bool get available => apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;

  static FirebaseOptions get options =>
      const FirebaseOptions(apiKey: apiKey, appId: appId, projectId: projectId, messagingSenderId: senderId);
}

class FunctionsSuggest implements SmartSuggest {
  FunctionsSuggest();

  static const _timeout = Duration(seconds: 6);
  final _calls = <String, Future<Map?>>{};
  final _outOfQuota = ValueNotifier(false);
  DateTime? _outOn;

  @override
  ValueListenable<bool> get outOfQuota => _outOfQuota;

  bool get _outThisMonth {
    final now = DateTime.now();
    final day = _outOn;
    if (day != null && (day.year != now.year || day.month != now.month)) {
      _outOn = null;
      _outOfQuota.value = false; // a new month, new credits
    }
    return _outOn != null;
  }

  Future<Map?> _decide(Map<String, Object?> data, {bool always = false}) async {
    if (!always && _outThisMonth) return null;
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) await auth.signInAnonymously().timeout(_timeout);
      final fn = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('decide', options: HttpsCallableOptions(timeout: _timeout));
      final r = await fn.call<Object?>(data).timeout(_timeout);
      return r.data is Map ? r.data as Map : null;
    } on FirebaseFunctionsException catch (e) {
      // This month's credits are used: word search until the month ends.
      if (e.code == 'resource-exhausted') {
        _outOn = DateTime.now();
        _outOfQuota.value = true;
      }
      debugPrint('smart suggest unavailable: ${e.code}');
      return null;
    } catch (e) {
      debugPrint('smart suggest unavailable: ${e.runtimeType}');
      return null;
    }
  }

  @override
  Future<({Pick? category, Pick? icon})?> classify(String name) async {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    // Typing the same name again reuses the answer.
    final r = await _calls.putIfAbsent('c:$key', () => _decide({'task': 'classify', 'name': name.trim()}));
    if (r == null) {
      _calls.remove('c:$key');
      return null;
    }
    return (category: Pick.fromJson(r['category']), icon: Pick.fromJson(r['icon']));
  }

  @override
  Future<Pick?> find(String query, List<String> itemNames) async {
    if (query.trim().isEmpty || itemNames.isEmpty) return null;
    final r = await _decide({'task': 'find', 'query': query.trim(), 'items': itemNames});
    return r == null ? null : Pick.fromJson(r['item']);
  }

  @override
  Future<FairyCredits?> credits() async {
    final r = await _decide({'task': 'credits'}, always: true);
    if (r == null || r['used'] is! num || r['limit'] is! num) return null;
    return (used: (r['used'] as num).toInt(), limit: (r['limit'] as num).toInt(), shared: r['shared'] == true);
  }
}

/// Set in main() once Firebase is ready; stays [NoSuggest] in tests.
final smartSuggestBackendProvider = Provider<SmartSuggest>((ref) => const NoSuggest());

/// What screens use. AI suggestions are always on; past the daily allowance
/// the backend answers null and screens fall back to the on-phone rules.
final smartSuggestProvider = Provider<SmartSuggest>((ref) => ref.watch(smartSuggestBackendProvider));
