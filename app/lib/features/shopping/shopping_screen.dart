import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';
import '../../widgets/header_line.dart';
import '../../widgets/inventory_slot.dart';
import '../../widgets/open_item.dart';
import '../../widgets/sheets.dart';

/// Things below their minimum amount. "Refilled" brings one back up to it.
class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final d = ref.watch(homeProvider).requireValue;
    final low = lowStock(d);

    return Scaffold(
      appBar: AppBar(title: Text(l.shoppingTitle), actions: const [SettingsButton()]),
      body: low.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(pose: FairyPose.cheer, title: l.shoppingEmptyTitle, body: l.shoppingEmptyBody),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              children: [
                for (final item in low)
                  ListTile(
                    leading: ItemThumb(category: item.category, photoPath: item.photoPath, iconKey: item.icon),
                    title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${l.shoppingNeed(item.qty, item.minQty!)}\n${pathText(d.pathOf(item.containerId))}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: FilledButton.tonal(
                      key: ValueKey('refill-${item.id}'),
                      onPressed: () async {
                        await ref.read(homeProvider.notifier).apply((d, ctx) => adjustQty(d, ctx, item.id, item.minQty! - item.qty));
                        if (context.mounted) showUndo(context, ref, l.shoppingRefilled(item.name, item.minQty!));
                      },
                      child: Text(l.shoppingRefill),
                    ),
                    onTap: () => openItem(context, d, item),
                  ),
              ],
            ),
    );
  }
}
