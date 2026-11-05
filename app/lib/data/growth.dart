import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../settings/settings.dart';
import 'home_store.dart';
import 'household.dart';

/// What the fairy sheet shows.
class GrowthView {
  const GrowthView({
    required this.stars,
    required this.stage,
    required this.toNext,
    required this.progress,
    required this.tasks,
    required this.done,
    required this.weeksInRow,
    required this.stamps,
    required this.leveledUp,
  });

  final int stars;

  /// The best stage reached (it never goes back down).
  final FairyStage stage;
  final int? toNext;
  final double progress;
  final List<WeekTask> tasks;
  final List<bool> done;
  final int weeksInRow;
  final List<Stamp> stamps;

  /// A new stage reached since the fairy last said so.
  final bool leveledUp;
}

const _weekKey = 'growth.week', _tasksKey = 'growth.tasks', _doneKey = 'growth.done', _starsKey = 'growth.taskStars';
const _bestKey = 'growth.best', _shownKey = 'growth.shown', _streakKey = 'growth.streak';

/// The fairy's growth, worked out from the home whenever it changes. This
/// week's tasks and the stars they gave stay on the phone (prefs).
class GrowthController extends Notifier<GrowthView?> {
  @override
  GrowthView? build() {
    final d = ref.watch(homeProvider).value;
    if (d == null) return null;
    final members = ref.watch(householdProvider).value?.members.length ?? 1;
    final prefs = ref.read(prefsProvider);
    final now = DateTime.now();
    final week = weekStart(now).toIso8601String();

    var tasks = [
      for (final t in (jsonDecode(prefs.getString(_tasksKey) ?? '[]') as List))
        if (t is Map) ?WeekTask.fromJson(t.cast<String, Object?>()),
    ];
    var counted = (prefs.getStringList(_doneKey) ?? const []).toSet();
    var streak = prefs.getInt(_streakKey) ?? 0;
    if (prefs.getString(_weekKey) != week) {
      // A new week: the last one counts toward the streak if all its tasks were done.
      final allDone = tasks.isNotEmpty && counted.length >= tasks.length;
      streak = allDone ? streak + 1 : 0;
      tasks = pickWeekTasks(d, now);
      counted = {};
      prefs
        ..setString(_weekKey, week)
        ..setString(_tasksKey, jsonEncode([for (final t in tasks) t.toJson()]))
        ..setStringList(_doneKey, const [])
        ..setInt(_streakKey, streak);
    }
    final since = weekStart(now);
    final done = [for (final t in tasks) weekTaskDone(t, d, since)];
    var taskStars = prefs.getInt(_starsKey) ?? 0;
    for (final (i, t) in tasks.indexed) {
      if (done[i] && !counted.contains('$i')) {
        counted.add('$i');
        taskStars += t.stars;
      }
    }
    prefs
      ..setStringList(_doneKey, counted.toList())
      ..setInt(_starsKey, taskStars);

    final stars = homeStars(d, members: members, taskStars: taskStars);
    final reached = stageOf(stars);
    final best = FairyStage.values[(prefs.getInt(_bestKey) ?? 0).clamp(0, FairyStage.values.length - 1)];
    final stage = reached.index > best.index ? reached : best;
    if (stage != best) prefs.setInt(_bestKey, stage.index);
    final shown = prefs.getInt(_shownKey) ?? 0;
    return GrowthView(
      stars: stars,
      stage: stage,
      toNext: starsToNext(stars),
      progress: stageProgress(stars),
      tasks: tasks,
      done: done,
      weeksInRow: streak + (done.isNotEmpty && done.every((x) => x) ? 1 : 0),
      stamps: stampsOf(d, now, members: members),
      // The first stage is where everyone starts: nothing to celebrate.
      leveledUp: stage.index > shown && stage.index > 0,
    );
  }

  /// The level-up sheet was shown.
  void celebrated() {
    final v = state;
    if (v == null) return;
    ref.read(prefsProvider).setInt(_shownKey, v.stage.index);
    state = GrowthView(
      stars: v.stars,
      stage: v.stage,
      toNext: v.toNext,
      progress: v.progress,
      tasks: v.tasks,
      done: v.done,
      weeksInRow: v.weeksInRow,
      stamps: v.stamps,
      leveledUp: false,
    );
  }
}

final growthProvider = NotifierProvider<GrowthController, GrowthView?>(GrowthController.new);

/// Stars from outside this week's tasks (a new medal), kept with the task stars.
Future<void> addBonusStars(WidgetRef ref, int n) async {
  final prefs = ref.read(prefsProvider);
  await prefs.setInt(_starsKey, (prefs.getInt(_starsKey) ?? 0) + n);
  ref.invalidate(growthProvider);
}
