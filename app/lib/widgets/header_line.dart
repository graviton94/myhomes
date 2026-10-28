import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../data/accounts.dart';
import '../data/home_store.dart';
import '../data/household.dart';
import '../features/family/family_screen.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import 'doodle.dart';
import 'sheets.dart';

/// Settings, always at the top right.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('settings'),
    tooltip: AppLocalizations.of(context).settings,
    icon: const Icon(Icons.tune_rounded),
    onPressed: () => context.push('/settings'),
  );
}

/// "Megaphone" line at the top of the main tabs: the last change, how long
/// ago, and Settings at the right. Tapping the change opens where it happened.
class HeaderLine extends ConsumerWidget {
  const HeaderLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).value;
    final change = d == null ? null : lastChange(d);
    final home = ref.watch(householdProvider).value;
    final me = ref.watch(accountProvider).value?.uid;
    final sync = ref.watch(syncStateProvider).value;
    var text = change == null ? l.noChangesYet : '${changeText(l, d!, change)} · ${agoText(l, change.at, DateTime.now())}';
    // In a shared home, changes by family say who made them.
    final who = home?.member(change?.by);
    if (change?.by != null && change!.by != me) text = l.changeBy(who == null ? l.familySomeone : memberName(l, who), text);
    final place = change?.containerId;
    return Material(
      color: c.card,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        padding: const EdgeInsets.only(left: AppSpace.md),
        height: 48,
        child: Row(
          children: [
            const DoodleMegaphone(size: 24),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: InkWell(
                onTap: place == null || d?.container(place) == null ? null : () => context.push('/space/${d!.container(place)!.spaceId}'),
                child: Text(
                  text,
                  key: const ValueKey('last-change'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.caption.copyWith(color: change == null ? c.mutedFg : c.fg),
                ),
              ),
            ),
            if (sync != null)
              Tooltip(
                message: switch (sync) {
                  SyncState.saved => l.syncSaved,
                  SyncState.saving => l.syncSaving,
                  SyncState.offline => l.syncOffline,
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpace.xs),
                  child: Icon(
                    switch (sync) {
                      SyncState.saved => Icons.cloud_done_outlined,
                      SyncState.saving => Icons.cloud_upload_outlined,
                      SyncState.offline => Icons.cloud_off_outlined,
                    },
                    key: ValueKey('sync-${sync.name}'),
                    size: 20,
                    color: sync == SyncState.offline ? c.mutedFg : c.secondaryInk,
                  ),
                ),
              ),
            const SettingsButton(),
          ],
        ),
      ),
    );
  }
}

/// "가위 외 2개 넣음 · 거실 › TV장".
String changeText(AppLocalizations l, HomeData d, Change c) {
  final what = c.names.length > 1 ? l.changeWhatMore(c.names.first, c.names.length - 1) : c.names.first;
  final place = c.containerId == null || d.container(c.containerId!) == null ? '' : pathText(d.pathOf(c.containerId!));
  return switch (c.type) {
    LogType.add => l.changeAdd(what, place),
    LogType.move => l.changeMove(what, place),
    LogType.use => l.changeUse(what, place),
    LogType.usedUp => l.changeUsedUp(what),
    LogType.edit => l.changeEdit(what),
    LogType.remove => l.changeRemove(what),
  };
}

String agoText(AppLocalizations l, DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inMinutes < 1) return l.agoNow;
  if (d.inHours < 1) return l.agoMinutes(d.inMinutes);
  if (d.inDays < 1) return l.agoHours(d.inHours);
  return l.agoDays(d.inDays);
}
