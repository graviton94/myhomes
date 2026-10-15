/// How urgent an item's expiry date is, counted in whole calendar days.
///
/// Badges always pair the colour with words ("Due tomorrow", "D-3"), so this
/// type carries the day count the UI needs to write them.
enum ExpiryLevel { overdue, today, tomorrow, soon, later }

class ExpiryStatus {
  const ExpiryStatus(this.level, this.daysLeft);

  final ExpiryLevel level;

  /// Days until the expiry date. Negative when overdue.
  final int daysLeft;

  /// Items that should appear in "Eat first" lists and notifications.
  bool get isUrgent => level != ExpiryLevel.later;

  @override
  bool operator ==(Object other) =>
      other is ExpiryStatus && other.level == level && other.daysLeft == daysLeft;

  @override
  int get hashCode => Object.hash(level, daysLeft);

  @override
  String toString() => 'ExpiryStatus($level, $daysLeft)';
}

/// Days counted as "soon" (D-2 and D-3). Matches the D-3 notification.
const int soonWindowDays = 3;

/// Classifies [expiresOn] relative to [today]. Only the calendar date matters;
/// the time of day of either value is ignored.
ExpiryStatus expiryStatus({required DateTime today, required DateTime expiresOn}) {
  final a = DateTime.utc(today.year, today.month, today.day);
  final b = DateTime.utc(expiresOn.year, expiresOn.month, expiresOn.day);
  final days = b.difference(a).inDays;
  final ExpiryLevel level;
  if (days < 0) {
    level = ExpiryLevel.overdue;
  } else if (days == 0) {
    level = ExpiryLevel.today;
  } else if (days == 1) {
    level = ExpiryLevel.tomorrow;
  } else if (days <= soonWindowDays) {
    level = ExpiryLevel.soon;
  } else {
    level = ExpiryLevel.later;
  }
  return ExpiryStatus(level, days);
}

/// Notification days before expiry: D-3, D-1 and the day itself.
const List<int> reminderOffsets = [3, 1, 0];

/// Dates (at [hour]:00 local) on which reminders fire for [expiresOn],
/// skipping any that are already before [now].
List<DateTime> reminderTimes({
  required DateTime now,
  required DateTime expiresOn,
  int hour = 9,
}) {
  final result = <DateTime>[];
  for (final offset in reminderOffsets) {
    final day = DateTime(expiresOn.year, expiresOn.month, expiresOn.day - offset, hour);
    if (day.isAfter(now)) result.add(day);
  }
  return result;
}
