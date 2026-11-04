import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:intl/intl.dart';

import '../../data/accounts.dart';
import '../../data/home_store.dart';
import '../../data/household.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/sheets.dart';
import '../family/family_screen.dart';

/// What happened in the home, newest first: read only. Filters are the
/// three actions (+ ⇄ −); who did it is a small word on the row.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  ActionKind? _only;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final d = ref.watch(homeProvider).requireValue;
    final household = ref.watch(householdProvider).value;
    final me = ref.watch(accountProvider).value?.uid;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final list = changes(d, only: _only);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String dayOf(DateTime at) {
      final day = DateTime(at.year, at.month, at.day);
      final ago = today.difference(day).inDays;
      if (ago == 0) return l.dayToday;
      if (ago == 1) return l.dayYesterday;
      return DateFormat.MMMEd(locale).format(at);
    }

    final rows = <Widget>[];
    String? lastDay;
    for (final (n, ch) in list.indexed) {
      final day = dayOf(ch.at);
      if (day != lastDay) {
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xs),
            child: Text(day, style: t.labelLarge?.copyWith(color: c.mutedFg)),
          ),
        );
        lastDay = day;
      }
      final kind = actionOf(ch.type);
      final what = ch.names.length > 1 ? l.changeWhatMore(ch.names.first, ch.names.length - 1) : ch.names.first;
      final place = ch.containerId == null || d.container(ch.containerId!) == null ? null : ch.containerId!;
      final who = ch.by == null || ch.by == me ? null : household?.member(ch.by);
      final parts = [
        if (place != null) pathText(d.pathOf(place)),
        DateFormat.jm(locale).format(ch.at),
        if (ch.type == LogType.usedUp) l.usedUp,
        if (ch.type == LogType.discard) l.discard,
        if (who != null) memberName(l, who),
      ];
      rows.add(
        ListTile(
          key: ValueKey('history-$n'),
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: switch (kind) {
              ActionKind.add => c.secondarySoft,
              ActionKind.move => c.accentSoft,
              ActionKind.use => c.primarySoft,
              null => c.muted,
            },
            child: Icon(
              switch (kind) {
                ActionKind.add => Icons.add_rounded,
                ActionKind.move => Icons.swap_horiz_rounded,
                ActionKind.use => Icons.remove_rounded,
                null => Icons.edit_outlined,
              },
              size: 18,
              color: c.fg,
            ),
          ),
          title: Text(what, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(parts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: place == null ? null : () => context.push('/storage/$place'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.historyTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.sm),
            // Four fixed segments: all, + in, ⇄ moved, − used.
            child: SegmentedButton<ActionKind?>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: null, label: Text(l.filterAll)),
                ButtonSegment(value: ActionKind.add, icon: const Icon(Icons.add_rounded), label: Text(l.filterAdd)),
                ButtonSegment(value: ActionKind.move, icon: const Icon(Icons.swap_horiz_rounded), label: Text(l.filterMove)),
                ButtonSegment(value: ActionKind.use, icon: const Icon(Icons.remove_rounded), label: Text(l.filterUse)),
              ],
              selected: {_only},
              onSelectionChanged: (s) => setState(() => _only = s.first),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Text(l.historyEmpty, style: t.bodyMedium?.copyWith(color: c.mutedFg)),
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: AppSpace.xl),
                    children: rows,
                  ),
          ),
        ],
      ),
    );
  }
}
