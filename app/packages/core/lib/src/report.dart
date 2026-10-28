/// The monthly report (v0.9): what came in, what was used and what was
/// thrown away in one calendar month, from the activity log.
library;

import 'model.dart';

class MonthReport {
  const MonthReport({
    required this.year,
    required this.month,
    required this.added,
    required this.used,
    required this.discarded,
    required this.topUsed,
    required this.thrownOut,
    required this.byMember,
  });

  final int year;
  final int month;

  /// Quantities: things put in, used (partly or up), thrown away.
  final int added;
  final int used;
  final int discarded;

  /// Most-used names with their quantity, most first (at most 5).
  final List<(String, int)> topUsed;

  /// Thrown-away names with their quantity, most first (at most 5).
  final List<(String, int)> thrownOut;

  /// Changes per member uid in a shared home; empty on a phone alone.
  final Map<String, int> byMember;

  bool get isEmpty => added == 0 && used == 0 && discarded == 0;
}

/// The report for [year]-[month] from [log] (any order).
MonthReport monthReport(Iterable<LogEntry> log, int year, int month) {
  var added = 0, used = 0, discarded = 0;
  final usedBy = <String, int>{}, thrown = <String, int>{}, members = <String, int>{};
  for (final e in log) {
    if (e.at.year != year || e.at.month != month) continue;
    if (e.by != null) members[e.by!] = (members[e.by!] ?? 0) + 1;
    switch (e.type) {
      case LogType.add:
        added += e.qty;
      case LogType.use || LogType.usedUp:
        used += e.qty;
        usedBy[e.itemName] = (usedBy[e.itemName] ?? 0) + e.qty;
      case LogType.discard:
        discarded += e.qty;
        thrown[e.itemName] = (thrown[e.itemName] ?? 0) + e.qty;
      case LogType.move || LogType.edit || LogType.remove:
        break;
    }
  }
  List<(String, int)> top(Map<String, int> m) =>
      (m.entries.toList()..sort((a, b) => b.value != a.value ? b.value.compareTo(a.value) : a.key.compareTo(b.key)))
          .take(5)
          .map((e) => (e.key, e.value))
          .toList();
  return MonthReport(
    year: year,
    month: month,
    added: added,
    used: used,
    discarded: discarded,
    topUsed: top(usedBy),
    thrownOut: top(thrown),
    byMember: members,
  );
}
