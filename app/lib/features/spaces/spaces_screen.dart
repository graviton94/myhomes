import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/home_store.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import 'space_actions.dart';

/// Spaces tab: every room with its storage count.
class SpacesScreen extends ConsumerWidget {
  const SpacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    return Scaffold(
      appBar: AppBar(title: Text(l.navSpaces)),
      floatingActionButton: d.spaces.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => addSpaceFlow(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.addSpace),
            ),
      body: d.spaces.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  pose: FairyPose.sleep,
                  title: l.spacesEmptyTitle,
                  body: l.spacesEmptyBody,
                  action: FilledButton.icon(
                    onPressed: () => addSpaceFlow(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.addSpace),
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, 96),
              itemCount: d.spaces.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
              itemBuilder: (context, i) {
                final s = d.spaces[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    title: Text(s.name, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text(l.spaceSummary(d.containers.where((c) => c.spaceId == s.id).length, d.itemCountInSpace(s.id))),
                    trailing: Text(s.code, style: AppType.code.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    onTap: () => context.push('/space/${s.id}'),
                  ),
                );
              },
            ),
    );
  }
}
