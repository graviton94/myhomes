import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/home_store.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import 'app_icons.dart';

/// "⌂ My home › Kitchen › Drawer 1". Each level has its own colour (room =
/// green, storage = honey) and takes you back to that level when tapped.
class LocationBar extends ConsumerWidget {
  const LocationBar({super.key, this.spaceId, this.storageId, this.trailing});

  final String? spaceId;
  final String? storageId;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final storage = storageId == null ? null : d.container(storageId!);
    final space = d.space(spaceId ?? storage?.spaceId ?? '');
    Widget sep() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(Icons.chevron_right_rounded, size: 16, color: c.mutedFg),
    );
    return Row(
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              LevelChip(
                icon: Icons.home_rounded,
                label: l.myHome,
                bg: c.muted,
                fg: c.mutedFg,
                onTap: storage == null && spaceId != null ? null : () => context.go('/spaces'),
              ),
              if (space != null) ...[
                sep(),
                LevelChip(
                  icon: spaceIcon(space),
                  label: space.name,
                  bg: c.secondarySoft,
                  fg: c.secondaryInk,
                  onTap: storage == null ? null : () => context.push('/space/${space.id}'),
                ),
              ],
              if (storage != null) ...[
                sep(),
                LevelChip(icon: storageIcon(storage), label: storage.name, bg: c.accentSoft, fg: c.accentInk),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.icon, required this.label, required this.bg, required this.fg, this.onTap});

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
