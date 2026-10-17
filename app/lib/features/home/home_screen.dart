import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';
import '../../widgets/open_item.dart';
import '../fairy/fairy_button.dart';
import '../spaces/space_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Add / Move / Take out from home: choose the storage first.
  Future<void> _quick(BuildContext context, WidgetRef ref, _Quick kind) async {
    final l = AppLocalizations.of(context);
    final d = ref.read(homeProvider).requireValue;
    if (d.containers.isEmpty) {
      showMessage(context, l.makeStorageFirst);
      return;
    }
    final title = switch (kind) {
      _Quick.add => l.addWhere,
      _Quick.move => l.moveFromWhere,
      _Quick.use => l.takeOutFromWhere,
    };
    final id = await pickStorage(context, title: title);
    if (id == null || !context.mounted) return;
    switch (kind) {
      case _Quick.add:
        context.push('/item/new?storage=$id');
      case _Quick.move:
        context.push('/storage/$id?select=1');
      case _Quick.use:
        context.push('/storage/$id');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final today = DateTime.now();
    final urgent = byExpiry(d, today).where((e) => e.$2.isUrgent).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l.myHome),
        actions: [
          IconButton(tooltip: l.settings, icon: const Icon(Icons.tune_rounded), onPressed: () => context.push('/settings')),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      floatingActionButton: FairyButton(badge: urgent.length),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, 112),
        children: [
          TextField(
            readOnly: true,
            onTap: () => context.go('/search'),
            decoration: InputDecoration(hintText: l.searchHint, prefixIcon: const Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              _QuickAction(icon: Icons.add_rounded, label: l.actionAdd, color: c.primaryInk, onTap: () => _quick(context, ref, _Quick.add)),
              const SizedBox(width: AppSpace.sm),
              _QuickAction(
                icon: Icons.swap_horiz_rounded,
                label: l.actionMove,
                color: c.accentInk,
                onTap: () => _quick(context, ref, _Quick.move),
              ),
              const SizedBox(width: AppSpace.sm),
              _QuickAction(
                icon: Icons.remove_rounded,
                label: l.actionTakeOut,
                color: c.secondaryInk,
                onTap: () => _quick(context, ref, _Quick.use),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          if (urgent.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.sm),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(l.eatFirst(urgent.length), style: Theme.of(context).textTheme.titleSmall)),
                        TextButton(onPressed: () => context.go('/expiry'), child: Text(l.seeAll)),
                      ],
                    ),
                    for (final (item, status) in urgent.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ItemThumb(category: item.category, photoPath: item.photoPath, icon: iconFor(item.icon)),
                        title: Text(item.qty > 1 ? '${item.name} ×${item.qty}' : item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(pathText(d.pathOf(item.containerId)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: AppSpace.sm),
                          child: DdayBadge(status),
                        ),
                        onTap: () => openItem(context, d, item),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          if (d.spaces.isEmpty)
            Card(
              child: EmptyState(
                pose: FairyPose.carry,
                title: l.homeEmptyTitle,
                body: l.homeEmptyBody,
                action: FilledButton.icon(
                  onPressed: () => addSpaceFlow(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.addSpace),
                ),
              ),
            )
          else ...[
            Text(l.navSpaces, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpace.sm),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpace.sm,
              crossAxisSpacing: AppSpace.sm,
              childAspectRatio: 2.6,
              children: [
                for (final s in d.spaces) SpaceTile(space: s),
                _AddTile(label: l.addSpace, onTap: () => addSpaceFlow(context, ref)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum _Quick { add, move, use }

class SpaceTile extends ConsumerWidget {
  const SpaceTile({super.key, required this.space});

  final Space space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/space/${space.id}'),
        child: Row(
          children: [
            if (space.photoPath != null && File(space.photoPath!).existsSync())
              Image.file(File(space.photoPath!), width: 56, height: double.infinity, fit: BoxFit.cover, cacheWidth: 200)
            else
              Container(
                width: 48,
                height: double.infinity,
                color: HfColors.of(context).secondarySoft,
                child: Icon(spaceIcon(space), color: HfColors.of(context).secondaryInk),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(space.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      l.itemsCount(d.itemCountInSpace(space.id)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.code.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Material(
      color: c.muted,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: c.mutedFg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.mutedFg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 4),
                Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
