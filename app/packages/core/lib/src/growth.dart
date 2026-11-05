/// The fairy grows as the home gets tidy (docs/fairy-growth-mockup.html).
/// Stars come from the home itself, so they need no storage of their own and
/// match on every family phone and after a backup: things put away, spots
/// filled, details written down, family. Weekly tasks add a few more, kept
/// on the phone. Stages never go back down (the app remembers the best).
library;

import 'features.dart';
import 'model.dart';

enum FairyStage { sprout, little, keeper, steady, guardian }

/// Stars needed for each stage.
const stageStars = {FairyStage.sprout: 0, FairyStage.little: 20, FairyStage.keeper: 50, FairyStage.steady: 120, FairyStage.guardian: 250};

FairyStage stageOf(int stars) => FairyStage.values.lastWhere((s) => stars >= stageStars[s]!);

/// Stars to the next stage, or null at the top.
int? starsToNext(int stars) {
  final s = stageOf(stars);
  if (s == FairyStage.guardian) return null;
  return stageStars[FairyStage.values[s.index + 1]]! - stars;
}

/// How full the way to the next stage is, 0..1 (1 at the top).
double stageProgress(int stars) {
  final s = stageOf(stars);
  if (s == FairyStage.guardian) return 1;
  final from = stageStars[s]!, to = stageStars[FairyStage.values[s.index + 1]]!;
  return (stars - from) / (to - from);
}

bool _hasDetail(Item i) => i.expiresOn != null || i.minQty != null || i.warrantyUntil != null || i.photoPath != null;

/// The home's stars: 1 per thing put away (up to 200), 2 per spot with
/// things in it, 1 per thing with a detail (date, minimum, warranty, photo;
/// up to 60), 5 per family member beyond the first, plus [taskStars] from
/// weekly tasks done.
int homeStars(HomeData d, {int members = 1, int taskStars = 0}) {
  final things = d.items.length.clamp(0, 200);
  final spots = d.containers.where((c) => d.items.any((i) => i.containerId == c.id)).length;
  final details = d.items.where(_hasDetail).length.clamp(0, 60);
  final family = (members - 1).clamp(0, 10) * 5;
  return things + spots * 2 + details + family + taskStars;
}

/// Monday 00:00 of [now]'s week.
DateTime weekStart(DateTime now) {
  final day = DateTime(now.year, now.month, now.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

enum WeekTaskKind {
  /// Something past its date: use it up, throw it out or change the date.
  clearExpired,

  /// An empty storage spot: put something in it.
  fillSpot,

  /// The shopping list: tick two lines.
  buyTwo,

  /// Put away five things.
  addFive,

  /// Write a detail (date, minimum, warranty, photo) on something.
  addDetail,
}

/// One of this week's three small tasks. [target] names the thing or spot
/// (an id), [baseline] is a count when the task was picked.
class WeekTask {
  const WeekTask(this.kind, {this.target, this.label, this.baseline = 0});

  final WeekTaskKind kind;
  final String? target;

  /// The thing's or spot's name, for the sentence on screen.
  final String? label;
  final int baseline;

  Map<String, Object?> toJson() => {'kind': kind.name, 'target': ?target, 'label': ?label, 'baseline': baseline};

  static WeekTask? fromJson(Map<String, Object?> j) {
    final kind = WeekTaskKind.values.where((k) => k.name == j['kind']).firstOrNull;
    if (kind == null) return null;
    return WeekTask(kind, target: j['target'] as String?, label: j['label'] as String?, baseline: (j['baseline'] as num?)?.toInt() ?? 0);
  }

  /// Stars for doing it.
  int get stars => switch (kind) {
    WeekTaskKind.clearExpired || WeekTaskKind.fillSpot || WeekTaskKind.addFive => 5,
    WeekTaskKind.buyTwo || WeekTaskKind.addDetail => 2,
  };
}

int _shoppingCount(HomeData d) => d.toBuy.fold(0, (n, b) => n + 1) + lowStock(d).length;

/// Up to three tasks that fit the home now, most useful first.
List<WeekTask> pickWeekTasks(HomeData d, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final out = <WeekTask>[];
  final expired = d.items.where((i) => i.expiresOn != null && i.expiresOn!.isBefore(today)).toList()
    ..sort((a, b) => a.expiresOn!.compareTo(b.expiresOn!));
  if (expired.isNotEmpty) out.add(WeekTask(WeekTaskKind.clearExpired, target: expired.first.id, label: expired.first.name));
  final empty = d.containers.where((c) => c.kind != StorageKind.furniture && d.items.every((i) => i.containerId != c.id)).toList();
  if (empty.isNotEmpty) out.add(WeekTask(WeekTaskKind.fillSpot, target: empty.first.id, label: empty.first.name));
  final shopping = _shoppingCount(d);
  if (shopping >= 2) out.add(WeekTask(WeekTaskKind.buyTwo, baseline: shopping));
  if (out.length < 3) out.add(WeekTask(WeekTaskKind.addFive, baseline: d.log.length));
  if (out.length < 3) out.add(WeekTask(WeekTaskKind.addDetail, baseline: d.items.where(_hasDetail).length));
  return out.take(3).toList();
}

/// Whether [t] is done in [d] (picked at [since], this week's start).
bool weekTaskDone(WeekTask t, HomeData d, DateTime since) => switch (t.kind) {
  WeekTaskKind.clearExpired => () {
    final i = d.item(t.target ?? '');
    final today = DateTime.now();
    return i == null || i.expiresOn == null || !i.expiresOn!.isBefore(DateTime(today.year, today.month, today.day));
  }(),
  WeekTaskKind.fillSpot => d.container(t.target ?? '') == null || d.items.any((i) => i.containerId == t.target),
  WeekTaskKind.buyTwo => _shoppingCount(d) <= t.baseline - 2,
  WeekTaskKind.addFive => d.log.where((e) => e.type == LogType.add && !e.at.isBefore(since)).length >= 5,
  WeekTaskKind.addDetail => d.items.where(_hasDetail).length > t.baseline,
};

enum Stamp {
  /// A spot with five or more things in it.
  firstDrawer,

  /// Two or more people share the home.
  family,

  /// Nothing thrown away in the last 30 days, with food in the home.
  fridgeKeeper,

  /// Three or more things with a minimum, and nothing to buy right now.
  shopper,

  /// A warranty written down.
  warranty,

  /// Five or more things with a photo.
  photos,
}

/// The stamps the home has earned, in [Stamp] order.
List<Stamp> stampsOf(HomeData d, DateTime now, {int members = 1}) => [
  if (d.containers.any((c) => d.items.where((i) => i.containerId == c.id).length >= 5)) Stamp.firstDrawer,
  if (members >= 2) Stamp.family,
  if (d.items.any((i) => i.category == ItemCategory.food) &&
      !d.log.any((e) => e.type == LogType.discard && now.difference(e.at).inDays < 30))
    Stamp.fridgeKeeper,
  if (d.items.where((i) => i.minQty != null).length >= 3 && _shoppingCount(d) == 0) Stamp.shopper,
  if (d.items.any((i) => i.warrantyUntil != null)) Stamp.warranty,
  if (d.items.where((i) => i.photoPath != null).length >= 5) Stamp.photos,
];
