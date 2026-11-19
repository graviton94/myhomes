// Anonymous daily usage totals (user decision 2026-11-19, roadmap 4):
// how many things were added and how many searches found something or
// nothing, counted on the phone and sent once a day as plain numbers with
// a snapshot (things at home, a map or not, days since install). No names,
// search words or ids leave the phone (functions/main.py usage).
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings.dart';

enum UsageCount { added, found, empty }

/// Sends a day's numbers. [NoUsageSender] in tests and builds without Firebase.
abstract class UsageSender {
  Future<bool> send(Map<String, Object> report);
}

class NoUsageSender implements UsageSender {
  const NoUsageSender();

  @override
  Future<bool> send(Map<String, Object> report) async => false;
}

class FunctionsUsageSender implements UsageSender {
  @override
  Future<bool> send(Map<String, Object> report) async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) await auth.signInAnonymously().timeout(const Duration(seconds: 6));
      await FirebaseFunctions.instanceFor(region: 'us-central1').httpsCallable('usage').call<Object?>(report).timeout(const Duration(seconds: 8));
      return true;
    } catch (e) {
      debugPrint('usage: ${e.runtimeType}');
      return false;
    }
  }
}

final usageSenderProvider = Provider<UsageSender>((ref) => const NoUsageSender());

String _day(DateTime t) => '${t.year}-${t.month}-${t.day}';

/// Adds to today's count on this phone.
Future<void> countUsage(SharedPreferences prefs, UsageCount what, [int n = 1]) async {
  if (n <= 0) return;
  await prefs.setInt('stat.${what.name}', (prefs.getInt('stat.${what.name}') ?? 0) + n);
}

/// Once a day: sends what was counted since the last report with a snapshot
/// of the home, then starts counting again. Kept for later when offline.
Future<void> reportUsage(SharedPreferences prefs, UsageSender sender, HomeData d, {required bool account, required bool family, DateTime? now}) async {
  final today = now ?? DateTime.now();
  final first = prefs.getString('stat.since') ?? (await prefs.setString('stat.since', today.toIso8601String()), today.toIso8601String()).$2;
  if (prefs.getString('stat.sent') == _day(today)) return;
  final since = DateTime.tryParse(first) ?? today;
  final report = <String, Object>{
    for (final c in UsageCount.values) c.name: prefs.getInt('stat.${c.name}') ?? 0,
    'items': d.items.length,
    'map': d.spaces.any((s) => s.plan != null),
    'age': DateTime(today.year, today.month, today.day).difference(DateTime(since.year, since.month, since.day)).inDays.clamp(0, 30),
    'account': account,
    'family': family,
  };
  if (!await sender.send(report)) return;
  await prefs.setString('stat.sent', _day(today));
  for (final c in UsageCount.values) {
    await prefs.remove('stat.${c.name}');
  }
}

/// For widgets: count with the app's preferences.
void noteUsage(WidgetRef ref, UsageCount what, [int n = 1]) => countUsage(ref.read(prefsProvider), what, n);
