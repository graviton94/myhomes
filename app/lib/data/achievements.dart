// Achievements on the phone: each medal's best value so far (values counted
// from the history can drop in a shared home, which only keeps recent
// entries), the counters for actions, and which medals were celebrated.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../settings/settings.dart';
import 'growth.dart';
import 'home_store.dart';
import 'household.dart';

typedef AchievementView = ({Achievement a, int value, Medal medal, int? next});

class AchievementsState {
  const AchievementsState(this.all, this.fresh);

  final List<AchievementView> all;

  /// Medals earned (or stepped up) that were not celebrated yet.
  final List<AchievementView> fresh;

  int get got => all.fold(0, (n, v) => n + stepsOf(v.a, v.medal));
  int get total => medalSteps;
  int count(Medal m) => all.where((v) => v.medal == m).length;
}

/// Bumped when a counter changes, so the medals are counted again.
class _Tick extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final _tickProvider = NotifierProvider<_Tick, int>(_Tick.new);

String _value(Achievement a) => 'ach.v.${a.name}';
String _shown(Achievement a) => 'ach.m.${a.name}';
String _count(Achievement a) => 'ach.n.${a.name}';
const _initKey = 'ach.init';

final achievementsProvider = Provider<AchievementsState?>((ref) {
  ref.watch(_tickProvider);
  final d = ref.watch(homeProvider).value;
  if (d == null) return null;
  final prefs = ref.read(prefsProvider);
  final members = ref.watch(householdProvider).value?.members.length ?? 1;
  final streak = ref.watch(growthProvider)?.weeksInRow ?? 0;
  final input = AchievementInput(
    d,
    now: DateTime.now(),
    members: members,
    bestStreak: streak,
    counters: {
      for (final a in Achievement.values)
        if (a.counted) a.name: prefs.getInt(_count(a)) ?? 0,
    },
  );
  // The first time: what the home already has counts as celebrated, so an
  // old home does not open with fifteen sheets.
  final first = !(prefs.getBool(_initKey) ?? false);
  final all = <AchievementView>[];
  final fresh = <AchievementView>[];
  for (final a in Achievement.values) {
    final now = achievementValue(a, input);
    final best = prefs.getInt(_value(a)) ?? 0;
    final value = now > best ? now : best;
    if (value != best) prefs.setInt(_value(a), value);
    final medal = medalFor(a, value);
    final v = (a: a, value: value, medal: medal, next: nextStep(a, value));
    all.add(v);
    if (first) {
      prefs.setInt(_shown(a), medal.index);
    } else if (medal.index > (prefs.getInt(_shown(a)) ?? 0)) {
      fresh.add(v);
    }
  }
  if (first) prefs.setBool(_initKey, true);
  return AchievementsState(all, fresh);
});

/// One more of an action that only the phone sees (found by search, ticked
/// off the shopping list, cooked, finished a move).
Future<void> countAchievement(WidgetRef ref, Achievement a) async {
  final prefs = ref.read(prefsProvider);
  await prefs.setInt(_count(a), (prefs.getInt(_count(a)) ?? 0) + 1);
  ref.read(_tickProvider.notifier).bump();
}

/// Stars a new medal gives.
const medalStars = 10;

/// The celebration was shown: remember the medal and add its stars.
Future<void> celebrated(WidgetRef ref, AchievementView v) async {
  final prefs = ref.read(prefsProvider);
  await prefs.setInt(_shown(v.a), v.medal.index);
  await addBonusStars(ref, medalStars);
  ref.read(_tickProvider.notifier).bump();
}
