/// Achievements: medals for keeping the home, in up to three steps
/// (bronze one star, silver two, gold three). What the home's state shows is
/// counted from it; what only happens as an action (finding by search,
/// ticking the shopping list, cooking, finishing a move) is counted on the
/// phone and passed in [AchievementInput.counters].
library;

import 'expiry.dart';
import 'model.dart';

enum Achievement {
  home('home', [1]),
  drawers('drawer', [5, 20, 50]),
  things('box', [10, 50, 200]),
  finder('scissors', [5, 30, 100]),
  fridge('freezer', [1]),
  thrifty('egg', [10, 50, 150]),
  bought('store', [5, 20, 50]),
  family('family', [1]),
  moves('suitcase', [10, 50, 150]),
  cook('soup', [1, 5, 20]),
  moving('toolbox', [1]),
  warranty('card', [1, 5, 15]),
  streak('star', [3, 8, 20]),
  photos('camera', [5, 20, 50]),
  dated('fruit', [5, 20, 50]);

  const Achievement(this.icon, this.steps);

  /// Icon key (design/icons) drawn in the middle of the medal.
  final String icon;

  /// The value each step needs; one step is a single gold medal.
  final List<int> steps;

  /// Counters kept on the phone for these.
  bool get counted => this == finder || this == bought || this == cook || this == moving;
}

/// How far a medal is: 0 = not yet, steps.length = done.
enum Medal { none, bronze, silver, gold }

class AchievementInput {
  const AchievementInput(this.d, {this.members = 1, this.counters = const {}, this.bestStreak = 0, required this.now});

  final HomeData d;
  final int members;

  /// Phone counters by [Achievement.name].
  final Map<String, int> counters;
  final int bestStreak;
  final DateTime now;
}

/// The current value toward [a].
int achievementValue(Achievement a, AchievementInput x) {
  final d = x.d;
  final today = DateTime(x.now.year, x.now.month, x.now.day);
  return switch (a) {
    Achievement.home => d.spaces.any((s) => s.plan != null) ? 1 : 0,
    Achievement.drawers => d.containers.where((c) => d.items.any((i) => i.containerId == c.id)).length,
    Achievement.things => d.items.fold(0, (n, i) => n + i.qty),
    Achievement.photos => d.items.where((i) => i.photoPath != null).length,
    Achievement.dated => d.items.where((i) => i.expiresOn != null).length,
    Achievement.warranty => d.items.where((i) => i.warrantyUntil != null).length,
    Achievement.fridge =>
      d.items.where((i) => i.category == ItemCategory.food).length >= 5 &&
              !d.items.any(
                (i) =>
                    i.category == ItemCategory.food &&
                    i.expiresOn != null &&
                    expiryStatus(today: today, expiresOn: i.expiresOn!).daysLeft < 0,
              ) &&
              !d.log.any((e) => e.type == LogType.discard && x.now.difference(e.at).inDays < 30)
          ? 1
          : 0,
    Achievement.thrifty => d.log.where((e) => e.type == LogType.use || e.type == LogType.usedUp).length,
    Achievement.moves => d.log.where((e) => e.type == LogType.move).length,
    Achievement.family => x.members >= 2 ? 1 : 0,
    Achievement.streak => x.bestStreak,
    Achievement.finder || Achievement.bought || Achievement.cook || Achievement.moving => x.counters[a.name] ?? 0,
  };
}

/// The medal [value] earns for [a]: one step is gold at once; three steps
/// go bronze, silver, gold.
Medal medalFor(Achievement a, int value) {
  final reached = a.steps.where((s) => value >= s).length;
  if (reached == 0) return Medal.none;
  if (a.steps.length == 1) return Medal.gold;
  return Medal.values[reached];
}

/// The next step's value, or null when the medal is gold.
int? nextStep(Achievement a, int value) => a.steps.where((s) => value < s).firstOrNull;

/// Every medal there is to earn (a step each).
int get medalSteps => Achievement.values.fold(0, (n, a) => n + a.steps.length);

/// Steps earned for a medal (gold of a one-step achievement is one step).
int stepsOf(Achievement a, Medal m) => m == Medal.none ? 0 : (a.steps.length == 1 ? 1 : m.index);
