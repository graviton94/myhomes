import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_update.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import 'doodle.dart';
import 'fit_text.dart';

/// The store's new version at the bottom of the tabs: 나중에 · 받기, then how
/// much is fetched, then 다시 시작. Nothing when there is nothing to do.
class UpdateToast extends ConsumerWidget {
  const UpdateToast({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appUpdateProvider);
    final update = ref.read(appUpdateProvider.notifier);
    if (!update.toastShown) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final text = AppType.body.copyWith(color: c.bg, fontSize: 15, fontWeight: FontWeight.w700);

    Widget button(String id, String label, VoidCallback onTap) => TextButton(
      key: ValueKey('update-$id'),
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: c.onPrimary,
        backgroundColor: c.primary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        minimumSize: const Size(0, 40),
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: AppType.label.copyWith(fontSize: 14)),
    );

    // "나중에" as a small ×, so the sentence keeps the room.
    final later = IconButton(
      key: const ValueKey('update-later'),
      tooltip: l.updateLater,
      onPressed: update.later,
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.close_rounded, color: c.bg.withValues(alpha: 0.75), size: 20),
    );

    final (Widget body, List<Widget> buttons) = switch (s.phase) {
      UpdatePhase.downloading => (
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            OneLine([l.updateDownloading(s.percent), l.updateDownloadingShort(s.percent)], style: text),
            const SizedBox(height: AppSpace.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                key: const ValueKey('update-progress'),
                value: s.progress > 0 ? s.progress : null,
                minHeight: 6,
                color: c.primary,
                backgroundColor: c.bg.withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
        const <Widget>[],
      ),
      UpdatePhase.downloaded => (OneLine([l.updateDownloaded, l.updateDownloadedShort], style: text), [button('restart', l.updateRestart, update.complete)]),
      UpdatePhase.failed => (OneLine([l.updateFailed, l.updateFailedShort], style: text), [later, button('get', l.updateRetry, update.start)]),
      _ => (OneLine([l.updateAvailable, l.updateNew], style: text), [later, button('get', l.updateGet, update.start)]),
    };

    return Padding(
      key: const ValueKey('update-toast'),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.sm),
      child: Material(
        color: c.fg,
        elevation: 6,
        shadowColor: const Color(0x55000000),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.sm, AppSpace.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              children: [
                const DoodleDust(size: 24),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: body),
                for (final b in buttons) ...[const SizedBox(width: AppSpace.xs), b],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
