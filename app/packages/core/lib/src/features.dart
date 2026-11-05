/// Add-on features people switch on in Settings (v0.7 step 6): use-by
/// reminders, getting lent things back, and a shopping list for consumables.
library;

import 'asks.dart';
import 'expiry.dart';
import 'model.dart';
import 'ops.dart';

/// Consumables below their minimum, fewest first relative to the minimum.
List<Item> lowStock(HomeData d) {
  final out = d.items.where((i) => i.minQty != null && i.qty < i.minQty!).toList()
    ..sort((a, b) => (a.qty - a.minQty!).compareTo(b.qty - b.minQty!));
  return out;
}

/// Dated items due within [days] days (past dates included), soonest first.
List<(Item, ExpiryStatus)> dueWithin(HomeData d, DateTime today, int days) =>
    byExpiry(d, today).where((e) => e.$2.daysLeft <= days).toList();

enum ReminderKind { expiry, returnBy, inUse, warranty }

/// One phone notification to schedule.
class Reminder {
  const Reminder(this.id, this.at, this.kind, this.name, this.daysLeft);

  /// Stable per thing and day, so rescheduling replaces rather than duplicates.
  final int id;
  final DateTime at;
  final ReminderKind kind;
  final String name;
  final int daysLeft;
}

/// Notifications to schedule after [now]: an evening question for each thing
/// in use (see asks.dart), and D-3, D-1 and the day itself at
/// [hour]:00 for dated items (when [expiry] is on) and for lent things'
/// return dates (when [returns] is on). At most [limit], soonest first
/// (phones cap how many alarms an app may hold).
List<Reminder> remindersFrom(HomeData d, DateTime now, {required bool expiry, required bool returns, int hour = 9, int limit = 48}) {
  final out = <Reminder>[];
  void add(String key, String name, DateTime due, ReminderKind kind) {
    for (final at in reminderTimes(now: now, expiresOn: due, hour: hour)) {
      final day = DateTime(at.year, at.month, at.day);
      final left = DateTime(due.year, due.month, due.day).difference(day).inDays;
      out.add(Reminder(Object.hash(key, at.year, at.month, at.day) & 0x7fffffff, at, kind, name, left));
    }
  }

  if (expiry) {
    for (final i in d.items.where((i) => i.expiresOn != null)) {
      add('i:${i.id}', i.name, i.expiresOn!, ReminderKind.expiry);
    }
  }
  if (returns) {
    for (final s in d.containers.where((s) => s.returnBy != null)) {
      add('r:${s.id}', s.name, s.returnBy!, ReminderKind.returnBy);
    }
  }
  // Warranties: a month before the last day, and on it.
  for (final i in d.items.where((i) => i.warrantyUntil != null)) {
    final end = i.warrantyUntil!;
    for (final at in [DateTime(end.year, end.month - 1, end.day, hour), DateTime(end.year, end.month, end.day, hour)]) {
      if (at.isAfter(now)) {
        final left = DateTime(end.year, end.month, end.day).difference(DateTime(at.year, at.month, at.day)).inDays;
        out.add(Reminder(Object.hash('w:${i.id}', at.year, at.month, at.day) & 0x7fffffff, at, ReminderKind.warranty, i.name, left));
      }
    }
  }
  // Things taken out and not back: one evening question each.
  for (final i in d.items.where((i) => i.inUseSince != null)) {
    final at = askReminderAt(takenAt: i.inUseSince!, askedAt: i.askedAt);
    if (at != null && at.isAfter(now)) out.add(Reminder(Object.hash('u:${i.id}', at.day) & 0x7fffffff, at, ReminderKind.inUse, i.name, 0));
  }
  out.sort((a, b) => a.at.compareTo(b.at));
  return out.take(limit).toList();
}

/// The valuables list (moving house, an insurance claim, after-sales):
/// things with a warranty or a price, warranties ending soonest first.
List<Item> valuables(HomeData d) {
  final out = d.items.where((i) => i.warrantyUntil != null || i.price != null).toList()
    ..sort((a, b) {
      final x = a.warrantyUntil, y = b.warrantyUntil;
      if (x != null && y != null) return x.compareTo(y);
      if (x != null) return -1;
      if (y != null) return 1;
      return (b.price ?? 0).compareTo(a.price ?? 0);
    });
  return out;
}

/// What the valuables add up to, in won.
int valuablesTotal(HomeData d) => d.items.fold(0, (n, i) => n + (i.price ?? 0) * (i.qty < 1 ? 1 : i.qty));
