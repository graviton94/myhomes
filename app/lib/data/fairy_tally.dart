import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings.dart';
import 'accounts.dart';

/// Sends a number of rule answers to the account's dust; true once sent.
typedef TallySender = Future<bool> Function(int count);

/// Overridden in main() when Firebase is available.
final tallySenderProvider = Provider<TallySender>((ref) => (_) async => true);

/// Questions the fairy answered with the phone's own rules (names, initials).
/// They cost a little dust too (user request): one for every five, counted
/// on the server. Kept here and sent five at a time; never stops an answer,
/// and guests (no dust of their own) are not counted.
class FairyTally extends Notifier<int> {
  static const key = 'fairy.tally';
  static const batch = 5;

  @override
  int build() => ref.read(prefsProvider).getInt(key) ?? 0;

  Future<void> used() async {
    if (ref.read(accountProvider).value == null) return;
    final prefs = ref.read(prefsProvider);
    final n = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, n);
    state = n;
    if (n < batch) return;
    if (await ref.read(tallySenderProvider)(n)) {
      final left = (prefs.getInt(key) ?? n) - n;
      await prefs.setInt(key, left);
      if (ref.mounted) state = left;
    }
  }
}

final fairyTallyProvider = NotifierProvider<FairyTally, int>(FairyTally.new);
