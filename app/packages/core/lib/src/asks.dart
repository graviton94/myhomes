/// When the app asks about something later, instead of asking on the spot:
/// "가위는 다 사용했나요?" a while after scissors were taken out.
library;

import 'model.dart';

/// What "use (−)" does to an item.
enum UseKind {
  /// Goes down in number (tissues, milk).
  usedUp,

  /// Comes back to its place (scissors, a drill): it is "in use" meanwhile.
  returned,
}

/// The default for a category; each item may say otherwise.
UseKind useKindOf(ItemCategory category) => switch (category) {
  ItemCategory.food || ItemCategory.household || ItemCategory.medicine || ItemCategory.pets => UseKind.usedUp,
  ItemCategory.tools ||
  ItemCategory.clothes ||
  ItemCategory.electronics ||
  ItemCategory.papers ||
  ItemCategory.hobby ||
  ItemCategory.kids ||
  ItemCategory.other => UseKind.returned,
};

/// How long after taking something out the app asks whether it is back.
const askAfter = Duration(hours: 2);

/// Hour of the evening reminder for questions not answered in the app.
const askEveningHour = 20;

/// Whether to ask now, on opening the app, about something taken out at
/// [takenAt]. [askedAt] is the last time it was asked (null = never); the
/// same thing is asked at most once a day.
bool askOnOpen({required DateTime takenAt, required DateTime now, DateTime? askedAt}) {
  if (now.difference(takenAt) < askAfter) return false;
  return askedAt == null || now.difference(askedAt) >= const Duration(days: 1);
}

/// When to send the evening reminder for something taken out at [takenAt]:
/// 8 pm that day, or the next day when it was taken out too late for that.
/// Null when it was already asked in the app since it was taken out.
DateTime? askReminderAt({required DateTime takenAt, DateTime? askedAt}) {
  if (askedAt != null && !askedAt.isBefore(takenAt)) return null;
  final ready = takenAt.add(askAfter);
  var at = DateTime(ready.year, ready.month, ready.day, askEveningHour);
  if (at.isBefore(ready)) at = at.add(const Duration(days: 1));
  return at;
}
