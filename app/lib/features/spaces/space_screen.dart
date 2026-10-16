import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/sheets.dart';
import 'space_actions.dart';

/// One room: its storage spots. (Photo with pins comes in a later build.)
class SpaceScreen extends ConsumerWidget {
  const SpaceScreen({super.key, required this.spaceId});

  final String spaceId;

  Future<void> _addStorage(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final r = await askStorage(context, title: l.addStorage);
    if (r == null || !context.mounted) return;
    final s = await ref
        .read(homeProvider.notifier)
        .apply<Storage>((d, ctx) => addContainer(d, ctx, spaceId: spaceId, name: r.name, rows: r.rows, cols: r.cols));
    if (s != null && context.mounted) context.push('/storage/${s.id}');
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, String action, Space space) async {
    final l = AppLocalizations.of(context);
    final home = ref.read(homeProvider.notifier);
    if (action == 'rename') {
      final name = await askText(context, title: l.rename, initial: space.name, label: l.spaceNameHint);
      if (name != null) await home.apply((d, _) => renameSpace(d, spaceId, name));
    } else if (action == 'delete') {
      final ok = await confirm(context, title: l.deleteSpaceTitle(space.name), body: l.deleteSpaceBody, action: l.delete);
      if (!ok || !context.mounted) return;
      context.pop();
      await home.apply((d, _) => deleteSpace(d, spaceId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final space = d.space(spaceId);
    if (space == null) return const Scaffold();
    final storages = d.containers.where((c) => c.spaceId == spaceId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(space.name),
        actions: [
          PopupMenuButton<String>(
            tooltip: l.more,
            onSelected: (a) => _menu(context, ref, a, space),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rename', child: Text(l.rename)),
              PopupMenuItem(value: 'delete', child: Text(l.delete)),
            ],
          ),
        ],
      ),
      floatingActionButton: storages.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _addStorage(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.addStorage),
            ),
      body: storages.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  pose: FairyPose.carry,
                  title: l.spaceEmptyTitle,
                  body: l.spaceEmptyBody,
                  action: FilledButton.icon(
                    onPressed: () => _addStorage(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.addStorage),
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, 96),
              itemCount: storages.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
              itemBuilder: (context, i) => _StorageCard(storage: storages[i]),
            ),
    );
  }
}

class _StorageCard extends ConsumerWidget {
  const _StorageCard({required this.storage});

  final Storage storage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final items = d.itemsIn(storage.id)..sort((a, b) => a.slot.compareTo(b.slot));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/storage/${storage.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(pathText(d.pathOf(storage.id).skip(1).toList()), style: Theme.of(context).textTheme.titleSmall)),
                  Text(storage.code, style: AppType.code.copyWith(color: c.mutedFg)),
                ],
              ),
              const SizedBox(height: 2),
              Text(l.itemsCount(items.length), style: Theme.of(context).textTheme.bodySmall),
              if (items.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final i in items.take(7)) ItemThumb(category: i.category, photoPath: i.photoPath, size: 32),
                    if (items.length > 7)
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(10)),
                        child: Text('+${items.length - 7}', style: AppType.code.copyWith(color: c.mutedFg)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
