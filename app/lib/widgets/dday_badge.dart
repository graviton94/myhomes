import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';

/// Use-by badge. Always pairs colour with words so status is never colour-only.
class DdayBadge extends StatelessWidget {
  const DdayBadge(this.status, {super.key});

  final ExpiryStatus status;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final l = AppLocalizations.of(context);
    final (String label, Color bg, Color fg) = switch (status.level) {
      ExpiryLevel.overdue => (l.expiryOverdue(-status.daysLeft), c.dangerSoft, c.dangerInk),
      ExpiryLevel.today => (l.expiryToday, c.dangerSoft, c.dangerInk),
      ExpiryLevel.tomorrow => (l.expiryTomorrow, c.dangerSoft, c.dangerInk),
      ExpiryLevel.soon => (l.expiryDaysLeft(status.daysLeft), c.accentSoft, c.accentInk),
      ExpiryLevel.later => (l.expiryOk, c.secondarySoft, c.secondaryInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: AppType.label.copyWith(fontSize: 12, color: fg)),
    );
  }
}

/// "Back in 3 days" badge for things lent out.
class ReturnBadge extends StatelessWidget {
  const ReturnBadge(this.status, {super.key});

  final ExpiryStatus status;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    final l = AppLocalizations.of(context);
    final (String label, Color bg, Color fg) = switch (status.level) {
      ExpiryLevel.overdue => (l.returnOverdue(-status.daysLeft), c.dangerSoft, c.dangerInk),
      ExpiryLevel.today => (l.returnToday, c.dangerSoft, c.dangerInk),
      ExpiryLevel.tomorrow || ExpiryLevel.soon => (l.returnDaysLeft(status.daysLeft), c.accentSoft, c.accentInk),
      ExpiryLevel.later => (l.returnDaysLeft(status.daysLeft), c.muted, c.mutedFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.keyboard_return_rounded, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: AppType.label.copyWith(fontSize: 12, color: fg)),
        ],
      ),
    );
  }
}
