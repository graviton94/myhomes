import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/location_bar.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/sheets.dart';
import '../spaces/space_actions.dart';
import 'inventory_grid.dart';
import 'selection.dart';

/// One storage spot on its own (from search, the fairy, or "open" on the
/// room board).
class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key, required this.storageId, this.startInSelectMode = false});

  final String storageId;
  final bool startInSelectMode;

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> with PickSelection {
  @override
  void initState() {
    super.initState();
    selecting = widget.startInSelectMode;
  }

  Future<void> _menu(String action, Storage s) async {
    final l = AppLocalizations.of(context);
    final home = ref.read(homeProvider.notifier);
    if (action == 'edit') {
      await editStorageFlow(context, ref, s);
    } else if (action == 'delete') {
      final count = home.data.itemsIn(s.id).length;
      final ok = await confirm(context, title: l.deleteStorageTitle(s.name), body: l.deleteStorageBody(count), action: l.delete);
      if (!ok || !mounted) return;
      context.pop();
      await home.apply((d, _) => deleteContainer(d, s.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final storage = d.container(widget.storageId);
    if (storage == null) return const Scaffold();
    final items = d.itemsIn(storage.id);
    prunePicks(d);

    return PopScope(
      canPop: !selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) endSelect();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(selecting ? (picks.isEmpty ? l.pickItems : l.pickedSummary(picks.length, pickedTotal)) : storage.name),
          leading: selecting ? IconButton(tooltip: l.cancel, onPressed: endSelect, icon: const Icon(Icons.close_rounded)) : null,
          actions: [
            if (!selecting)
              PopupMenuButton<String>(
                tooltip: l.more,
                onSelected: (a) => _menu(a, storage),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(l.editStorage)),
                  PopupMenuItem(value: 'delete', child: Text(l.delete)),
                ],
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
          children: [
            LocationBar(
              storageId: storage.id,
              trailing: Text(storage.code, style: AppType.code.copyWith(color: c.mutedFg)),
            ),
            if (storage.photoPath != null) ...[
              const SizedBox(height: AppSpace.md),
              PhotoBox(photoPath: storage.photoPath, height: 132, onTap: () => _menu('edit', storage)),
            ],
            const SizedBox(height: AppSpace.md),
            InventoryGrid(storageId: storage.id, picks: picks, selecting: selecting, onTogglePick: togglePick),
            const SizedBox(height: AppSpace.md),
            Text(selecting ? l.selectHint : l.storageHint, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.mutedFg)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
            child: selecting
                ? selectionButtons(context, exclude: storage.id)
                : Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push('/item/new?storage=${storage.id}'),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l.actionAdd),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: items.isEmpty ? null : startSelect,
                          icon: const Icon(Icons.checklist_rounded),
                          label: Text(l.pickSeveral),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
